# Firebase va Google Cloud — ishlab chiqarish va to‘lov (Blaze)

Bu ro‘yxat ilovani **real foydalanuvchilar va pulli servislar** (Firestore oqimi, Storage, Vertex AI / Firebase AI Logic va h.k.) bilan ishlashga tayyorlash uchun.

## 1. Reja va billing

1. [Firebase Console](https://console.firebase.google.com) → loyiha → **Upgrade** → **Blaze** (faqat shundan keyin miqdordan tashqari xizmatlar to‘liq ishlaydi).
2. [Google Cloud Console](https://console.cloud.google.com) → **Billing** → hisob-ulightingiz bog‘langanini tekshiring.
3. **Budgets & alerts**: Cloud Console → Billing → Budgets — oy yoki haftalik limit va e-mail/SMS ogohlantirishlar.
4. **Firebase Usage** va **Cloud Billing reports** ni muntazam ko‘rib turish.

## 2. Firebase konfiguratsiyasi

- Barcha platformalar uchun `google-services.json` / `GoogleService-Info.plist` / veb uchun Firebase konfigi **produksiya loyihasi** bilan mos.
- `flutterfire configure` yoki qo‘lda yangilangan `firebase_options.dart` lokal fayllar **commit qilinmasin** (maxfiy kalitlar bo‘lsa).

## 3. Firestore

**Tezkor (loyiha ildizidan):**

- Windows: `tool\deploy_firestore_rules.bat` — ikki marta bosib ishga tushiring (oxirida `pause`).
- Git Bash / macOS / Linux: `bash tool/deploy_firestore_rules.sh`

Yoki qo‘lda:

```bash
cd geofield_pro_flutter
firebase deploy --only firestore:rules
```

**Eslatma:** deploy **faqat sizning kompyuteringizda** `firebase login` bilan ishlaydi; Cursor/agent bulutga sizning nomingizsiz yubora olmaydi.

- `firestore.rules` o‘zgarganda har doim deploy qiling.
- `collectionGroup('shift_logs')` so‘rovlari uchun Firestore indekslari kerak bo‘lsa, xatolik matnida berilgan havoladan indeks yarating.
- Ishlab chiqarishda **ma’lumotlar tuzilmasi** va backup strategiyasi (eksport / snapshot)ni rejalashtiring.

## 4. Authentication

- Ishlatilayotgan kirish usullari (Email, Google va h.k.) Firebase Authentication da yoqilgan.
- **Authorized domains** (veb) ro‘yxatiga produksiya domeningiz qo‘shilgan.

## 5. Storage (agar foydalanilsa)

- `storage.rules` ni deploy qiling: `firebase deploy --only storage`.
- Yuklashlar uchun maxfiy URL lar va CORS sozlamalari tekshirilsin.

## 6. App Check (tavsiya etiladi)

- Firestore / Storage / Funksiyalarni **noqonuniy klient**dan himoya qilish uchun App Check ni yoqing (veb: reCAPTCHA, mobil: Play Integrity / DeviceCheck).

## 7. AI / Vertex

- Firebase AI Logic / Vertex AI ishlatilsa, Cloud Console da tegishli **API yoqilgan** va **kvota** kuzatiladi.
- Foydalanuvchi kvotasi ilova ichida cheklangan bo‘lsa ham, bulut tomonda xarajat bo‘lishi mumkin.

## 8. Monitoring

- Firebase **Crashlytics**, **Performance**, **Analytics** (kerak bo‘lsa) produksiya buildlarda ulangan.
- Muhim xatoliklar uchun **alerting** (Cloud Monitoring yoki Firebase orqali).

---

**Qisqa:** Blaze + billing ogohlantirishlari + `firestore:rules` (va kerak bo‘lsa `storage:rules`) deploy, indekslar, Auth domenlari, App Check va AI API — shu qatlam **“to‘lab ishlatish”** uchun minimal operatsion asos.
