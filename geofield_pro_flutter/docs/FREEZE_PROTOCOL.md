# GEOFIELD PRO — FREEZE PROTOCOL v1 (+ kengaytma)

> **Maqsad:** restart without deleting everything. Kod o‘chirilmaydi; faqat muzlatiladi va bitta disiplin bilan boshqariladi.

Asl matn: `Freeze APP.txt` (desktop). Bu fayl **qoida + 5 ta kritik qatlam** ni birlashtiradi.

---

## Yagona feature manbasi

Barcha “hozircha yoqilmaydigan” narsalar:

- `lib/core/config/app_features.dart` → **`AppFeatures`**

```dart
AppFeatures.enableAR         // ARCore/ARKit + lithology AR overlay
AppFeatures.enableAI         // Gemini / real backend (false → mock)
AppFeatures.enableCloudSync  // fon sinxron + SyncProcessor.run
```

Kodda tarqalgan `if (...)` o‘rniga avvalo shu konstantalarni qo‘llang.

---

## 1. DEPENDENCY FREEZE (kritik)

`pubspec.yaml` ichida:

- **Taqiqlangan:** “latest”, tasodifiy major update, tekshirilmagan yangi paket.
- Har yangi paket uchun checklist:
  - **WHY?** — muammo aniq gapirilishi kerak
  - **SIZE?** — APK/compile vaqt
  - **MAINTAINED?** — oxirgi release, issue lar
  - **ANDROID / IOS / WEB impact?** — ayniqsa: **AR, camera, map, firebase, permission, ffmpeg** guruhi

> Hozirgi dependencylar `^x.y.z` bilan pin qilingan; freeze davrida versiyani faqat xavfsizlik yoki bloklovchi bug uchun ko‘taring.

---

## 2. FEATURE FLAGS

Bitta joy: **`AppFeatures`**. “Ghost feature” va tasodifiy yoqilgan AI loop shu yerda to‘xtatiladi.

---

## 3. BUILD DISCIPLINE (kritik)

Har katta o‘zgarishdan keyin (majburiy tartib):

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Windows: `scripts/verify_build.bat`  
Git Bash / CI: `scripts/verify_build.sh`

> Hot reload ≠ production build.

---

## 4. LOG STRATEGY

Matnli diagnostika va konsol uchun yagona prefixlar:

- `lib/core/diagnostics/log_channels.dart` → **`DiagLogChannel`**
- `[BOOT] [CAMERA] [MAP] [GPS] [AI] [CACHE] [SYNC] [ERROR]`

`DiagnosticService.logPrefixed(DiagLogChannel.boot, '...')` dan foydalaning.

---

## 5. DEAD CODE GRAVEYARD (kritik)

Freeze paytida **o‘chirmaysiz** — **ko‘chirasiz:**

- `legacy/` — eski lekin hali import bo‘lmasligi mumkin bo‘lgan qatlam
- `archive/` — aniq tarixiy snapshot
- `experimental/` — sinov, productionga ulanmagan

Har papkada `README.md`: nima uchun, qachon qaytariladi.

---

## Darhol muzlatilgan (asliga)

| Bo‘lim | Status | Izoh |
|--------|--------|------|
| AR tizimi | FREEZE | `AppFeatures.enableAR = false` |
| Advanced AI | FREEZE | `AppFeatures.enableAI = false` → mock |
| Firebase complexity | PARTIAL | `enableCloudSync = false` — fon queue muzlatilgan |
| Desktop/Web product | FREEZE | maqsad v0.1: **Android field notebook** |

## Qoladigan REAL CORE

- Ochilish, crashsiz ish, GPS, oddiy kamera, stansiya saqlash, PDF eksport, offline.

## Prinsiplar (qisqa)

1. Feature before abstraction  
2. No invisible magic  
3. No god objects  
4. Offline first  
5. Har async → timeout  

## v0.1-alpha (30 kun)

Ochiladi, crash qilmaydi, GPS, kamera, stansiya, PDF, offline — **keyin** AI/AR qaytadi.
