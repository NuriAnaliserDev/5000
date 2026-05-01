# Bosqich 0 — Mahsulot charter va tizim

## 1. Asosiy vazifa (JTBD)

Foydalanuvchi **maydonda** loyiha kontekstida **stansiya** yaratadi: GPS, struktur/o‘lchov, foto/ovoz; **internetsiz** ishlaydi; ulanish paytida **bulut bilan sinxron** (ixtiyoriy login).

## 2. MVP chegarasi (v1 «yetarli»)

**Kirish:** ha — [AuthScreen](../../lib/screens/auth_screen.dart), Firebase Auth.

**MVP ichida:** stansiya CRUD, loyiha mayoni, GPS, foto, mahalliy Hive, asosiy sinxron stub/ish jarayoni, splash/xato/l10n.

**Keyingi relizlar:** KML keng import, jamoa rollari, murakkab konflikt UI, to‘liq web paritet — alohida PR.

## 3. Ma’lumot modeli (joriy kod)

| Domen | Asosiy fayl |
|-------|-------------|
| Stansiya | [station.dart](../../lib/models/station.dart) |
| O‘lchov | [measurement.dart](../../lib/models/measurement.dart), Hive adapterlar |
| Marshrut | [track_data.dart](../../lib/models/track_data.dart) |
| Xarita chizma/struktura | [geological_line.dart](../../lib/models/geological_line.dart), [map_structure_annotation.dart](../../lib/models/map_structure_annotation.dart), [boundary_polygon.dart](../../lib/models/boundary_polygon.dart) |
| Chat | [chat_message.dart](../../lib/models/chat_message.dart), [chat_group.dart](../../lib/models/chat_group.dart) |

Mahalliy saqlash: [hive_db.dart](../../lib/services/hive_db.dart).

## 4. Sinxron konflikt siyosati (hozirgi yondashuv)

- **Manba:** mahalliy Hive — «first class» oflayn.
- **Bulut:** `users/{uid}/stations/{key}` — `SetOptions(merge: true)` ([cloud_sync_service.dart](../../lib/services/cloud_sync_service.dart)).
- **Konflikt:** ikki qurilmada bir `key` bo‘lsa — oxirgi `set` serverda ustun; **maydonda murakkab merge UI yo‘q** — keyinroq mahsulot qarori (review queue / version vector).

**Qabul qilinadigan xatar:** bir vaqtda tahrirlangan bir xil stansiya — ma’lumot yo‘qotilishi mumkin; hujjatlashtirilgan va kerak bo‘lsa keyingi bosqichda yumshatiladi.

## 5. Huquqlar (loyiha darajasida)

- Firebase Auth orqali **UID** chegarasi; Firestore ma’lumotlari user scope.
- Admin/sozlamalar: [AdminScreen](../../lib/screens/admin_screen.dart).

## 6. KPI va qabul mezonlari (AC) — shablon

| KPI | Maqsad | O‘lchash |
|-----|--------|----------|
| Crash-free sessions | > 99% (relizdan keyin) | Crash reporter |
| Stansiya yaratish (muvaffaqiyat) | > 99% oflayn | Analytics / manual dogfood |
| Sinxron (login bilan) | Navbat bo‘shaguncha retry | `CloudSyncService.isSyncing` + log |

**MVP AC (qisqa):**

- Ilova aviamode/offlayn ochiladi, stansiya saqlanadi.
- Internet qaytganda login bo‘lsa navbat ishlaydi.
- `flutter analyze` yashil; asosiy `flutter test` yashil.

## 7. Arxitektura qatlamlari

- **UI:** `lib/screens/`, `lib/widgets/`
- **Services:** `lib/services/` (repository pattern: [station_repository.dart](../../lib/services/station_repository.dart))
- **App composition:** [app_bootstrap.dart](../../lib/app/app_bootstrap.dart), [geo_field_pro_app.dart](../../lib/app/geo_field_pro_app.dart)

Keyingi katta qadam: domain paketiga (optional) ajratish — refaktor narxi baland, faqat jamoa o‘sishi bilan.
