import "dotenv/config";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Agent } from "@cursor/sdk";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** cursor-agent-fixer odatda workspace ichida: .../workspace/cursor-agent-fixer/src → workspace ildizi */
function defaultWorkspaceRoot(): string {
  return path.resolve(__dirname, "..", "..");
}

function parseArgs(argv: string[]): {
  noPlan: boolean;
  cwdOverride: string | undefined;
  task: string;
} {
  let noPlan = false;
  let cwdOverride: string | undefined;
  const rest: string[] = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--no-plan") {
      noPlan = true;
      continue;
    }
    if (a === "--cwd" && argv[i + 1]) {
      cwdOverride = path.resolve(argv[++i]);
      continue;
    }
    rest.push(a);
  }
  return {
    noPlan,
    cwdOverride,
    task: rest.join(" ").trim(),
  };
}

function wantPlan(includePlanEnv: string | undefined, noPlanFlag: boolean): boolean {
  if (noPlanFlag) return false;
  const v = includePlanEnv?.trim().toLowerCase();
  if (v === "0" || v === "false" || v === "no") return false;
  return true;
}

function tryLoadPlan(planPath: string): { text: string | null; pathTried: string } {
  if (!planPath) return { text: null, pathTried: planPath };
  if (!fs.existsSync(planPath)) {
    return { text: null, pathTried: planPath };
  }
  return { text: fs.readFileSync(planPath, "utf8"), pathTried: planPath };
}

function resolvePlanPath(): string {
  const fromEnv = process.env.PLAN_PATH?.trim();
  if (fromEnv) return fromEnv;
  return path.join(process.env.USERPROFILE ?? "C:\\Users\\New", "Desktop", "90 kunlik.txt");
}

function resolveRepoCwd(cwdOverride: string | undefined): string {
  if (cwdOverride) return cwdOverride;
  const fromEnv = process.env.REPO_CWD?.trim();
  if (fromEnv) return path.resolve(fromEnv);
  return defaultWorkspaceRoot();
}

async function main() {
  const apiKey = process.env.CURSOR_API_KEY?.trim();
  if (!apiKey) {
    console.error("CURSOR_API_KEY o‘rnatilmagan.");
    console.error("1) Cursor > Integratsiyalar > API kalit yarating");
    console.error("2) cursor-agent-fixer/.env faylida CURSOR_API_KEY=... qo‘ying (.env.example dan nusxa)");
    process.exit(1);
  }

  const { noPlan, cwdOverride, task: taskFromArgs } = parseArgs(
    process.argv.slice(2)
  );

  const usePlan = wantPlan(process.env.INCLUDE_PLAN, noPlan);
  const planPath = resolvePlanPath();
  const planLoaded = usePlan ? tryLoadPlan(planPath) : { text: null as string | null, pathTried: planPath };

  if (usePlan && !planLoaded.text && planPath) {
    console.error(`[eslatma] Reja fayli topilmadi (${planLoaded.pathTried}) — rejasiz davom etiladi.`);
    console.error("       Faqat reja kerak bo‘lsa PLAN_PATH ni to‘g‘rilang yoki INCLUDE_PLAN=0 qiling.");
  }

  const repoCwd = resolveRepoCwd(cwdOverride);

  if (!fs.existsSync(repoCwd)) {
    console.error(`REPO_CWD / --cwd noto‘g‘ri (papka yo‘q): ${repoCwd}`);
    process.exit(1);
  }

  const task =
    taskFromArgs ||
    process.env.AGENT_TASK?.trim() ||
    "Butun loyiha tuzilmasini o‘rgan (papka va muhim fayllar), texnologik stack va kirish nuqtalarini qisqa xulosa qil, keyin barqarorlik va keyingi mantiqiy qadamlarni taklif qil.";

  const modelId = process.env.CURSOR_MODEL?.trim() || "composer-2";

  const planBlock =
    planLoaded.text != null
      ? `Qo‘shimcha kontekst — foydalanuvchi rejasi (ixtiyoriy fayl):

${planLoaded.text}

---

`
      : "";

  const prompt = `${planBlock}Sen **Agent Fixer** sifatida ishlayapsan.

**Ish muhiti:** barcha kod va konfiguratsiya — quyidagi katalogni butunlay qamrab ol:
\`${repoCwd}\`

Faqat bitta tashqi matn fayliga qaramay, **butun shu loyiha/repository** bo‘yicha ishlang: tuzilma, modullar, build va test buyruqlari, muhim konfiglar. Zarur bo‘lsa fayllarni o‘qing, kataloglarni ko‘ring, bog‘liqliklarni aniqlang.

**Foydalanuvchi vazifasi:** ${task}

Javobda aniq fayl yo‘llari va amaliy qadamlarni ko‘rsat.`;

  console.error(`cwd (butun loyiha doirasi): ${repoCwd}`);
  console.error(`reja: ${planLoaded.text != null ? planLoaded.pathTried : "yo‘q (--no-plan yoki fayl yo‘q / INCLUDE_PLAN=0)"}`);
  console.error(`model: ${modelId}`);

  const agent = await Agent.create({
    apiKey,
    model: { id: modelId },
    local: { cwd: repoCwd },
  });

  try {
    const run = await agent.send(prompt);
    for await (const event of run.stream()) {
      console.log(JSON.stringify(event, null, 2));
    }
    const result = await run.wait();
    console.error(`\nStatus: ${result.status}`);
    if (result.result) console.log(result.result);
  } finally {
    agent.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
