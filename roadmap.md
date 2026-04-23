# GeoField Pro — EXECUTION ROADMAP

> **Bu reja agent uchun ishchi dokument.** Har bir bosqich oldingi bosqichga bog'liq. Hech qanday bosqich oldindan boshlanmaydi. Hech qanday fayl 400 qatordan oshmaydi.

**Maqsad:** QField + FieldMove + Geology Toolkit + GeoKit'dan ustun, iOS-silliq, `.exe` desktop + Android geologik platforma.

**Asosiy tamoyillar:**
- **Kichik fayllar**: max 400 qator (ideal 150-300)
- **Bitta mas'uliyat**: har fayl bir maqsadga xizmat qiladi
- **Ortga moslik**: eski ma'lumotlar buzilmasin (Hive typeId o'zgarmaydi)
- **Test avval**: matematik funksiya yozilsa — test yoziladi
- **Dependency to'g'ri**: har bosqich o'zidan oldingisi yakunlangach boshlanadi
- **Kommitlar kichik**: har kichik ish alohida kommit

---

## BOG'LIQLIK GRAFI

```
┌─────────────────────────────────────────────────────────┐
│ BOSQICH 1: BUILD YASHIL (P0)                            │
│ — barcha keyingilari shunga bog'liq. Hech narsa qila    │
│   olmaymiz dastur qurilmasa.                            │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
┌──────────────────────┐  ┌──────────────────────────┐
│ BOSQICH 2: MATH      │  │ BOSQICH 3: ARCHITECTURE  │
│ CORE                 │  │ — GpsBroadcaster         │
│ — GeoConstants       │  │ — Lazy Providers         │
│ — Unified UTM        │  │ — StereonetEngine bitta  │
│ — True Thickness (3) │  │ — Duplikat fayl o'chirish│
│ — Real WMM           │  │                          │
└──────────┬───────────┘  └──────────┬───────────────┘
           │                         │
           └────────────┬────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│ BOSQICH 4: PERFORMANCE + UX                             │
│ — Selector refactor (Math + Arch tayyor bo'lgach)       │
│ — Stereonet cache (Math yadrosi tayyor bo'lgach)        │
│ — ARB localization                                      │
│ — Animation, Cupertino scroll                           │
└──────────────────────┬──────────────────────────────────┘
                       ▼
          ┌────────────┴────────────┐
          ▼                         ▼
┌──────────────────────┐  ┌──────────────────────────┐
│ BOSQICH 5: EXPORT    │  │ BOSQICH 6: SECURITY      │
│ — DXF HEADER+UTM     │  │ — Hive encryption        │
│ — PDF Cyrillic       │  │ — PIN hash               │
│ — CSV BOM            │  │ — SOS offline queue      │
│ — Shapefile          │  │ — Rate limit             │
└──────────┬───────────┘  └──────────┬───────────────┘
           │                         │
           └────────────┬────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│ BOSQICH 7: EXE DASHBOARD + TEST + CI                    │
│ — Windows desktop shell                                 │
│ — Map canvas editor                                     │
│ — Data console                                          │
│ — 50+ unit testlar                                      │
│ — GitHub Actions                                        │
└─────────────────────────────────────────────────────────┘
```

---

# BOSQICH 1 — BUILD YASHIL (P0)

**Davomiylik:** 1-2 kun
**Muvaffaqiyat kriteriyasi:** `dart analyze` → 0 xato (warning qolishi mumkin)
**Bog'liq:** Hech kimga (boshlang'ich bosqich)
**Bosqichdan keyin:** hamma keyingilari shundan keyin bajariladi

## 1.1 Models qatlami — etishmovchi fayllar

### 1.1.1 `lib/models/project.dart` yaratish
- **Hajm:** ~60 qator
- **Mazmun:** `Project` class (id, name, createdAt, description, stations count)
- **Ishlatadi:** `archive_screen.dart`
- **Ishlatuvchilar:** Archive, Settings, PDF reports
- **Test:** Oddiy constructor test, `Project.fromMap` round-trip

**Bog'liq fayllar (o'qish uchun):**
- `station_repository.dart` — project string'dan qanday ishlatilmoqda
- `settings_controller.dart` — projects list

## 1.2 Shared komponentlar — etishmovchi

