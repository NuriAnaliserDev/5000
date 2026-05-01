# Bosqich 1 — MVP «maydonda ishlaydi»

Loyiha holatiga nisbatan tekshiruv ro‘yxati (yangi ishga tushirish yoki regressiya).

## Mahsulot tekshiruvi

| Talab | Kod / joy |
|-------|-----------|
| Kirish / ro‘yxat | [auth_screen.dart](../../lib/screens/auth_screen.dart) |
| Splash va bootstrap | [splash_screen.dart](../../lib/screens/splash_screen.dart), [app_bootstrap_shell.dart](../../lib/app/app_bootstrap_shell.dart) |
| Asosiy ekran (mobil) | [main_tab_shell.dart](../../lib/app/main_tab_shell.dart), [platform_gate.dart](../../lib/app/platform_gate.dart) |
| Stansiya CRUD | [station_repository.dart](../../lib/services/station_repository.dart), [station_summary_screen.dart](../../lib/screens/station_summary_screen.dart) |
| GPS | [location_service.dart](../../lib/services/location_service.dart), [dashboard_screen.dart](../../lib/screens/dashboard_screen.dart) |
| Rasm / kamera | [smart_camera_screen.dart](../../lib/screens/smart_camera/smart_camera_screen.dart) |
| Mahalliy DB | [hive_db.dart](../../lib/services/hive_db.dart), Hive modellar `*.g.dart` |
| Til (l10n) | [lib/l10n/](../../lib/l10n/), `GeoFieldStrings` |

## Texnik tekshurv

```bash
cd geofield_pro_flutter
flutter analyze
flutter test
```

CI bo‘lmasa ham, har PR oldin shu ikki buyruq **yashil** bo‘lishi kerak.

## Smooth UX (minimal)

- Splash holatlari: [splash_screen.dart](../../lib/screens/splash_screen.dart) (l10n kalitlari)
- Xato ekrani: [error_screen.dart](../../lib/screens/error_screen.dart)
- Marshrut topilmasa: [app_router.dart](../../lib/app/app_router.dart) `_notFound`

## MVP «tayyor» deb e’tirof etish

- Yuqoridagi jadvaldagi asosiy oqimlar real qurilmada 1 kun maydon sinovi.
- Crash + «ma’lumot yo‘qotilmadi» tasdiqlangan.
