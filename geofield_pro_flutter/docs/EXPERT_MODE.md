# Ekspert rejim (`SettingsController.expertMode`)

Hive kaliti: `expertMode` (`settings` qutisi). Foydalanuvchi **Admin** ekranidagi switch orqali yoqadi/o‘chiradi.

## Ta’sir doirasi (yangi ekran qo‘shganda shu ro‘yxatga qo‘shing)

1. **Pastki navigatsiya** — [`app_nav_bar.dart`](../lib/utils/app_nav_bar.dart): «Yana» ochilganda ixtiyoriy **Scale** (`/scale-assistant`) bandi; faqat `expertMode == true` bo‘lsa ko‘rinadi.
2. **Kamera** — [`smart_camera_screen_state.dart`](../lib/screens/smart_camera/smart_camera_screen_state.dart): yon menyu, Pro sheet, HUD/ekspert elementlari; Firestore/eksportdagi stansiya `authorRole` muhitida «Professional» (sozlamaga bog‘liq).
3. **Xarita** — [`global_map_screen.dart`](../lib/screens/global_map_screen.dart): yuboriladigan/yoziladigan profil turi: «Professional» yoki standart.
4. **Stansiya formasi** — [`station_form_body.dart`](../lib/screens/station/components/station_form_body.dart): qo‘shimcha maydonlar va bo‘linishlar.
5. **Veb sozlamalar** — [`web_settings_screen.dart`](../lib/screens/web/web_settings_screen.dart): profil sifat matni (Professional / oddiy).
6. **Boshqalar** — [`dashboard_desktop_header.dart`](../lib/widgets/dashboard/desktop/dashboard_desktop_header.dart), **track** — [`track_service.dart`](../lib/services/track_service.dart) (sozlamani to‘g‘ridan-to‘g‘ri Hive o‘qishi mumkin).

Kodda `context.watch<SettingsController>().expertMode` yoki `settings.expertMode` qidiruvi barcha ishlatilgan joylarni topishga yordam beradi.
