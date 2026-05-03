# GeoField Pro — BOSQICHMA-BOSQICH REJA
> Har bir ish oldingi ishga bog'liq. Bitta mavzu — oxirigacha tugatiladi.

---

## BLOK 0: TAYYORGARLIK (Kun 0)

### 0.1 — Loyihani tushunish
- [x] `pubspec.yaml` o'qish — barcha dependency versiyalarini bilish
- [x] `main.dart` o'qish — Provider'lar ro'yxati
- [x] `dart analyze > analyze_before.txt` — 40 xatoni saqlash (taqqoslash uchun)

### 0.2 — Yagona konstantalar (BIRINCHI yaratiladi, hamma ishlatadi)
- [x] `lib/core/geo_constants.dart` YARATISH
```dart
class GeoConstants {
  static const double wgs84A = 6378137.0;      // WGS84 semi-major
  static const double earthRadius = 6378137.0; // hamma joyda bir xil
  static const double earthFlattening = 1/298.257223563;
}
```
- [x] `three_d_math_utils.dart` → `GeoConstants.earthRadius` ishlatish
- [x] `spatial_calculator.dart` → `GeoConstants.wgs84A` ishlatish
- [x] `geological_projection_service.dart` → `GeoConstants.earthRadius` ishlatish

**✅ Tekshiruv:** 3 faylda `6371000` va `6378137` hardcode qolmagan bo'lishi kerak

---

## BLOK 1: MODEL QATLAMI (Kun 1)

> Modellar hamma narsaning asosi. Birinchi tuzatiladi.

### 1.1 — `project.dart` YARATISH (yo'q, import xatosi bor)
- [x] `lib/models/project.dart` yaratish
```dart
@HiveType(typeId: 10)
class Project extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String description;
  @HiveField(3) DateTime createdAt;
  @HiveField(4) String leadGeologist;
}
```
- [x] `project.g.dart` — `dart run build_runner build` bilan generatsiya
- [x] `hive_db.dart` → `Project` box ro'yxatdan o'tkazish

### 1.2 — `track_data.dart` eksport tekshiruvi
- [x] `track_data.dart` ichida `TrackData` va `TrackPoint` class'lari bor ekanini tekshirish
- [x] `archive_screen.dart` importini tekshirish: `TrackData`, `TrackService` to'g'ri import

**✅ Tekshiruv:** `dart analyze lib/models/` — 0 xato

---

## BLOK 2: ASOSIY SERVISLAR — GPS (Kun 1-2)

> GPS barcha servislar uchun asos. Bitta stream — hamma ishlatadi.

### 2.1 — `GpsBroadcaster` YARATISH
- [x] `lib/services/gps/gps_broadcaster.dart` YARATISH
```dart
class GpsBroadcaster {
  static final instance = GpsBroadcaster._();
  GpsBroadcaster._();
  StreamController<Position>? _controller;
  StreamSubscription? _sub;

  Stream<Position> get stream {
    _controller ??= StreamController<Position>.broadcast();
    return _controller!.stream;
  }

  void init(LocationSettings settings) {
    _sub ??= Geolocator.getPositionStream(locationSettings: settings)
        .listen(_controller!.add);
  }

  void dispose() { _sub?.cancel(); _controller?.close(); }
}
```

### 2.2 — `location_service.dart` REFAKTOR
- [x] `Geolocator.getPositionStream()` ni olib tashlash
- [x] `GpsBroadcaster.instance.stream.listen(...)` ga o'tkazish
- [x] `LocationService.of()` method'ini Provider orqali qo'shish (camera_top_bar xatosi)

### 2.3 — `track_service.dart` REFAKTOR
- [x] `Geolocator.getPositionStream()` ni olib tashlash
- [x] `GpsBroadcaster.instance.stream.listen(...)` ga o'tkazish
- [x] Hive write → `compute()` orqali izolat qilingan yozuv

### 2.4 — `main.dart` ga GPS init qo'shish
- [x] `GpsBroadcaster.instance.init(settings)` — app startup'da bir marta

**✅ Tekshiruv:** GPS stream faqat 1 marta ochilayotgani logda ko'rinadi

---

## BLOK 3: XAVFSIZLIK QATLAMI (Kun 2-3)

> Encryption modellardan keyin, servislardan oldin qilinadi.

### 3.1 — Hive Encryption
- [x] `flutter_secure_storage` bilan kalit generatsiya
- [x] `hive_db.dart` — barcha box'larni `HiveAesCipher` bilan ochish:
  - `stations`, `tracks`, `projects`, `chat_messages`, `audit_entries`