### 1.2.1 `lib/widgets/station_tile.dart` yaratish
- **Hajm:** ~120 qator
- **Mazmun:** `StationTile` widget (recent stations'da ishlatiladi)
- **Ishlatadi:** `dashboard_widgets_2.dart`
- **Import:** `models/station.dart`, `utils/app_localizations.dart`
- **Design:** Card + lat/lng + strike/dip + rockType + onTap

### 1.2.2 `lib/widgets/dashboard/dashboard_mini_map_box.dart` yaratish
- **Hajm:** ~150 qator
- **Mazmun:** Dashboard mini-map (user joylashuvi + aylanadagi stansiyalar)
- **Ishlatadi:** `dashboard_screen.dart`
- **Bog'liq:** `LocationService`, `StationRepository`, `flutter_map`

## 1.3 Dashboard bilan bog'liq parametrlar

### 1.3.1 `DashboardSliverAppBar` parametrlar qo'shish
- **Fayl:** `lib/widgets/dashboard/dashboard_widgets_2.dart`
- **Ish:** `const DashboardSliverAppBar({super.key, required this.settings, required this.isDark});`
- **`dashboard_screen.dart:93` bilan mos kelishi kerak**

### 1.3.2 Dashboard_widgets_2 importlari tuzatish
- `../station_tile.dart` → `../station_tile.dart` (1.2.1'da yaratilgan)
- `intl` import — foydalaniladi, saqlanadi
- `cloud_sync_service` importini olib tashlash (dashboard_components.dart)

## 1.4 Archive ekran

### 1.4.1 `archive_screen.dart` importlar
- `'../services/track_service.dart'` qo'shish
- `'../models/track_data.dart'` qo'shish
- `'../utils/app_nav_bar.dart'` qo'shish (`AppBottomNavBar` uchun)
- `'../models/project.dart'` — olib tashlash yoki 1.1.1 ishlatish

## 1.5 Smart Camera

### 1.5.1 Camera paketi API migratsiya
- **Fayl:** `lib/screens/smart_camera/components/camera_side_controls.dart`
- **Muammo:** `FlashMode` — `camera: ^0.11` da import yo'li o'zgargan
- **Yechim:** `import 'package:camera/camera.dart' show FlashMode;` yoki yangi API nomi

### 1.5.2 `smart_camera_screen.dart` scope xatosi
- **Qator:** 428
- **Muammo:** `settings` 438-qatorda e'lon qilingan, 428'da ishlatilgan
- **Yechim:** 438'dagi e'lonni 420 atrofiga ko'chirish

### 1.5.3 `ArStrikeDipOverlay` import yo'li
- **Fayl:** `lib/screens/smart_camera/smart_camera_screen.dart:26`
- **Noto'g'ri:** `'components/ar_strike_dip_overlay.dart'`
- **To'g'ri:** `'../components/ar_strike_dip_overlay.dart'`

### 1.5.4 `camera_top_bar.dart` Provider pattern
- **Muammo:** `LocationService.of(context)` — bunday method yo'q
- **Yechim:** `Provider.of<LocationService>(context)` yoki `context.watch<LocationService>()`

## 1.6 Station Form

### 1.6.1 `station_form_body.dart` majburiy parametrlar
- `onOpenPainter` va `onPlayAudio` parametrlarini qabul qilish va `StationFieldAssets`ga o'tkazish
- **Fayl hajmi:** ~170 qator (hozir 157)
- **Inline `TextEditingController()` olib tashlash** — State'ga o'tkazish (memory leak bug)

### 1.6.2 `station_coordinate_section.dart` null safety
- **Qator:** 149
- **Muammo:** `s.accuracy.toStringAsFixed` — accuracy nullable
- **Yechim:** `s.accuracy?.toStringAsFixed(1) ?? '—'`

## 1.7 Station Summary Screen

### 1.7.1 Rock va Munsell importlarini to'g'rilash
- **Noto'g'ri:** `'../utils/data/rock_data.dart'` (yo'q)
- **To'g'ri:** `'../utils/rocks_list.dart'` (mavjud)
- `rockTree` → `rocksList.rockTree` yoki global'ga moslashtirish
- `munsellColors` → `'../utils/munsell_data.dart'`'dan import

## 1.8 Global Map

### 1.8.1 Generic cast xatolari
- **Qatorlar:** 253, 266
- **Muammo:** `List<dynamic>` → `List<GeologicalLine>` assign
- **Yechim:** `.cast<GeologicalLine>().toList()` yoki map'da type'ni aniq yozish

### 1.8.2 Unused variable
- **Qator:** 212
- **Muammo:** `lineRepo` unused
- **Yechim:** Olib tashlash yoki ishlatish

## 1.9 Scale Assistant

### 1.9.1 `AppBottomNavBar` import
- **Fayl:** `lib/screens/scale_assistant_screen.dart:155`
- **Import qo'shish:** `'../utils/app_nav_bar.dart'`

## 1.10 Boundary Service

### 1.10.1 `FilePicker.platform` → yangi API
- **Fayl:** `lib/services/boundary_service.dart:148`
- **Muammo:** `file_picker: ^11` da `FilePicker.platform` deprecated
- **Yechim:** `FilePicker.platform.pickFiles(...)` → `FilePicker().pickFiles(...)` yoki yangi versiya dokumentatsiyasiga qarash

## 1.11 Coordinate Converter bug

### 1.11.1 `formatUtm` N/S tuzatish
- **Fayl:** `lib/utils/coordinate_converter.dart:51`
- **Muammo:** Janub uchun ham "N" chiqaradi
- **Yechim:** `lat < 0 ? 'S' : 'N'`

## 1.12 Map Legend null safety

### 1.12.1 `currentPos` null-check
- **Fayl:** `lib/screens/map/components/map_legend.dart:68`
- **Yechim:** Local variable'ga promote qilish yoki `?.` ishlatish

## 1.13 Warninglar (ixtiyoriy, keyinroq)

- Unused imports (20+ joy)
- Unused local variables
- `dart:ui` unnecessary imports

## ✅ 1-Bosqich DoD (Definition of Done)
- [ ] `dart analyze` error count = 0
- [ ] Oddiy smoke test o'tadi
- [ ] Dashboard ochiladi
- [ ] Station qo'shish ishlaydi
- [ ] Archive ochiladi

---

# BOSQICH 2 — MATEMATIK YADRO

**Davomiylik:** 3-4 kun
**Bog'liq:** Bosqich 1
**Keyingisiga berilganlari:** Bosqich 3, 4 (arxitektura va performance ushbu modullarni ishlatadi)

## 2.1 GeoConstants yaratish

### 2.1.1 `lib/utils/geo_constants.dart` — ~50 qator
Yagona manba:
- `wgs84A = 6378137.0` (semi-major)
- `wgs84F = 1.0 / 298.257223563` (flattening)
- `wgs84E2 = f * (2 - f)`
- `meanEarthRadius = 6371000.0` (3D operatsiyalar uchun)
- `utmK0 = 0.9996`

### 2.1.2 Hamma joyda ishlatish
- `geology_utils.dart:37-41` → GeoConstants
- `spatial_calculator.dart:10` → GeoConstants
- `three_d_math_utils.dart:11` → GeoConstants
- `geological_projection_service.dart:44` → GeoConstants
- `coordinate_converter.dart` — o'chiriladi

## 2.2 UTM Unifikatsiya

### 2.2.1 `coordinate_converter.dart` O'CHIRISH
- Kim ishlatadi: grep orqali topib `GeologyUtils.toUTM` ga almashtirish

### 2.2.2 `geology_utils.dart:toUTM` `N/S` return tuzatish
- Hozir: `"$zone${lat >= 0 ? 'N' : 'S'} E:$e N:$n"` — OK
- Lekin: bu **string**, dashboard'dagi ba'zi joylarda `Map` kerak
- Yangi method: `static UtmCoord toUtmStruct(double lat, double lng)` qaytaradi `UtmCoord` class (zone, hemisphere, easting, northing, meridianConvergence)

### 2.2.3 `lib/utils/utm_coord.dart` — ~80 qator
```
class UtmCoord {
  final int zone;
  final bool isNorth;
  final double easting;
  final double northing;
  final double meridianConvergence; // degrees
  final double pointScaleFactor;
  String get display => "$zone${isNorth ? 'N' : 'S'} E:${easting.toStringAsFixed(0)} N:${northing.toStringAsFixed(0)}";
}
```

## 2.3 True Thickness 3 Formula

### 2.3.1 `lib/utils/thickness_calculator.dart` — ~150 qator
Uch holat:
1. **Horizontal ground, section ⊥ strike:** `TT = W × sin(δ)`
2. **Horizontal ground, section arbitrary:** `TT = W × sin(δ) × sin(β)` yerda β = strike vs traverse
3. **Dipping/sloping ground:** Palmer 1918 to'liq formula:
   ```
   TT = W × (sin α · cos β · sin δ ± cos α · sin δ · cos β)
   ```
   ± — traverse yo'nalishi va dip yo'nalishi bir tomondami (−) yoki qarama-qarshi (+)

### 2.3.2 `geology_utils.dart:trueThickness` — OLIB TASHLASH
Ortga moslik uchun `@Deprecated` bilan wrap qilib 3.1 versiya'dan to'liq o'chirish.

### 2.3.3 Station formiga UI qo'shish
- Thickness tab — 3 holat tanlash
- "Traverse type" tanlash → formula dinamik o'zgaradi

## 2.4 Real WMM Integratsiya

### 2.4.1 WMM2025.COF fayl
- **Yuklab olish:** NOAA NGDC'dan
- **Joylashuv:** `assets/wmm/WMM2025.COF`
- **pubspec.yaml:** `assets:` bo'limiga qo'shish

### 2.4.2 `lib/utils/wmm/wmm_model.dart` — ~200 qator
- `WMMModel.loadFromAsset()` — COF fayl parse (12 darajali spherical harmonic)
- `WMMModel.declination(lat, lng, altKm, decimalYear)` — haqiqiy declination

### 2.4.3 `lib/utils/wmm/wmm_coefficients.dart` — ~250 qator
- `COFParser` — NOAA format parse
- Gauss coefficients matritsasi

### 2.4.4 `geo_orientation.dart` yangilash
- `_estimateDeclination` → `WMMModel.declination`
- `_wmmDeclinationTable` — **O'CHIRISH** (yolg'on edi)

### 2.4.5 Offline fallback
- Agar asset yuklanmasa (web'da) — 2020 reference oddiy formula

## 2.5 Axial (Bidirectional) Statistics

### 2.5.1 `lib/utils/circular_stats.dart` — ~120 qator
- `CircularStats.mean(angles)` — unimodal (0-360)
- `CircularStats.axialMean(lines)` — bimodal/axial (0-180): `(circMean(2·θ) / 2)`
- `CircularStats.stdDev`, `axialStdDev`
- Fisher statistics (2D + spherical 3D variants)

### 2.5.2 `geology_utils.dart` Refactor
- Circular functions'ni `circular_stats.dart`ga ko'chirish
- `fisherStats` — hozirgini qoldirish + yangi `fisher3D(poles)` qo'shish

### 2.5.3 `rose_tab.dart` Axial tuzatish
- `final bin = ((s.strike % 180) / binSize).floor() % _binCount;`
- BinCount'ni 0-180 ga moslashtirish (bu bidirectional rose)

### 2.5.4 `statistics_tab.dart` axial'ni ishlatish
- `circularMean` → `axialMean`
- StdDev ham axial

## 2.6 Stereonet Mean Pole 3D

### 2.6.1 `stereonet_engine.dart` yangi method
- `meanPole(List<{dipDir, dip}>)` — 3D unit vector sum, normalize, convert back to dipDir/dip
- Return `ProjectedPoint` (pre-projected)

### 2.6.2 `stereonet_painter.dart:204-232` yangilash
- Arifmetik o'rtacha olib tashlash
- `StereonetEngine.meanPole(...)` ishlatish
- α₉₅: **great-circle projection** `α₉₅` burchakda mean pole atrofida

## 2.7 Geology Validator kengaytirish

### 2.7.1 `geology_validator.dart` — ~120 qator
- Strike ↔ DipDirection izchilligi
- GPS accuracy check (threshold)
- Measurements list validatsiya
- Altitude limits (±8848/-500m)
- Required field rules

## ✅ 2-Bosqich DoD
- [ ] `coordinate_converter.dart` o'chirilgan
- [ ] Barcha joyda `GeoConstants` ishlatiladi
- [ ] `thickness_calculator.dart` 3 formulani qo'llab-quvvatlaydi
- [ ] Real WMM2025 ishlatiladi, test da ±0.5° aniqlik
- [ ] Circular stats axial/unimodal ajratilgan
- [ ] 20+ unit test o'tadi: `dart test test/utils/`

---

# BOSQICH 3 — ARXITEKTURA BIRLASHTIRISH

**Davomiylik:** 2-3 kun
**Bog'liq:** Bosqich 1 (build) + Bosqich 2 (math) ishlatiladi
**Keyingisiga berilganlari:** Bosqich 4 performance

## 3.1 GPS Broadcaster

### 3.1.1 `lib/services/gps/gps_broadcaster.dart` — ~180 qator
- Yagona `Geolocator.getPositionStream()` ochadi
- Multiple listeners (Location, Track, Presence, Smart Camera)
- Subscribe/unsubscribe pattern

### 3.1.2 `location_service.dart` refactor
- Geolocator stream'ni o'chirish, `GpsBroadcaster.instance.positions`'ga subscribe
- Shahidligi: faqat "hozirgi GPS" ko'rsatish va GpsStatus hisoblash

### 3.1.3 `track_service.dart` refactor
- Stream'ni `GpsBroadcaster`'dan olish
- O'zining Geolocator stream'ini o'chirish
- `_onPositionUpdate` logic'i saqlanadi

### 3.1.4 Natija
- Batareya: ~30-40% kamayish (bitta GPS chip bitta stream)
- Tezlik: bir stansiya qo'shish = bitta GPS o'qish (debounce'ga qaramay)

## 3.2 Stereonet Unifikatsiya

### 3.2.1 `stereonet_calculator.dart` O'CHIRISH
- Foydalanuvchilarni (`PdfExportService`, boshqalar) `StereonetEngine`'ga o'tkazish

### 3.2.2 `stereonet_engine.dart` alohida fayl
- `geology_utils.dart`'dan ko'chirish (~120 qator)
- `StereonetEngine`, `StereonetProjection`, `ProjectedPoint`, `meanPole`
- `calculateGreatCircle` — parametrlarni yaxshilash

## 3.3 Lazy Providers

### 3.3.1 `main.dart` yangilash
- `lazy: true` har qayerda qo'llanilsa
- Ba'zilari darhol kerak (CloudSync, Theme, Auth), boshqalari keyin (BoundaryService, SosService, PresenceService)

### 3.3.2 Provider organization
- `lib/app/providers.dart` — ~100 qator (providerlarni alohida faylga)
- `main.dart` — ~80 qator (faqat init + runApp)

### 3.3.3 Service lifecycles
- `BoundaryService` — faqat map ekranida yoqiladi
- `PresenceService` — login'dan keyin
- `SosService` — background'da doimiy

## 3.4 SplashScreen init UX

### 3.4.1 `lib/screens/splash_screen.dart` yangilash
- Init progress ko'rsatish:
  - "Firebase init..." (30%)
  - "Local DB..." (50%)
  - "Offline tiles..." (70%)
  - "WMM model..." (90%)
  - "Ready" (100%)
- Xato bo'lsa — ErrorScreen ko'rsatish (oq ekran emas)

### 3.4.2 `lib/screens/error_screen.dart` yaratish
- Xato sabab, retry tugma, log yuborish

## 3.5 Fixed `\$e` escaped bug

5 ta faylda escaped `\$e` — to'g'rilash:
- `gis_export_service.dart:191`
- `ai_lithology_service.dart:101,102`
- `mine_report_repository.dart:66,76`

## 3.6 Inline TextEditingController

### 3.6.1 `station_form_body.dart:135`
- `azimuthController: TextEditingController()` → parent state'ga ko'chirish

## 3.7 Routes organization

### 3.7.1 `lib/app/router.dart` — ~120 qator
- `main.dart` dan `onGenerateRoute` ajratib chiqarish
- Type-safe route names va arguments

### 3.7.2 Arguments safety
- `final args = settings.arguments as String?;` → null check bilan

## ✅ 3-Bosqich DoD
- [ ] Bitta GPS stream ishlaydi (log'da ko'rinadi)
- [ ] `stereonet_calculator.dart` o'chirilgan
- [ ] `coordinate_converter.dart` o'chirilgan
- [ ] Providerlar 70%+ lazy
- [ ] SplashScreen progress bor
- [ ] 5 ta `\$e` bug tuzatilgan
- [ ] `main.dart` < 100 qator

---

# BOSQICH 4 — PERFORMANCE + SILLIQLIK

**Davomiylik:** 3-4 kun
**Bog'liq:** Bosqich 1, 2, 3
**Keyingisiga berilganlari:** Bosqich 7 EXE (desktop uchun ham shu optimallashtirish)

## 4.1 Selector Refactor

### 4.1.1 `dashboard_screen.dart`
- `context.watch<StationRepository>()` → `Selector<StationRepository, List<Station>>`
- `context.watch<SettingsController>()` → `Selector` (faqat currentProject + currentUserRole)

### 4.1.2 `dashboard_components.dart:DashboardMiniMapBox`
- `Consumer<LocationService>` → `Selector<LocationService, LatLng?>`

### 4.1.3 `fisher_reliability_tile.dart`
- StatefulWidget + memoization
- Faqat stations.length o'zgarganda qayta hisoblash

### 4.1.4 Dashboard memoization
- Filtered stations list'ni cache qilish (project + count hash)

## 4.2 Stereonet Painter Cache

### 4.2.1 `stereonet_painter.dart` refactor
- Density grid'ni `computeAsync` + cache
- `shouldRepaint` — MapEquality ishlatish
- `List<Station>` — immutable reference (copyWith yangi ref beradi)

### 4.2.2 Offscreen render
- `Picture` / `Image` cache (bir marta chizib, keyin raster)

## 4.3 ARB Lokalizatsiya

### 4.3.1 `app_localizations.dart` 934 qator → ARB
- `lib/l10n/app_uz.arb`
- `lib/l10n/app_ru.arb`
- `lib/l10n/app_en.arb`
- `flutter_gen_l10n` integratsiya

### 4.3.2 `pubspec.yaml` flutter_localizations qo'shish

### 4.3.3 Avval 934 qatorlik faylni 3 ARB faylga ajratish
- Yaxshisi: 10-15 modul bo'yicha ajratish (auth, dashboard, analysis, camera, etc.)

## 4.4 Smart Camera Decomposition

### 4.4.1 `smart_camera_screen.dart` 678 qator → ~250 qator
Ajratiladigan qismlar:
- `smart_camera_controller.dart` (~200) — state + logic (camera init, capture, recording)
- `smart_camera_sensors.dart` (~150) — accelerometer, gyroscope, compass logic
- `smart_camera_ai.dart` (~80) — AI analysis triggering
- `smart_camera_screen.dart` (~250) — faqat UI + wire up

## 4.5 Animatsiyalar

### 4.5.1 `PageRouteBuilder` custom transitions
- `lib/app/transitions.dart` — ~80 qator
- Slide, Fade, Hero pattern

### 4.5.2 Dashboard entrance animatsiyalari
- Staggered grid fade-in
- Station tile shimmer on load

### 4.5.3 `BouncingScrollPhysics` barcha scroll uchun
- Yagona `AppScrollPhysics` (platformga qarab: iOS=Bouncing, Android=Clamping)

## 4.6 Theme Refactor

### 4.6.1 `lib/app/theme.dart` — ~200 qator
- Light + Dark theme
- ColorScheme'da `primary`, `secondary`, `tertiary`, `error`
- `AppColors` — const'lar (hozirgi 0xFF1976D2 va boshqalar)
- Tema kengaytmalari (`AppColorsExtension`)

### 4.6.2 Grep & Replace
- `Color(0xFF1976D2)` → `theme.colorScheme.primary`
- `Colors.orange` → `theme.colorScheme.tertiary`
- `Colors.red` → `theme.colorScheme.error`

## 4.7 Presence Service optimizatsiya

### 4.7.1 Interval 30s → 120s
- Dala geologida 30s overkill
- Admin panel'dan interval boshqarish

### 4.7.2 Delta-only updates
- Faqat 10m'dan ko'p siljish bo'lsa yuborish
- Batareya va Firestore billing

## 4.8 Track Service Isolate

### 4.8.1 Hive writes isolate'ga
- `compute()` ishlatib `track.save()` ni main thread'dan chiqarish
- Lekin Hive isolate-safe emas — keyinlik'dan ko'rib chiqish (yoki `isar` ga migratsiya)

## ✅ 4-Bosqich DoD
- [ ] Dashboard scroll 60 FPS (DevTools profile)
- [ ] Stereonet 500 station paint <16ms
- [ ] ARB integratsiya ishlaydi
- [ ] smart_camera_screen.dart < 300 qator
- [ ] Tema o'zgarsa barcha ranglar o'zgaradi
- [ ] `app_localizations.dart` < 100 qator (faqat helper)

---

# BOSQICH 5 — EKSPORT TUZATISH

**Davomiylik:** 2-3 kun
**Bog'liq:** Bosqich 1, 2 (math core — UTM kerak)
**Keyingisiga berilganlari:** Bosqich 7 (test uchun fixture'lar)

## 5.1 DXF AutoCAD-ready

### 5.1.1 `lib/services/export/dxf_writer.dart` — ~300 qator
- To'liq DXF R12/R14 format
- SECTION HEADER (ACADVER, $INSBASE, $EXTMIN, $EXTMAX)
- SECTION TABLES (LAYER definitions)
- SECTION ENTITIES
- SECTION EOF

### 5.1.2 UTM konvertatsiya
- GPS coords → UTM (Northing/Easting, metric)
- Meridian convergence qaydi

### 5.1.3 `export_service.dart` refactor
- `exportToDxf` → `DxfWriter.write(stations, tracks, lines, useUtm: true)`
- Dashboard message: "DXF AutoCAD'da UTM Zona X'da ochiladi"

## 5.2 CSV UTF-8 BOM

### 5.2.1 `export_service.dart:exportToCsv`
- `'\uFEFF' + buffer.toString()` — Excel uchun
- Quoted string'lar escape (hozir OK)

## 5.3 PDF Cyrillic Font

### 5.3.1 `assets/fonts/NotoSans-Regular.ttf`, `NotoSans-Bold.ttf` yuklab olish
- pubspec.yaml'ga qo'shish

### 5.3.2 `pdf_export_service.dart` font load
- `pw.Document()` da `theme: pw.ThemeData.withFont(base: notoSans, bold: notoSansBold)`
- Cyrillic chiqadi

### 5.3.3 Photolar haqiqiy image embedding
- `pw.MemoryImage(await file.readAsBytes())`
- Thumbnail (resize to 150×100 with `image` paketi)

## 5.4 JORC Template To'liq

### 5.4.1 `lib/services/export/jorc_pdf_builder.dart` — ~350 qator
- Sampling Techniques table
- QA/QC procedures
- Sample preparation
- Deposit type and mineralization style
- Criteria table (Table 1 JORC 2012)

### 5.4.2 Sertifikat bo'limi
- Qualifications of the Qualified Person
- Date and signature block

## 5.5 GPX metadata

### 5.5.1 `export_service.dart:exportTracksToGpx`
- `<metadata><name>...</name><time>...</time><bounds>...</bounds></metadata>`
- `<wpt>` waypoints (stansiyalar)

## 5.6 Shapefile Support (YANGI)

### 5.6.1 `lib/services/export/shapefile_writer.dart` — ~300 qator
- ESRI Shapefile (.shp + .shx + .dbf + .prj)
- Points (stations), Lines (tracks), Polygons (boundaries)
- PRJ: WGS84 WKT string

### 5.6.2 Archive export menyusiga qo'shish
- QField compatibility

## 5.7 Background Export

### 5.7.1 Katta eksport'lar isolate'da
- `compute()` bilan 1000+ records
- UI loading dialog bilan

## ✅ 5-Bosqich DoD
- [ ] DXF AutoCAD'da to'g'ri ochiladi (test)
- [ ] CSV Excel'da cyrillic to'g'ri
- [ ] PDF'da "O'zgarishlar" — haqiqiy matn
- [ ] Shapefile ZIP QGIS'da ochiladi
- [ ] Katta eksport UI freeze qilmaydi

---

# BOSQICH 6 — XAVFSIZLIK

**Davomiylik:** 2-3 kun
**Bog'liq:** Bosqich 1, 3 (lazy providers uchun)
**Parallel mumkin:** Bosqich 5 bilan

## 6.1 Hive Encryption at Rest

### 6.1.1 `lib/services/security/encryption_manager.dart` — ~120 qator
- Master key generation (flutter_secure_storage)
- HiveAesCipher wrap
- Migration from plain → encrypted (versiya)

### 6.1.2 `hive_db.dart` yangilash
- Barcha `openBox` lar encryption cipher bilan

### 6.1.3 Migration strategy
- `hive_version` setting — agar v1 plain bo'lsa, v2'ga encrypt qilib ko'chirish

## 6.2 PIN Hashing

### 6.2.1 `security_service.dart` yangilash
- `savePin` → salt + PBKDF2 (crypto paketi) hash
- `verifyPin` → hash taqqoslash
- **ONLY HASH stored, never plain PIN**

## 6.3 SOS Offline Queue

### 6.3.1 `lib/services/sos/sos_queue.dart` — ~150 qator
- Hive box `sos_queue`
- `enqueue(signal)` — local save
- `tryFlush()` — connectivity bo'lganda
- SMS fallback integration

### 6.3.2 SMS fallback
- `url_launcher` → `sms:emergency_number?body=SOS+coords`

### 6.3.3 `sos_service.dart` refactor
- Yuborish → queue, connectivity'da flush
- UI: "SOS queued (offline), will send when online"

## 6.4 AI Rate Limiting

### 6.4.1 `lib/services/ai/ai_rate_limiter.dart` — ~80 qator
- Hive: `ai_quota` box (user_id → today_count)
- Default: 20/day per user
- Admin override via Firestore config

### 6.4.2 `ai_lithology_service.dart` yangilash
- Har chaqiruvdan oldin `rateLimiter.consume()`
- Quota exceeded → UI xabar

## 6.5 Firestore Security Rules

### 6.5.1 `firestore.rules` yozish (loyiha root'ida)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid}/stations/{stationId} {
      allow read, write: if request.auth.uid == uid;
    }
    match /presence/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }
    match /emergency_signals/{doc} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
      allow update: if request.auth.uid == resource.data.senderUid;
    }
    match /global_boundaries/{doc} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(db)/documents/users/$(request.auth.uid)).data.role in ['admin','geologist_senior'];
    }
  }
}
```

### 6.5.2 firebase.json'ga qo'shish

## 6.6 Audit Trail Kuchaytirish

### 6.6.1 `station_repository.dart` audit entries
- Barcha maydonlar uchun audit (hozir faqat 8 ta)
- `measurementType`, `dipDirection`, `sampleType`, `confidence`, `munsellColor`, `lat/lng`

### 6.6.2 Audit tabular view (admin panel)

## 6.7 firebase_options.dart Gitignore

### 6.7.1 `.gitignore` yangilash
- `lib/firebase_options.dart`

### 6.7.2 CI environment variable
- GitHub Actions secrets'dan file generate qilish

## ✅ 6-Bosqich DoD
- [ ] Hive fayllar shifrlangan (eski plain yo'q)
- [ ] PIN hash shaklida saqlanadi
- [ ] SOS offline'da ishlaydi (test: airplane mode)
- [ ] AI rate limit — 21-chi chaqiruv rejected
- [ ] firestore.rules deploy qilingan
- [ ] firebase_options.dart git'dan chiqarilgan

---

# BOSQICH 7 — EXE DASHBOARD + TEST + CI

**Davomiylik:** 7-10 kun
**Bog'liq:** Bosqich 1-6 hammasi tayyor
**Bu eng katta bosqich — EXE dashboard yangi platforma**

## 7.1 Windows Build Sozlash

### 7.1.1 `flutter doctor` yashil
- Visual Studio 2022 (Desktop C++ workload) — foydalanuvchi o'rnatgan
- Windows SDK
- Test: `flutter run -d windows`

### 7.1.2 `windows/` katalog yangilash
- App icon (ico format)
- App name
- Version info

## 7.2 Desktop Shell

### 7.2.1 `lib/screens/desktop/` yangi katalog
- `desktop_shell.dart` — ~250 qator — ana layout
- `desktop_sidebar.dart` — ~150 qator — chap panel
- `desktop_map_canvas.dart` — ~300 qator — katta markaziy xarita
- `desktop_right_panel.dart` — ~180 qator — attributes/edit
- `desktop_bottom_panel.dart` — ~150 qator — logs/tasks

### 7.2.2 Hotkeys
- `lib/screens/desktop/desktop_hotkeys.dart` — ~80 qator
- Ctrl+S save, Ctrl+Z undo, Ctrl+Y redo, F focus map

### 7.2.3 Session restore
- Hive'ga: oxirgi loyiha, zoom, center, layers

## 7.3 Desktop Map Editor

### 7.3.1 `lib/screens/desktop/editor/` — vector editing
- `geometry_editor_controller.dart` — ~200 qator
- `snap_engine.dart` — ~150 qator
- `undo_redo_stack.dart` — ~120 qator
- `topology_validator.dart` — ~180 qator

### 7.3.2 Operations
- Select, Move vertex, Add vertex, Delete vertex
- Split line, Merge polygons, Simplify (Douglas-Peucker)
- Snap to stations, tracks, boundaries (meters)

### 7.3.3 Undo/Redo
- Command pattern
- Shortcut hotkeys

## 7.4 Desktop Data Console

### 7.4.1 `lib/screens/desktop/console/` katalog
- `data_console_screen.dart` — ~250 qator
- `advanced_filter_builder.dart` — ~200 qator
- `bulk_edit_panel.dart` — ~180 qator
- `validation_engine.dart` — ~150 qator
- `import_preview_screen.dart` — ~220 qator

### 7.4.2 Features
- SQL-like filters (date, project, author, rock type, status)
- Bulk field update with preview
- Conflict detection in import
- CSV/GeoJSON/Shapefile import

## 7.5 Desktop vs Mobile Routing

### 7.5.1 `lib/app/platform_gate.dart` — ~60 qator
- `Platform.isWindows` → DesktopShell
- `Platform.isAndroid/iOS` → MobileShell
- `kIsWeb` → WebDashboardMain

### 7.5.2 Main navigation tree
```
App
├── Mobile: DashboardScreen → ...
├── Web:    WebDashboardMain → ...
└── Desktop: DesktopShell → ...
```

## 7.6 Test Coverage

### 7.6.1 Unit Tests — `test/utils/`
- `test/utils/geology_utils_test.dart` (~200 qator, 15+ tests)
  - toDMS, toUTM (reference values)
  - circularMean, axialMean
  - fisherStats (tekshirilgan datasets)
  - apparentDip (known cases)
- `test/utils/thickness_calculator_test.dart` (~150 qator)
- `test/utils/wmm_model_test.dart` (~150 qator)
- `test/utils/spatial_calculator_test.dart` (~100 qator)
- `test/utils/stereonet_engine_test.dart` (~150 qator)
- `test/utils/parsers/dxf_parser_test.dart` (~200 qator)
- `test/utils/parsers/kml_parser_test.dart` (~100 qator)

### 7.6.2 Widget Tests — `test/widgets/`
- `test/widgets/dashboard_screen_test.dart`
- `test/widgets/analysis_tabs_test.dart`
- Golden tests (stereonet, rose painters)

### 7.6.3 Integration Tests — `integration_test/`
- Full flow: launch → capture → save → sync → export
- Map interaction
- Offline mode

### 7.6.4 Test Infrastructure
- Mock Firebase
- Mock Hive (`hive_test`)
- Test fixture: `test/fixtures/` (sample DXF, KML, Station lists)

## 7.7 CI/CD — GitHub Actions

### 7.7.1 `.github/workflows/ci.yml` — ~100 qator
Jobs:
- `analyze` — `dart analyze --fatal-infos`
- `test` — `flutter test --coverage`
- `build-android` — apk build
- `build-windows` — exe build (on windows-latest runner)

### 7.7.2 Codecov integration

### 7.7.3 `.github/workflows/release.yml`
- Tag'da — automated build + release draft

## 7.8 Installer

### 7.8.1 Inno Setup script yoki MSIX package
- `windows/runner/Runner.iss` yoki MSIX config
- Offline install tested

## 7.9 Admin Panel Desktop

### 7.9.1 `lib/screens/desktop/admin/`
- User management
- Project management
- Audit viewer
- Firestore usage dashboard

## ✅ 7-Bosqich DoD
- [ ] `flutter build windows --release` → .exe
- [ ] Installer toza Windowsda ishlaydi
- [ ] Test coverage ≥ 40% line, ≥ 60% util
- [ ] CI yashil (har PR'da)
- [ ] Map editor: select, move, undo, snap ishlaydi
- [ ] Data console: filter, bulk edit, import preview ishlaydi

---

# FAYL HAJMI BUDGET

| Tur | Max qator | Tavsiya |
|---|---|---|
| Utility class | 200 | ≤150 |
| Service class | 300 | ≤250 |
| Screen (Stateful) | 400 | ≤300 |
| Widget composition | 250 | ≤200 |
| Painter | 300 | ≤250 |
| Model | 200 | ≤150 |
| Constants | 100 | ≤80 |

**Qoida:** Fayl 400+ qatorga yetsa — DARHOL komponentga bo'lib yuborish.

---

# KOMMIT STRATEGIYASI

Har bosqich ichida sub-task'lar:
- Bitta commit = bitta mantiqiy birlik
- Commit message: `[Bosqich N.M] <nima qilindi>`
- Misol: `[1.1.1] project.dart model qo'shildi`

