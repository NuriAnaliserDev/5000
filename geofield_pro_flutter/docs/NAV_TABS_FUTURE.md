# Asosiy tablar va marshrutlar

## Mobil (joriy)

[`MainTabShell`](../lib/app/main_tab_shell.dart): bitta `Scaffold`, `body` ichida `IndexedStack` (Dashboard, Xarita, Kamera, Arxiv) va har bir tab uchun alohida [`Navigator`](https://api.flutter.dev/flutter/widgets/Navigator-class.html) (`GlobalKey<NavigatorState>`). Pastki [`AppBottomNavBar`](../lib/utils/app_nav_bar.dart) `useShellNavigation: true` bilan tab indeksini almashtiradi (`pushReplacementNamed` emas).

- Tablar orasida vidjetlar tirik qoladi (xarita/kamera holati saqlanadi).
- Har bir tab ichidagi `push`/`pop` (masalan, xaritadan stansiya) o‘sha tab `Navigator`ida saqlanadi. Ilova darajasidagi marshrutlar (`/station`, `/painter`, …) odatda `Navigator.of(context, rootNavigator: true)` orqali [`MaterialApp.onGenerateRoute`](../lib/app/app_router.dart)ga uchraydi.
- Shell tashqarisidagi ekranlar (masalan, chat) uchun [`MainTabNavigation`](../lib/app/main_tab_navigation.dart) shell bo‘lmasa avvalgi kabi `pushNamed` qiladi.

## Keyingi qadam (ixtiyoriy)

**`go_router` + `StatefulShellRoute`**: yagona URL/deep link modeli kerak bo‘lsa — refaktor katta, lekin rasmiy Flutter pattern.