### 3.2 — PIN xavfsizligi
- [x] `security_service.dart` → `savePin()` — bcrypt hash + salt
- [x] `verifyPin()` — hash taqqoslash (plain text emas)

### 3.3 — Firebase options himoyasi
- [x] `.gitignore` ga `lib/firebase_options.dart` qo'shish
- [x] CI uchun environment variable template yaratish

**✅ Tekshiruv:** `.hive` faylni notepad bilan ochganda — shifrlangan matn ko'rinishi

---

## BLOK 4: WIDGET / IMPORT XATOLARI (Kun 3)

> Bu yerda build yashil bo'ladi.

### 4.1 — `dashboard_screen.dart` xatolari
- [x] `dashboard_widgets_2.dart` → `DashboardSliverAppBar({settings, isDark})` parametrlari qo'shish
- [x] `dashboard_mini_map_box.dart` ichida `DashboardMiniMapBox` class mavjud ekanini tekshirish
- [x] `dashboard_screen.dart` importini `dashboard_mini_map_box.dart` ga to'g'rilash

### 4.2 — `archive_screen.dart` xatolari
- [x] `TrackService` import → `../../services/track_service.dart`
- [x] `TrackData` import → `../../models/track_data.dart`
- [x] `AppBottomNavBar` import → `../../utils/app_nav_bar.dart`
- [x] `project.dart` import → `../../models/project.dart` (1.1 da yaratildi)

### 4.3 — `station_form_body.dart` xatolari
- [x] `TextEditingController()` inline → `StatefulWidget` ichida `late final` controller
- [x] `StationFieldAssets` ga `onOpenPainter` va `onPlayAudio` parametrlarini o'tkazish

### 4.4 — `station_coordinate_section.dart`
- [x] `s.accuracy?.toStringAsFixed` → null-safe: `s.accuracy?.toStringAsFixed(1) ?? '–'`

### 4.5 — `station_summary_screen.dart`
- [x] `rockTree` → `rocks_list.dart` dan import
- [x] `munsellColors` → `munsell_data.dart` dan import

### 4.6 — `scale_assistant_screen.dart`
- [x] `AppBottomNavBar` import → `../../utils/app_nav_bar.dart`

### 4.7 — `global_map_screen.dart`
- [x] `List<dynamic>` → `List<GeologicalLine>` explicit cast

### 4.8 — `smart_camera_screen_state.dart`
- [x] `FlashMode` → `CameraFlashMode` (yangi camera paketi API)
- [x] `ArStrikeDipOverlay` import → `components/` to'g'ri yo'l
- [x] `settings` o'zgaruvchi scope xatosi tuzatish

### 4.9 — `camera_side_controls.dart`
- [x] `FlashMode` → `CameraFlashMode` barcha joylarda

### 4.10 — `camera_top_bar.dart`
- [x] `LocationService.of()` → `context.read<LocationService>()` (Provider pattern)

### 4.11 — `boundary_service.dart`
- [x] `FilePicker.platform.pickFiles()` → yangi API: `FilePicker.platform.pickFiles(allowMultiple: false)`

**✅ Tekshiruv:** `dart analyze` — **0 xato**. `flutter run` ishga tushadi.

---

## BLOK 5: DEBUG PRINT XATOLARI (Kun 3 — 1 soat)

> Kichik ammo muhim. Exception ko'rinmaydi.

### 5.1 — `\$e` escaped bug — 5 faylda
- [x] `gis_export_service.dart:191` → `'$e'` emas `$e`
- [x] `ai_lithology_service.dart:101` → tuzatish
- [x] `ai_lithology_service.dart:102` → tuzatish
- [x] `mine_report_repository.dart:66` → tuzatish
- [x] `mine_report_repository.dart:76` → tuzatish

**✅ Tekshiruv:** Exception bo'lganda log'da haqiqiy xato matni ko'rinadi

---

## BLOK 6: MATEMATIK QATLAM — GEOLOGIK HAQIQAT (Kun 4-6)

> Bu blok bitta modul — `geology_utils.dart`. Barchasini birga qilamiz.

### 6.1 — `GeoConstants` ni barcha matematik fayllar ishlatishi
- [x] `geology_utils.dart` → `GeoConstants.wgs84A` ishlatish
- [x] `utm_wgs84.dart` → `GeoConstants.wgs84A`
- [x] `coordinate_converter.dart` — tekshirish, kerak bo'lsa o'chirish (UTM 2 marta ishlab turibdi)

### 6.2 — `coordinate_converter.dart` — janubiy yarim shar bagi
- [x] `formatUtm()` → janubiy yarim shar uchun `S` harfi chiqishi

