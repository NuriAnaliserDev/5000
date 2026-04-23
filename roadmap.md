# GeoField Pro - 90 Kunlik Yakunlash Roadmapi

## Maqsad
- 90 kun ichida barqaror, kengaytiriladigan, field va boshqaruv ehtiyojlarini qoplaydigan geologik tizimni ishlab chiqarish holatiga olib chiqish.
- Tizimni `offline-first`, `local-first`, kuzatuv/audit imkoniyatlari bilan mustahkamlash.
- Rahbariyatga topshirish uchun `v1.0` release va operatsion qo'llanmani tayyorlash.

## Strategik Yo'nalish
- **Field Layer**: mobil/desktop oddiy rejim (`Capture`, `Map`, `Sync`).
- **Operations Layer**: web dashboard (tasdiqlash, hisobot, nazorat).
- **Platform Layer**: autentifikatsiya, sinxronlash, saqlash, audit, AI integratsiya.

## Ishlash Qoidalari
- Har sprint oxirida demo + regressiya tekshiruvi.
- Har merge oldidan: `flutter analyze` + smoke test.
- Har P0 issue uchun 24 soat ichida yechim yoki workaround.
- Barcha kritik o'zgarishlar uchun rollback rejasi yoziladi.

---

## 1-2 Hafta: Stabilizatsiya va Scope Freeze

### Vazifalar
- MVP scope muzlatish:
  - Field: Capture, Map, Sync, Archive, Basic Analysis.
  - Dashboard: login, report ko'rish, tasdiqlash, eksport.
- Arxitektura audit:
  - UI / Service / Repository qatlamlari hujjatlashtiriladi.
- Kritik bugfix:
  - `Analysis` tab mismatch kabi runtime xatolar tozalanadi.
- Kod sifati:
  - `flutter analyze` natijasidagi asosiy warninglar triage qilinadi (`P0/P1/P2`).
- Release intizomi:
  - branch strategiya, commit andozasi, issue tracking tartibi o'rnatiladi.

### Definition of Done
- MVP scope hujjati tasdiqlangan.
- P0 runtime xatolar yopilgan.
- Analyze natijasida bloklovchi xato qolmagan.
- Demo build rahbariyatga ko'rsatishga yaroqli.

### KPI
- Crash-free session >= 90%
- P0 issue close time <= 24 soat

---

## 3-4 Hafta: UX Soddalashtirish (Field-first)

### Vazifalar
- `Field Mode` joriy qilish:
  - Asosiy ekran: faqat `Capture`, `Map`, `Sync`.
- `Advanced Mode`:
  - Murakkab geologik vositalar alohida rejimga ko'chiriladi.
- Onboarding (3 daqiqa):
  - Birinchi ishga tushirishda GPS, kamera, mikrofon tekshiruvi.
- Terminologiya standarti:
  - Yagona lug'at (to'liq O'zbek yoki O'zbek + EN).
- Navigatsiya soddalash:
  - Takror funksiyalar bitta kirish nuqtasiga birlashtiriladi.

### Definition of Done
- Yangi foydalanuvchi 5 daqiqa ichida birinchi stansiyani saqlay oladi.
- Field mode default bo'lib ishlaydi.
- Terminologiya bo'yicha UI audit yakunlangan.

### KPI
- Onboarding completion >= 85%
- Task completion time (first capture) <= 5 daqiqa

---

## 5-6 Hafta: Kuzatuv, Log va Recovery

### Vazifalar
- `Health Check` sahifasi:
  - GPS, kamera, xotira, internet, sync holatlari.
- `Action Log` (local):
  - Capture, edit, sync, delete, export kabi amallar yozuvi.
- `Crash Log` (local):
  - Xatolik stack trace + oxirgi user actionlar.
- Recovery oqimi:
  - App qayta ishga tushganda tiklash ssenariysi.
- Self-diagnostic:
  - Bir klikda asosiy modullar holatini tekshiruvchi utilita.

### Definition of Done
- Har qanday xato holati uchun log olish mumkin.
- Crashdan keyin app qayta ishga tushib, asosiy oqimni davom ettira oladi.
- Health Check orqali asosiy muammolar ko'rinadi.

### KPI
- Mean Time To Diagnose (MTTD) <= 15 daqiqa
- Recovery success rate >= 95%

---

## 7-8 Hafta: Xavfsizlik va Local-first Mustahkamlash

### Vazifalar
- `Local-only` rejim:
  - Tashqi network chaqiriqlarni policy asosida boshqarish.
