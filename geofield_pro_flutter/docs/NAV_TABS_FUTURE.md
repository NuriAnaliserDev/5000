# Asosiy tablar va «orqaga» (ixtiyoriy loyiha qarori)

Hozirgi usul: [`app_nav_bar.dart`](../lib/utils/app_nav_bar.dart) `pushReplacementNamed` — tab o‘zgarishida avvalgi `Navigator` jamlanmasi almashtiriladi (stack «tab orasida» saqlanmaydi). Bu kichik o‘zgarishlarda yetarli.

Agar product **tab holatini doim saqlab qolish** yoki chuqurroq back yo‘lini xohlasa, taxminan ikki yo‘l:

1. **Shell**: bitta `Scaffold` + `body: IndexedStack` / `PageView` — asosiy 5 ekran bitta ota ichida, bottom nav `index` o‘zgartiradi. Back stack talab qilmasa, loyiha soddaroq.
2. **`go_router` + `StatefulShellRoute`**: yagona yo‘l deklaratsiyasi, tablar `branch` sifatida; refaktor hajmi katta, lekin Flutter ijtimoiy diagrammalarda ko‘p uchraydigan model.

Qaysi variant tanlanishi alohida PR va mahsulot qaroriga bog‘liq.