### 6.3 — True Thickness — 3 formulaga bo'lish
- [x] `geology_utils.dart:trueThickness()` — quyidagi 3 holatga ajratish:
  - **Perpendicular traverse:** `TT = W × sin(dip)`
  - **Oblique traverse:** `TT = W × (sinα·cosβ·sinδ ± cosα·sinδ)`
  - **Vertical traverse:** `TT = W × sin(dip) × cos(traverseSlope)`
- [x] `TraverseType` enum qo'shish
- [x] `station_structural_section.dart` → TraverseType tanlash UI

### 6.4 — Rose Diagram bidirectional bin
- [x] `rose_strike_binning.dart` → `strike % 180` (180° simmetriya)
- [x] `rose_tab.dart` → bin hisoblash yangilash

### 6.5 — Mean Pole — 3D vektor
- [x] `stereonet_density.dart` yoki `stereonet_widget.dart` → mean pole:
```dart
// Eski: meanX += p.x; (XATO)
// Yangi:
double sx=0, sy=0, sz=0;
for (final p in poles) {
  sx += p.x; sy += p.y; sz += p.z; // unit vektorlar yig'indisi
}
final len = sqrt(sx*sx + sy*sy + sz*sz);
final meanPole = Offset(sx/len, sy/len); // keyin proyeksiya
```

### 6.6 — Fisher statistics — axial (bidirectional)
- [x] `geology_utils.dart:fisherStats()` → `2×strike mod 360` usuli
- [x] α₉₅ → great-circle sifatida proyeksiya

### 6.7 — `plungeTrendToDipStrike` — nomini o'zgartirish
- [x] `geology_utils.dart` → `lineationToVector()` deb qayta nomlash
- [x] Ishlatilgan joylarni yangilash

**✅ Tekshiruv:** Unit testlar (6.8) orqali

### 6.8 — Unit testlar (matematika uchun)
- [x] `test/geology_utils_test.dart` yaratish:
  - UTM Toshkent: `(41.2995, 69.2401)` → `38T, E:456xxx, N:4571xxx`
  - Apparent dip: `dip=30°, angle=45°` → `22.2°`
  - Haversine: Toshkent→Samarqand → `~270 km`
  - Fisher κ: bir xil yo'nalish → `κ > 1000`
  - Rose bin: `170°` va `350°` → bitta bin (`170°`)
  - True thickness perpendicular: `W=10, dip=30°` → `5.0m`

---

## BLOK 7: WMM MAGNETIC DECLINATION (Kun 6-7)

> GPS va matematik blokdan keyin. WMM hamma joyda ishlatiladi.

### 7.1 — WMM2025.COF yuklab olish
- [x] `assets/wmm/WMM2025.COF` — NOAA saytidan yuklab qo'yish
- [x] `pubspec.yaml` → assets ro'yxatiga qo'shish

### 7.2 — WMM Parser YARATISH
- [x] `lib/utils/wmm/wmm_parser.dart` YARATISH
  - `.COF` fayl formatini o'qish (n, m, gnm, hnm, dgnm, dhnm)
  - Legendre polynomials hisoblash
  - Spherical harmonic summation

### 7.3 — `WmmCalculator` YARATISH
- [x] `lib/utils/wmm/wmm_calculator.dart` YARATISH
```dart
class WmmCalculator {
  static Future<double> getDeclination(
    double lat, double lng, DateTime date
  ) async { ... } // aniqlik: ±0.3°
}
```

### 7.4 — `geo_orientation.dart` ALMASHTIRISH
- [x] Eski lookup table → `WmmCalculator.getDeclination()` chaqiruv
- [x] `smart_camera_screen_state.dart` → `WmmCalculator` ishlatish
- [x] `station_structural_section.dart` → declination tuzatish

**✅ Tekshiruv:** Toshkent uchun declination ≈ `+2.5°` (NOAA online bilan taqqoslash)

---

## BLOK 8: PERFORMANCE — PROVIDER VA REBUILD (Kun 7-8)

> GPS va servislar tayyor bo'lgandan keyin qilinadi.

### 8.1 — Provider lazy loading
- [x] `main.dart` → barcha Provider'lar `lazy: true` qilinsin
- [x] Faqat kerak bo'lganda yaratiladi: `BoundaryService`, `MineReportRepository`, `PresenceService`

### 8.2 — Splash screen progress
- [x] `splash_screen.dart` → init bosqichlarini ko'rsatish:
  - "Hive ishga tushmoqda..."
  - "GPS ulanmoqda..."
  - "Sinxronizatsiya tekshirilmoqda..."
