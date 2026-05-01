#!/usr/bin/env node
/**
 * Legacy Firestore hujjatlariga createdByUid / ownerUid qo‘shish (masalan, yangi qoidalarga moslash).
 *
 * ISHLATISH (0-qadam — quyida README):
 *   cd geofield_pro_flutter/scripts
 *   npm install firebase-admin
 *   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\service-account.json
 *   node firestore_backfill_ownership.mjs --dry-run
 *   node firestore_backfill_ownership.mjs --set-owner <FIREBASE_AUTH_UID>
 *
 * Yoki `backfill.config.json` (namuna: backfill.config.example.json) ichida `defaultOwnerUid`.
 * --dry-run: faqat statistika (o‘zgartirmaydi).
 * --set-owner UID: maydon yo‘q bo‘lgan hujjatlarga ushbu UID yoziladi (faqat ishonchli uid!).
 *
 * Eslatma: noto‘g‘ri uid bilan barcha “yo‘q” hujjatlarni bir kishiga bog‘lash —
 * xavfli; avval dry-run qiling.
 */

import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import process from 'node:process';

const __dirname = dirname(fileURLToPath(import.meta.url));

function parseArgs() {
  const argv = process.argv.slice(2);
  const dryRun = argv.includes('--dry-run');
  let setOwner = null;
  const i = argv.indexOf('--set-owner');
  if (i >= 0 && argv[i + 1]) setOwner = argv[i + 1];
  if (!setOwner) {
    const cfgPath = join(__dirname, 'backfill.config.json');
    if (existsSync(cfgPath)) {
      try {
        const j = JSON.parse(readFileSync(cfgPath, 'utf8'));
        const u = j.defaultOwnerUid || j.setOwner;
        if (typeof u === 'string' && u.trim()) setOwner = u.trim();
      } catch (e) {
        console.warn('backfill.config.json o‘qilmadi:', e.message);
      }
    }
  }
  return { dryRun, setOwner };
}

function initAdmin() {
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (credPath && existsSync(credPath)) {
    const raw = readFileSync(credPath, 'utf8');
    const j = JSON.parse(raw);
    initializeApp({ credential: cert(j) });
    console.log('Firebase Admin: GOOGLE_APPLICATION_CREDENTIALS (JSON)');
    return;
  }
  initializeApp({ credential: applicationDefault() });
  console.log('Firebase Admin: applicationDefault()');
}

async function scanAndFix(db, { dryRun, setOwner }) {
  const collections = [
    { name: 'global_boundaries', field: 'createdByUid' },
    { name: 'geological_lines', field: 'ownerUid' },
    { name: 'map_structure_annotations', field: 'ownerUid' },
  ];

  for (const { name, field } of collections) {
    const snap = await db.collection(name).get();
    let missing = 0;
    let batch = db.batch();
    let batchCount = 0;
    const BATCH_LIMIT = 400;

    for (const doc of snap.docs) {
      const data = doc.data();
      if (data[field] != null && String(data[field]).length > 0) continue;
      missing++;

      if (!dryRun && setOwner) {
        batch.update(doc.ref, { [field]: setOwner });
        batchCount++;
        if (batchCount >= BATCH_LIMIT) {
          await batch.commit();
          batch = db.batch();
          batchCount = 0;
        }
      }
    }

    console.log(`[${name}] jami ${snap.size}, ${field} yo‘q: ${missing}`);

    if (!dryRun && setOwner && batchCount > 0) {
      await batch.commit();
      console.log(`[${name}] yangilandi (batch oxirgi qismi)`);
    }
  }

  if (dryRun) {
    console.log('\nDry-run: hech narsa yozilmadi. Haqiqiy yozish: --set-owner <uid>');
  } else if (!setOwner) {
    console.log('\n--set-owner berilmagan, faqat hisob-kitob chiqarildi (yozuv yo‘q).');
  }
}

const { dryRun, setOwner } = parseArgs();
initAdmin();
const db = getFirestore();
await scanAndFix(db, { dryRun, setOwner });
console.log('\nTayyor.');
process.exit(0);
