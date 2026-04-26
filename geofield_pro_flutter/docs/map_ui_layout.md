<!-- # Xarita va navigatsiya: tugmalar QAYSI `.dart` faylda -->
'
Eslatma: **koordinatlar (top/left) emas**, faqat **fayl → tugma** bog‘lanishi. Joylashuvni o‘zingiz fayl ichida qidirasiz (`Positioned`, `Stack`).

## Asosiy xarita ekrani

| Nima (tugma / qatlam) | Fayl |
|----------------------|------|

<!-- | Barcha umumiy `Stack` va pastki tugmalar guruh (`_buildSideControls`: struktur, slice, SOS, 3D, track) | `lib/screens/global_map_s\creen.dart` | -->
| Yuqoridagi loyiha sarlavhasi, uslub, qidiruv | `lib/screens/map/components/map_top_bar.dart` |
| GPS holati (pill) | `lib/screens/map/components/map_gps_hud.dart` |
| Legend (past chap) | `lib/screens/map/components/map_legend.dart` |
| Jonli marshrut statistikasi (yuqorida) | `lib/screens/map/components/map_live_track_stats.dart` |
| Chizish rejimi, chizg‘ich, qator turlari, undo/saqlash | `lib/screens/map/components/map_linework_controls.dart` |
| Proyeksiya (qavatlar) va chuqurlik slayderi | `lib/screens/map/components/map_projection_controls.dart` |
| Qatlam paneli, import/eksport, shaffoflik | `lib/screens/map/components/map_layer_drawer.dart` |
| Chizgilar (poliliniya) chizilishi | `lib/screens/map/components/map_linework_layer.dart` |
| Stansiyalar | `lib/screens/map/components/map_station_layer.dart` |
| Marshrut (track) chizgisi | `lib/screens/map/components/map_track_layer.dart` |
| Struktur (strike/dip) belgilar | `lib/screens/map/components/map_structure_markers_layer.dart` |
| Kesim (2 nuqta) | `lib/screens/map/components/map_slice_button.dart` — chaqiruv `global_map_screen.dart`da |
| SOS | `lib/screens/map/components/map_sos_button.dart` |
| 3D xarita | `lib/screens/map/components/map_three_d_button.dart` |
| Marshrut yozish FAB | `lib/screens/map/components/map_track_fab.dart` |
| Jamoa / SOS signal qatlamlari (ixtiyoriy) | `map_team_presence_layer.dart`, `map_sos_signals_layer.dart` |

## Pastdagi o‘tsira navigatsiya (barcha asosiy ekranlar)

| Tugmalar (Asosiy, Xabarlar, Xarita, …) | `lib/utils/app_nav_bar.dart` — vidjet: `AppBottomNavBar` |

## Chiqish (logout)

Faqat eslatma: tizimdan chiqish **tugmasi** `admin` / web sozlamalarida, `lib/screens/admin_screen.dart` va `lib/screens/web/...` (sidebar).

---

Ilgari bu faylda faqat `Positioned` raqamlari bo‘lgan; siz aytgandek, sizga kerak bo‘lgani **fayl ro‘yxati** edi. Yuqorida shu.