- [x] Xato bo'lsa `error_screen.dart` ga yo'naltirish (hozir oq ekran)

### 8.3 — Dashboard `Consumer` → `Selector`
- [x] `dashboard_screen.dart:45-52` → `Selector<StationRepository, List<Station>>`
- [x] `dashboard_screen.dart:112` → `Selector<LocationService, LatLng>`
- [x] `stereonet_painter.dart` → `shouldRepaint` `MapEquality.equals()` ishlatish

### 8.4 — Presence timer optimallashtirish
- [x] `presence_service.dart` → 30s → 120s (4x kamroq Firestore write)
- [x] Faqat pozitsiya o'zgarganda yuborish (threshold: 50m)

### 8.5 — Stereonet density grid cache
- [x] `stereonet_density.dart` → density grid `paint()` da emas, `notifyListeners()` da hisoblash
- [x] `RepaintBoundary` bilan o'rash

**✅ Tekshiruv:** Flutter DevTools → 60fps dashboard scroll

---

## BLOK 9: SOS OFFLINE QUVVATLASH (Kun 8)

> GPS va Hive tayyor bo'lgandan keyin.

### 9.1 — SOS offline queue
- [x] `lib/services/sos/sos_queue.dart` YARATISH (Hive box)
- [x] `sos_service.dart:sendSos()` → avval Hive'ga yoz, keyin Firestore
- [x] Connectivity listener → online bo'lganda queue'ni yuborish

### 9.2 — SMS fallback
- [x] `url_launcher` paketi bilan: `sms:+998XXXXXXXXX?body=SOS...`
- [x] Internet yo'q bo'lganda SMS dialog chiqarish

**✅ Tekshiruv:** Offline rejimda SOS bosilganda — Hive'ga yoziladi, online bo'lganda yuboriladi

---

## BLOK 10: AI RATE LIMITING (Kun 8 — 2 soat)

### 10.1 — Kunlik limit
- [x] `ai_lithology_service.dart` → `flutter_secure_storage` da kun+soni saqlash
- [x] Kuniga 20 ta tahlildan keyin: "Limit tugadi, ertaga urinib ko'ring"

**✅ Tekshiruv:** 21-marta bosishda chiroyli xato xabari

---

## BLOK 11: EKSPORT TUZATISH (Kun 9-10)

> Matematik va model bloklar tayyor bo'lgandan keyin.

### 11.1 — CSV UTF-8 BOM
- [x] `export_service.dart` → `'\uFEFF' + csvContent`

### 11.2 — DXF — UTM + HEADER
- [x] `gis_export_service.dart` → GPS daraja → UTM konvertatsiya
- [x] DXF HEADER, TABLES bo'limlari qo'shish
- [x] **Test:** AutoCAD yoki DXF Viewer'da ochilishi

### 11.3 — PDF Cyrillic font
- [x] `assets/fonts/NotoSans-Regular.ttf` qo'shish
- [x] `pubspec.yaml` → fonts ro'yxatiga qo'shish
- [x] `pdf_export_service.dart` → `pw.Font.ttf(fontData)` barcha TextStyle'larda
- [x] PDF'ga haqiqiy rasmlar embedding (hozir faqat fayl nomi)

### 11.4 — GPX metadata
- [x] `export_service.dart` → `<metadata>` bloki: time, bounds, author

### 11.5 — Export → Isolate
- [x] `export_service.dart` → `compute(csvWorker, data)` pattern
- [x] `pdf_export_service.dart` → `Isolate.run()`

**✅ Tekshiruv:** 
- Excel'da CSV: Cyrillic to'g'ri ko'rinadi
- AutoCAD'da DXF: koordinatalar to'g'ri joyda
- PDF'da: O'zbek harflari to'g'ri

---

## BLOK 12: UX SILLIQLIK (Kun 10-11)

### 12.1 — Routing xavfsizligi
- [x] `go_router` → `pubspec.yaml` ga qo'shish
- [x] `main.dart` → `onGenerateRoute` → `GoRouter` ga ko'chirish
- [x] Barcha `pushNamed` → `context.go()` / `context.push()`

### 12.2 — Scroll physics
- [x] `app_scroll_physics.dart` → `BouncingScrollPhysics` — barcha ListView'larda ishlatish
- [x] `dashboard_screen.dart`, `archive_screen.dart`, `station` ekranlari

### 12.3 — Tema ranglar
- [x] `lib/core/app_theme.dart` YARATISH — barcha ranglar bir joyda
- [x] Hardcoded `0xFF1976D2`, `Colors.orange` → `Theme.of(context).colorScheme`

