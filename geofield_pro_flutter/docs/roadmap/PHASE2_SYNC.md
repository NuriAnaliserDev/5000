# Bosqich 2 — Oflayn va sinxron ishonchliligi

## Joriy implementatsiya

| Komponent | Fayl |
|-----------|------|
| Navbatcha ishlov | [cloud_sync_service.dart](../../lib/services/cloud_sync_service.dart) — `_processSyncQueue`, connectivity listener |
| Stansiya yozuvi | `users/{uid}/stations/{key}`, merge `set` |
| Marshrut (shift log) | `shift_logs` kolleksiyasi, `isSynced` |
| Chat navbati | `pending` → yuborish, xato bo‘lsa keyingi urinish |
| Belgilangan sinxron holat | [HiveDb.syncStateBox](../../lib/services/hive_db.dart) (`station_$key` va hokazo) |

## Retry va oflayn

- **Retry:** chat xatosi → status `pending`; keyingi `triggerSync` / connectivity hodisasi.
- **Stansiya:** muvaffaqiyatsiz `false` → `syncStateBox` da `true` bo‘lmaydi, qayta urinish mumkin.
- **Internet tekshiruvi:** `hasRealInternet()` (xizmat ichida).

## Mahsulot yo‘nalishlari (keyingi yaxshilanishlar)

- Foydalanuvchiga **aniq progress** (nechta yozuv navbatda) — UI layer.
- **Konflikt ekrani** — hozir merge siyosati soddа (server merge); kelajakda `updatedAt` / vector clock.
- **Eksport** — [export_service.dart](../../lib/services/export_service.dart), [pdf_export_service.dart](../../lib/services/pdf_export_service.dart)

## Monitoring

- `debugPrint` mavjud — production uchun **Crashlytics / Sentry** qo‘shish tavsiya etiladi (loyiha qarori).
- Muhim hodisalar: sinxron boshlandi/tugadi, navbat hajmi, xato turi.

## Dogfood AC

1. Aeroport rejimi 30 daqiqa: stansiya qo‘shish, ilovani qayta ishga tushirish — ma’lumot saqlangan.
2. Wi‑Fi: login bilan sinxron — Firestore’da hujjat paydo bo‘lgani yoki Storage URL.