Bosqich oxirida:
- `[Bosqich N] Completed: <qisqa tavsif>`
- Tag: `v0.N-phase-done`

---

# PROGRESS MONITORING

`PROGRESS.md` faylida har kuni yangilanadi:
- [x] Bosqich 1.1 ✓ 2026-04-23
- [ ] Bosqich 1.2 (ish ustida)
- ...

Hozirgi ish doim 1 ta in_progress item bo'ladi.

---

# BIRINCHI QADAM (HOZIROQ)

## Bosqich 1.1.1 → boshlanadi
**Vazifa:** `lib/models/project.dart` yaratish (~60 qator)

**Kerakli ma'lumot:**
- `station.dart`'dagi `project` field (nullable String)
- `settings_controller.dart`'dagi `projects` list
- `archive_screen.dart` qanday ishlatmoqchi ekanini tekshirish

**Tugatilgach:**
- [1.1.1] commit
- 1.1.2'ga o'tish (station_tile.dart)

---

# SOZLAMA HAJM

Butun loyiha hozir: 24,117 qator
**4 hafta keyin taxmin:**
- Mavjud kod: ~16,000 qator (re-organized, cleaned)
- Yangi kod: ~8,000 qator (thickness, WMM, shapefile, desktop, tests)
- **Jami:** ~24,000 qator (shunga yaqin, lekin tarkib puxta)

Fayllar soni:
- Hozir: ~120 Dart fayl
- 4 hafta keyin: ~180-200 (chunki kichik fayllarga bo'linadi)
- O'rtacha fayl hajmi: 120-150 qator
