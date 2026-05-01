# Bosqich 4 — Navigatsiya va o‘sish

## Joriy holat (mobil)

- **Tab shell:** [main_tab_shell.dart](../../lib/app/main_tab_shell.dart) — `IndexedStack` + har tab uchun alohida `Navigator`.
- **Tablar orasida o‘tish:** [main_tab_navigation.dart](../../lib/app/main_tab_navigation.dart) + [AppBottomNavBar](../../lib/utils/app_nav_bar.dart) `useShellNavigation`.
- **Ildiz marshrutlar:** [app_router.dart](../../lib/app/app_router.dart).
- **Platforma ajratish:** [platform_gate.dart](../../lib/app/platform_gate.dart) — web/desktop/mobil.

Hujjat: [NAV_TABS_FUTURE.md](../NAV_TABS_FUTURE.md) (joriy yechim va `go_router` ixtiyoriy yo‘l).

## Root marshrutlar (ichki Navigator ustidan)

Qayta tekshirish: murakkab ekranlar (`/station`, `/painter`, `fieldWorkshop`, …) `rootNavigator: true` bilan chaqirilgan bo‘lishi kerak — aks holda tab `Navigator` marshrutni topmaydi. Qidiruv: `rootNavigator: true` in `lib/`.

## Kelajak: go_router + StatefulShellRoute

**Qachon:** deep link, web URL bir xil model, analytics «screen» nomlari.

**Narx:** `MaterialApp` → `MaterialApp.router`, barcha `pushNamed` migratsiyasi.

**Qadamlar (migratsiya):**

1. `go_router` qo‘shish, parallel ravishda eski `onGenerateRoute` saqlash.
2. Asosiy 4 tabni `StatefulShellRoute` branch qilish.
3. `Navigator.pushNamed`ni `context.push`ga almashtirish (bosqichma-bosqich).

## Deep link (ixtiyoriy)

- Android/iOS intent / universal link → `go_router` yoki `AppLink` paketi.
- Minimal: `/map?lat=&lng=` stansiya ochilishi — mahsulot talabi bilan.
