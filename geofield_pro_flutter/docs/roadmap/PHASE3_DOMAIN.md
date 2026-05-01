# Bosqich 3 — Geologik chuqurlik modullari

Har modul mustaqil «bo‘lak» sifatida rivojlanadi; integratsiya nuqtalari: repository va ekranlar.

## Xarita

| Qism | Fayl |
|------|------|
| Asosiy xarita | [global_map_screen.dart](../../lib/screens/global_map_screen.dart) + `global_map_screen_state.dart` |
| Pro vositalar | `lib/screens/map/` |
| Tile / oflayn | `flutter_map` + [FMTCTileProvider](../../lib/screens/global_map_screen_state.dart) (cache strategiyasi) |

## Kamera va sensor

| Qism | Fayl |
|------|------|
| Kamera shell | [smart_camera_screen.dart](../../lib/screens/smart_camera/smart_camera_screen.dart), [smart_camera_screen_state.dart](../../lib/screens/smart_camera/smart_camera_screen_state.dart) |
| Geologik overlay | [focus_mode_geology_overlay.dart](../../lib/screens/smart_camera/components/focus_mode_geology_overlay.dart), [geology_stereonet_painter.dart](../../lib/screens/smart_camera/components/geology_stereonet_painter.dart) |
| Orientatsiya | [geo_orientation.dart](../../lib/utils/geo_orientation.dart), WMM [wmm_model.dart](../../lib/utils/wmm/wmm_model.dart) |

## Marshrut / trek

| Qism | Fayl |
|------|------|
| Servis | [track_service.dart](../../lib/services/track_service.dart) |
| Model | [track_data.dart](../../lib/models/track_data.dart) |

## Tahlil

| Qism | Fayl |
|------|------|
| Ekran | [analysis_screen.dart](../../lib/screens/analysis_screen.dart) |

## Dogfooding rejasi

- Har modul uchun **1 haftalik** real maydon skripti (masalan: faqat xarita chizma + eksport).
- Sensor moduli: kamida 2 qurilma (Android/iOS) uchun kalibrlash tekshiruvi.

## Smooth

- Ekspert / oddiy rejim: [settings_controller.dart](../../lib/services/settings_controller.dart) `expertMode`
- Tutorial: [tutorial_coach_mark](https://pub.dev/packages/tutorial_coach_mark) — [smart_camera_screen_state.dart](../../lib/screens/smart_camera/smart_camera_screen_state.dart) ichida chaqiruvlar