- Local ma'lumotlarni himoyalash:
  - DB/fayllar shifrlash (at-rest encryption).
- Rolga asoslangan ruxsat:
  - Admin, geolog, auditor huquqlari.
- Audit trail:
  - Kim, qachon, nimani o'zgartirdi.
- Export nazorati:
  - Faqat ruxsat etilgan eksport formatlari va ro'yxatga olish.

### Definition of Done
- Xavfsizlik checklistdagi P0/P1 bandlar bajarilgan.
- Local ma'lumotlar himoyalangan va audit izlari mavjud.
- Ruxsatsiz amallar bloklanadi.

### KPI
- Security critical findings = 0
- Unauthorized action block rate = 100%

---

## 9-10 Hafta: Platforma Abstraksiyasi (Vendor Lock kamaytirish)

### Vazifalar
- Provider interfeyslarini ajratish:
  - `AuthProvider`, `SyncProvider`, `StorageProvider`.
- Firebase bog'liqlikni abstraksiya qilish:
  - To'g'ridan-to'g'ri chaqiriqlarni adapterga o'tkazish.
- Sync engine yaxshilash:
  - Queue, retry/backoff, idempotency.
- Conflict resolution:
  - Oxirgi yozuv strategiyasi yoki qo'lda yechish oqimi.
- Migratsiya texnik hujjati:
  - Keyin self-hosted backendga o'tish ssenariysi.

### Definition of Done
- Client kodi provider interfeyslari orqali ishlaydi.
- Firebase almashtirilsa ham core UI minimal o'zgarish bilan ishlaydi.
- Sync konflikti qayta tiklanadigan holatda.

### KPI
- Sync success rate >= 98%
- Data conflict unresolved rate <= 1%

---

## 11 Hafta: Windows .exe Release Pipeline

### Vazifalar
- Build muhit tayyorlash:
  - Visual Studio + C++ workload, doctor yashil holat.
- Release build:
  - `flutter build windows --release`.
- Installer:
  - Inno Setup yoki MSIX paketlash.
- Offline install test:
  - Internet bo'lmagan mashinada o'rnatish va ishga tushirish.
- Versionlash:
  - Build raqami, release note, rollback paketi.

### Definition of Done
- `.exe` va installer ishlaydi.
- Toza Windows muhitida muvaffaqiyatli o'rnatiladi.
- Release candidate foydalanuvchi sinoviga tayyor.

### KPI
- Installer success rate >= 95%
- Critical install issue = 0

---

## 12 Hafta: UAT va Field Pilot

### Vazifalar
- 10-20 foydalanuvchi bilan pilot.
- Asosiy ssenariy testlari:
  - Capture -> Map -> Save -> Archive -> Export.
- Incident triage:
  - Muammolarni P0/P1/P2 bo'yicha saralash.
- Performance o'lchov:
  - App start, map load, capture latency, sync delay.
- UAT feedback asosida final backlog.

### Definition of Done
- UAT hisobot tayyor.
- P0 muammolar yopilgan.
- P1lar uchun aniq muddatli reja mavjud.

### KPI
- User satisfaction >= 8/10
- Field task success >= 90%

---

## 13 Hafta: Final Hardening va Topshirish

### Vazifalar
- P0/P1 yakuniy tozalash.
- Ops runbook:
  - "muammo bo'lsa nima qilamiz" bo'limlari.
- Monitoring va log eksport yo'riqnomasi.
- Admin va user qo'llanma (PDF/markdown).
- Rahbariyat uchun yakuniy demo va KPI taqdimoti.

### Definition of Done
- `v1.0` release imzolangan.
- Tizim bo'yicha texnik va operatsion hujjatlar tayyor.
- Qo'llab-quvvatlash jamoasi incident boshqaruvga tayyor.

### KPI
- Crash-free sessions >= 98%
- P0 open issues = 0

---

## Ollama bo'yicha Qaror (Exe ichida)

### Nima mumkin
- Ollama ni local servis sifatida ishga tushirib, appdan local API orqali chaqirish mumkin.
- AI funksiyalar (matn tavsiyasi, report draft, klassifikatsiya) offline ishlashi mumkin.

### Nima mumkin emas
- Ollama auth/sync/storage/realtime backend o'rnini to'liq bosa olmaydi.