### 12.4 — Sahifa o'tish animatsiyalari
- [x] `GoRouter` → `CustomTransitionPage` — slide/fade animatsiyalar

### 12.5 — SnackBar yagona
- [x] `lib/core/snackbar_helper.dart` YARATISH
- [x] Barcha ekranlarda shu helper ishlatilsin

**✅ Tekshiruv:** iOS'da ilova Apple-like harakat qiladi

---

## BLOK 13: LOKALIZATSIYA (Kun 11)

### 13.1 — ARB formatiga o'tish
- [x] `app_localizations.dart` (934 qator) → `lib/l10n/app_uz.arb` va `app_ru.arb`
- [x] `l10n.yaml` konfiguratsiya
- [x] `flutter gen-l10n` ishga tushirish
- [x] Import o'zgartirishlar barcha faylda

**✅ Tekshiruv:** `flutter gen-l10n` — 0 xato, tarjimalar ishlaydi

---

## BLOK 14: TEST VA CI (Kun 12-14)

### 14.1 — Unit testlar
- [x] `test/geo_constants_test.dart` — konstantalar
- [x] `test/geology_utils_test.dart` — 10 ta test (6.8 da yozilgan)
- [x] `test/wmm_calculator_test.dart` — Toshkent, Moskva, Sydney
- [x] `test/spatial_calculator_test.dart` — Haversine, maydon
- [x] `test/stereonet_test.dart` — Schmidt, Wulff proyeksiya
- [x] `test/export_test.dart` — CSV, GPX, DXF string tekshiruvi
- [x] `test/geology_validator_test.dart` — barcha validatsiya holatlari
- [x] `test/sos_queue_test.dart` — offline queue LIFO/FIFO

### 14.2 — Golden testlar
- [x] `test/golden/stereonet_painter_test.dart`
- [x] `test/golden/rose_diagram_test.dart`

### 14.3 — GitHub Actions CI
- [x] `.github/workflows/ci.yml` YARATISH:
```yaml
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.x' }
      - run: flutter pub get
      - run: dart analyze --fatal-infos
      - run: flutter test
      - run: flutter build apk --release
```

**✅ Tekshiruv:** `flutter test` → 50+ test, hammasi yashil

---

## BLOK 15: AR KAMERA TAKOMILLASHTIRISH (Kun 14-15)

> Camera, GPS va matematik bloklar tayyor bo'lgandan keyin.

### 15.1 — `focus_mode_geology_overlay.dart` integratsiyasi
- [x] `smart_camera_screen_state.dart` → pitch/roll sensorsidan olingan qiymatlar `PlaneData`ga uzatilsin
- [x] `sensors_plus` → accelerometer stream → pitch/roll hisoblash
- [x] `flutter_compass` → azimuth → strikeDeg

### 15.2 — AR Overlay sahnaga to'g'ri ulash
- [x] `geological_ar_view_impl.dart` tekshirish — ARCore/ARKit bor-yo'qligini
- [x] Stub/real view pattern to'g'ri ishlashi

**✅ Tekshiruv:** Telefon harakatlantirilganda 3D tekislik real vaqtda o'zgaradi

---

## YAKUNIY TEKSHIRUV KETMA-KETLIGI

```
dart analyze           → 0 xato, 0 warning
flutter test           → 50+ test yashil
flutter build apk      → APK quriladi
flutter build appbundle → AAB quriladi
```

| Bosqich | Bog'liqlik | Kun |
|---|---|---|
| 0. Tayyorgarlik + GeoConstants | Mustaqil | 0 |
| 1. Model qatlami | 0 dan keyin | 1 |
| 2. GPS / GpsBroadcaster | 1 dan keyin | 1-2 |
| 3. Xavfsizlik / Encryption | 1 dan keyin | 2-3 |
| 4. Widget/Import xatolari | 1,2,3 dan keyin | 3 |
| 5. Debug print xatolari | 4 bilan birga | 3 |
| 6. Matematik / geology_utils | 4,5 dan keyin | 4-6 |
| 7. WMM Calculator | 6 dan keyin | 6-7 |
| 8. Performance / Provider | 2,4 dan keyin | 7-8 |
| 9. SOS offline | 2,3 dan keyin | 8 |
| 10. AI rate limit | 4 dan keyin | 8 |
| 11. Eksport tuzatish | 6 dan keyin | 9-10 |
| 12. UX silliqlik | 4 dan keyin | 10-11 |
| 13. Lokalizatsiya | 4 dan keyin | 11 |
| 14. Test va CI | Barchadan keyin | 12-14 |
| 15. AR Kamera | 2,6,7 dan keyin | 14-15 |