### Tavsiya
- **Qisqa muddat**: Firebase + local AI (Ollama) gibrid.
- **O'rta muddat**: backend provider abstraksiya.
- **Uzoq muddat**: self-hosted backendga bosqichma-bosqich o'tish.

---

## Risk Matritsa

### Yuqori risk
- Scope kengayib ketishi (deadline surilishi).
- Desktop build muhitidagi bloklovchilar.
- Sync conflictlar sabab ma'lumot nomutanosibligi.

### O'rta risk
- UX murakkabligi sabab foydalanuvchi adashuvi.
- Dependency yangilanishlarida regressiya.

### Past risk
- Vizual noaniqliklar, non-critical lint ogohlantirishlari.

---

## Incidentga Tayyorlik Rejasi
- Incident darajalari: P0 (to'liq to'xtash), P1 (asosiy funksiyaga ta'sir), P2 (qisman noqulaylik).
- Har incident uchun:
  - aniqlash vaqti,
  - ta'sir doirasi,
  - vaqtinchalik yechim,
  - root-cause tahlil,
  - qayta takrorlanmaslik chorasi.
- Haftalik "stability review" yig'ilishi o'tkaziladi.

---

## Yakuniy Natija (90-kun)
- Field uchun soddalashtirilgan, barqaror, lokal ishlovchi geologik app.
- Dashboard uchun boshqaruv, audit, tasdiqlash va hisobot oqimi.
- Release, monitoring, recovery va support jarayonlari bilan to'liq tizim.

---

## EXE Dashboard uchun Alohida 30 Kunlik Reja

### Maqsad
- Webga qaram bo'lmagan, Windows desktop uchun professional operator panel yaratish.
- Map ko'rish + map tahrirlash + data console + audit/recovery funksiyalarini bitta EXE ichida ishlatish.

## 1-Hafta: Desktop Shell va Operator UX

### Vazifalar
- Desktop-first layout:
  - Chap panel: `Projects`, `Layers`, `Filters`.
  - Markaz: katta `Map Canvas`.
  - O'ng panel: `Attributes` va `Edit tools`.
  - Past panel: `Logs` va `Tasks`.
- Katta monitorlar uchun responsive grid.
- Hotkeylar:
  - `Ctrl+S` saqlash, `Ctrl+Z` undo, `Ctrl+Y` redo, `F` fokus.
- Session restore:
  - oxirgi ochilgan loyiha va layer holatini tiklash.

### Definition of Done
- EXE dashboard desktopda ishlaydi va map workspace barqaror ochiladi.
- Asosiy operator oqimi sichqoncha + klaviatura orqali bajariladi.

## 2-Hafta: GIS Tahrirlash Core

### Vazifalar
- Geometriya tahrirlash:
  - Select, move, vertex add/delete/edit.
- Chiziq/polygon amallari:
  - split, merge, simplify.
- Snap va topologiya:
  - snap tolerance, self-intersection tekshiruvi.
- Undo/redo stack:
  - har edit operation uchun history.

### Definition of Done
- Foydalanuvchi line/polygonni professional darajada tahrir qila oladi.
- Noto'g'ri geometriya saqlanishidan oldin ogohlantirish ishlaydi.

## 3-Hafta: Data Console (Databasega yaqin ish rejimi)

### Vazifalar
- Kengaytirilgan qidiruv va filter:
  - vaqt, loyiha, muallif, tosh turi, status bo'yicha.
- Bulk operations:
  - bir nechta yozuvni birdan tahrirlash.
- Validation engine:
  - majburiy maydonlar, diapazon, format tekshiruvlari.
- Data import/export:
  - CSV/GeoJSON import preview + conflict ko'rsatish.
- Rollback:
  - noto'g'ri bulk update ni qaytarish.

### Definition of Done
- EXE dashboard ichida "data console" orqali tezkor analitik tahrir qilish mumkin.
- Har bulk amalda preview va tasdiqlash bosqichi mavjud.

## 4-Hafta: Governance, Barqarorlik va Release

### Vazifalar
- Role-based access:
  - viewer, editor, verifier, admin rollari.
- Audit trail:
  - kim, qachon, nimani o'zgartirdi.
- Health + diagnostics:
  - local self-check panel, xatolik hisobot paketi.
- Build/release:
  - `windows --release`, installer, versiya nazorati.
- UAT mini-pilot:
  - 3-5 real user bilan test.

### Definition of Done
- EXE dashboard operatsion ishga tayyor holatga keladi.
- Audit/log/recovery mexanizmi real xatoliklarda foydali ma'lumot beradi.

### KPI (30 kun)
- Crash-free session >= 97%
- Map edit success >= 90%
- Bulk update xatosiz bajarilish >= 95%

---

## Muhim Qarorlar (Web Dashboard vs EXE Dashboard)

### Webdan EXEga o'tish xatomi?
- Yo'q, bu xato emas.
- Agar sizning asosiy ish oqimingiz dala, ofis ichki tarmoq va local nazorat bo'lsa, EXE to'g'ri tanlov.
- Webning ustunligi: tez deploy va markaziy boshqaruv.
- EXEning ustunligi: offline, local control, qurilma darajasida barqarorlik.

### APK va Dashboardni birlashtira olamizmi?
- Ha, to'liq birlashtirish mumkin.
- To'g'ri model:
  - Bitta `domain model` (Station, Layer, Audit, Sync holati).
  - Bitta `data contract` (API yoki local sync protokol).
  - Turli UI:
    - APK: field tezkor oqim.
    - EXE dashboard: chuqur tahlil va boshqaruv.

### Qanchalik to'g'ri yo'ldamiz?
- To'g'ri yo'ldasiz.
- Asosiy qadam: "ko'p feature" emas, "barqaror core + data intizomi + audit"ni birinchi o'ringa qo'yish.

---

## AI-Driven Mine Operations System (Yangi Bo'lim)

### Maqsad
- Excel, field va dashboard ma'lumotlarini birlashtirib, kon faoliyatini AI yordamida kunlik tahlil qilish.
- Zaif nuqtalar, xato jarayonlar, KPI pasayishi va xavfli trendlarni erta aniqlash.
- Rahbariyatga avtomatik, tushunarli, amaliy tavsiyali hisobot berish.

### Arxitektura
- **Data Ingestion**:
  - Excel import (watch folder yoki schedule).
  - Mavjud dashboard/field ma'lumotlari bilan birlashtirish.
- **Normalization Layer**:
  - Turli formatlarni bitta standart sxemaga o'tkazish.
  - Bo'sh maydon, noto'g'ri birlik, duplikat tekshiruvi.
- **AI Analysis Layer (Ollama/Local LLM)**:
  - Daily summary.
  - Anomaly detection.
  - Risk scoring.
  - Root-cause taxmini va tavsiyalar.
- **Decision Layer (Human-in-the-loop)**:
  - AI tavsiyasi -> inson tasdiqlashi -> yakuniy action.
- **Reporting Layer**:
  - Executive summary.
  - Shift/uchastka bo'yicha zaif nuqta kartasi.
  - Outlookga yuborishdan oldin preview/tasdiq.

### 4 Haftalik Boshlang'ich Reja
- **1-hafta**: Excel ingest + data schema + quality checks.
- **2-hafta**: AI summary + kundalik tahlil promptlari.
- **3-hafta**: Risk score + anomaly panel + trend kartalari.
- **4-hafta**: Approval workflow + auto-report + audit trail.

### Definition of Done
- AI kundalik hisobotda kamida 3 turdagi muammoni aniqlay oladi.
- Tavsiyalar inson tasdiqlovidan o'tmasdan production actionga ketmaydi.
- Hisobotlar rahbariyatga yuborish uchun preview/tasdiq bosqichidan o'tadi.

### KPI
- Anomaly detection precision >= 80%
- Noto'g'ri AI xulosa (false alarm) <= 15%
- Daily report generation time <= 5 daqiqa

---

## AI Konstruktor (AI Sentinel + AI Copilot)

### Maqsad
- Dastur ichki holatini real vaqtga yaqin monitoring qilish.
- Muammolarni erta aniqlash, tahlil qilish va xavfsiz auto-remediation tavsiya/harakatlarini ishga tushirish.

### Tamoyil
- **AI hammasini avtomatik hal qilmaydi**.
- To'g'ri model: `AI Sentinel (aniqlash) + AI Copilot (yechim taklif) + Human Gate (tasdiq)`.

### Modul Tuzilishi
- **Telemetry Collector**:
  - App log, sync log, crash log, performance metriclar.
- **Security Signal Collector**:
  - Login failure, shubhali trafik, token xatolari, ruxsatsiz urinishlar.
- **Detection Engine**:
  - Rule-based qoidalar + anomaly modeli.
- **Reasoning Engine (LLM)**:
  - "Nima bo'ldi?", "Nima uchun?", "Nima qilish kerak?" xulosalari.
- **Action Orchestrator**:
  - Past risk action: auto.
  - Yuqori risk action: faqat tasdiq bilan.
- **Audit Trail**:
  - Har AI qaror va harakat loglanadi.

### Auto-Action Siyosati
- **Auto ruxsat etiladi**:
  - Retry sync.
  - Vaqtinchalik fallback mode.
  - Queue cleanup.
  - Non-critical service restart.
- **Manual tasdiq shart**:
  - Ma'lumot o'chirish.
  - Bulk update.
  - Access policy o'zgartirish.
  - Security lockout.

### 6 Haftalik Tatbiq Reja
- **1-2 hafta**: telemetry va event standardlashtirish.
- **3-4 hafta**: detection qoidalari + AI incident summary.
- **5-6 hafta**: controlled auto-remediation + P0 alerting.

### Definition of Done
- Incident paydo bo'lsa 1 daqiqada alert hosil bo'ladi.
- AI root-cause drafti va tavsiya runbooki chiqadi.
- Yuqori risk actionlar tasdiqsiz bajirilmaydi.

### KPI
- Mean Time To Detect (MTTD) <= 60 soniya
- Mean Time To Respond (MTTR) <= 15 daqiqa
- P0 incidents with missing logs = 0

---

## Xavfni Keskin Kamaytirish uchun Qo'shimcha Qatlamlar

### 1) "Single-Person Safe Delivery" Tartibi
- Har o'zgarishda:
  - backup,
  - checklist,
  - rollback rejasi.
- Katta funksiyalarni kichik releaselarga bo'lish.
- "Agar yiqilsa nima qilamiz?" savoliga oldindan javob yozish.

### 2) Kill Switch va Safe Mode
- Muammo kuchaysa:
  - AI modulni vaqtinchalik o'chirish.
  - Faqat minimal core funksiyalarni yoqib ishlash.
- Bitta tugma bilan "emergency degrade mode".

### 3) Chaos Drill (Oyiga 1 marta)
- Sun'iy xatolik berib:
  - tiklanish tezligi,
  - log sifati,
  - runbook ishlashini tekshirish.

### 4) Data Integrity Qoidasini Qattiqlash
- Har yozuvga checksum/version.
- Muhim yozuvlar uchun two-step save.
- Noto'g'ri importni oldindan preview bloklash.

### 5) AI Quality Gate
- AI javoblari uchun:
  - confidence threshold.
  - "Ishonchim past" holatini majburiy chiqarish.
  - taxminiy xulosa va faktni alohida ko'rsatish.

### Strategik Eslatma
- Siz kodni kam bilsangiz ham strategik fikrlash bilan juda uzoqqa borasiz.
- Sizning eng katta kuchingiz: to'g'ri savol berish, ustuvorlikni ajratish va intizomli bajarish.
- Bu loyiha "bitta odam + AI" modeli bilan ham chiqadi, faqat release intizomi buzilmasin.
## Future: Developer Mode + AI Constructor (Ollama)



### 1) Developer Mode (restricted access)
- Faqat ruxsat berilgan developerlar uchun ochiladi (Firebase UID allowlist/custom claims).
- 2FA/re-auth talab qilinadi.
- Barcha amallar audit log qilinadi (kim, qachon, nima o‘zgartirdi).

### 2) AI Constructor (phase-by-phase)
- Phase 1 (MVP): AI konstruktor faqat JSON/DSL config generatsiya qiladi (to‘g‘ridan-to‘g‘ri source code edit emas).
- Phase 2: Preview + validation + rollback mexanizmi.
- Phase 3: Git patch proposal -> PR oqimi (tasdiqlangandan keyin merge).

### 3) Ollama integration
- Local/offline ishlash va maxfiylik uchun Ollama integratsiyasi.
- 7B model: tez va yengil oddiy vazifalar uchun.
- 14B model: murakkabroq vazifalar uchun (resurs ko‘proq).
- Hybrid mode: local model + kerak bo‘lsa cloud fallback.

### 4) Safety / Guardrails
- Ruxsat etilgan actionlar ro‘yxati (allowlist).
- Xavfli buyruqlarni bloklash.
- “Apply changes”dan oldin diff ko‘rsatish va tasdiq olish.

### 5) UX
- `/dev`, `/ai-builder`, `/dev-audit` kabi alohida bo‘limlar.
- Oddiy foydalanuvchilardan to‘liq yashirilgan navigatsiya.
- “Builder sandbox” rejimi.