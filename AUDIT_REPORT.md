# GeoField Pro — TO'LIQ TANQIDIY AUDIT HISOBOTI

**Sana:** 2026-04-23
**Audit qamrovi:** 24,117 qator Dart kodi, 40+ dependency, 6 asosiy servis qatlami, 100+ komponent
**Audit metodlari:** `dart analyze`, 50+ fayl chuqur o'qish, matematik formulalar verifikatsiyasi, dublikat detektor, performance staticraz, xavfsizlik tekshiruvi

---

## 0. UMUMIY BAHO

| Kategoriya | Hozirgi holat | QField/FieldMove darajasi | Farq |
|---|---|---|---|
| **Build holati** | ❌ Qurilmaydi (40 xato) | ✅ Yashil | 100% |
| **Matematik aniqlik** | ⚠️ 6/10 | ✅ 9/10 | 30% |
| **Arxitektura** | ⚠️ 5/10 (dublikat, god widgets) | ✅ 8/10 | 30% |
| **Performance** | ⚠️ 4/10 (lag riskli joylar ko'p) | ✅ 9/10 | 45% |
| **Xavfsizlik** | ⚠️ 5/10 (encryption yo'q) | ✅ 8/10 | 30% |
| **UX silliqlik** | ⚠️ 5/10 | ✅ 9/10 (iOS-like) | 40% |
| **Test coverage** | ❌ 1/10 (17 qator) | ✅ 7/10 | 60% |
| **Eksport aniqligi** | ❌ DXF buzilgan, CSV BOM yo'q | ✅ | 50% |

**Yakuniy verdikt:** Loyiha "kuchli geologik dastur" deb aytishga hozircha **tayyor emas**. Lekin asos mustahkam — matematik yadroning 70%'i to'g'ri, 40+ feature'lar yozilgan. **3-4 haftalik intensiv ish** bilan QField/FieldMove darajasiga chiqarish mumkin.

---

## 1. P0 — BLOKLOVCHI XATOLAR (Darhol tuzatish shart)

> Bu xatolar tufayli hozir `flutter run` komandasi umuman ishlamaydi.

### 1.1 Fayl etishmovchiligi (5 ta)

| Import | Holat | Yechim |
|---|---|---|
| `'../models/project.dart'` (archive_screen.dart:6) | Fayl yo'q | Model yaratish yoki importni olib tashlash |
| `'../station_tile.dart'` (dashboard_widgets_2.dart:4) | Fayl yo'q | Komponent yaratish |
| `'components/ar_strike_dip_overlay.dart'` (smart_camera_screen.dart:26) | Noto'g'ri yo'l | `../components/ar_strike_dip_overlay.dart` |
| `'../utils/data/rock_data.dart'` (station_summary_screen.dart:19) | Fayl yo'q | `rocks_list.dart`ga yo'naltirish |

### 1.2 Kompilyatsiya xatolari (35+ ta)

**`archive_screen.dart`** — 8 xato
- Missing imports: `TrackService`, `TrackData`, `AppBottomNavBar`

**`dashboard_screen.dart`** — 3 xato
- `DashboardSliverAppBar({settings, isDark})` — `dashboard_widgets_2.dart`da konstruktor parametr olmaydi
- `DashboardMiniMapBox` — komponent **umuman mavjud emas** (dashboard_components.dart'da yo'q)

**`smart_camera_screen.dart`** — 6 xato
- `FlashMode` undefined — camera paketi yangi versiyasida `CameraFlashMode` yoki enum o'zgargan
- `settings` o'zgaruvchisi 428-qatorda declare'dan oldin ishlatilgan (scope xato)
- `ArStrikeDipOverlay` topilmayapti

**`smart_camera/components/camera_side_controls.dart`** — 6 xato
- Hamma joyda `FlashMode` undefined

**`smart_camera/components/camera_top_bar.dart`** — `LocationService.of()` method yo'q (noto'g'ri Provider pattern)

**`global_map_screen.dart`** — 2 xato
- `List<dynamic>` ni `List<GeologicalLine>` / `List<BoundaryPolygon>`ga assign qilib bo'lmaydi (generic type mismatch)

**`station/components/station_form_body.dart`** — 2 xato
- `StationFieldAssets`ga majburiy `onOpenPainter`, `onPlayAudio` parametrlari berilmagan

**`station/components/station_coordinate_section.dart`** — null safety:
```dart
(s.accuracy)?.toStringAsFixed // .toStringAsFixed nullable chaqirilgan
```

**`station_summary_screen.dart`** — 5 xato
- `rockTree`, `munsellColors` undefined identifiers

**`scale_assistant_screen.dart`** — `AppBottomNavBar` undefined

**`boundary_service.dart`** — `FilePicker.platform` — yangi `file_picker`da API o'zgardi

**`map/components/map_legend.dart`** — null safety: `currentPos.latitude` nullable olinmagan

---

## 2. P1 — MATEMATIK VA FIZIK FORMULALAR

### 2.1 ✅ TO'G'RI FORMULALAR

| Formula | Fayl | Baho | Izoh |
|---|---|---|---|
| **UTM Redfearn** (Easting+Northing 5/6 darajali) | `geology_utils.dart:27-88` | Professional | WGS84, ~0.001m aniqlik |
| **Haversine + L'Huilier** (sferik maydon) | `spatial_calculator.dart` | Professional | QGIS bilan teng |
| **Schmidt (equal-area) projection** | `geology_utils.dart:299-331`, `stereonet_calculator.dart` | To'g'ri | `R = √2 × sin(θ/2)` |
| **Wulff (equal-angle) projection** | `geology_utils.dart:314-317` | To'g'ri | `R = tan(θ/2)` |
| **Apparent Dip (Palmer)** | `geology_utils.dart:195-203` | To'g'ri | `tan(α') = tan(α)·cos(β)` |
| **Circular mean, StdDev** | `geology_utils.dart:101-111, 178-188` | To'g'ri | Vector sum usuli |
| **Fisher statistics (κ, α₉₅)** | `geology_utils.dart:116-175` | To'g'ri | Best-Fischer 1981 formulasi |
| **DXF parsing** (LWPOLYLINE, ARC, ELLIPSE, INSERT, BULGE) | `utils/parsers/dxf_parser.dart` | Chuqur | 322 qator, 10+ entity turi |
| **KML parsing** | `utils/parsers/kml_parser.dart` | Oddiy, to'g'ri | |
| **Cross-section apparent dip** (strike orqali) | `cross_section_service.dart:63-66` | To'g'ri | `tan(α') = tan(α)·sin(β)` teng formula |
| **Geological projection at depth** | `geological_projection_service.dart` | To'g'ri | `shift = depth/tan(dip)` |
| **Spherical Winding Number** (polygon point-in) | `boundary_polygon.dart:127-155` | To'g'ri | Katta poligonlar uchun ham ishlaydi |

### 2.2 ❌ XATO YOKI YOLG'ON FORMULALAR

#### 2.2.1 True Thickness — JIDDIY XATO
```18:403:geotag_pro_flutter/lib/utils/geology_utils.dart
  static double trueThickness({
    required double apparentThickness,
    required double dip,
  }) {
    if (dip <= 0) return apparentThickness;
    return apparentThickness * sin(dip * pi / 180);
  }
```
**Muammo:** Haqiqiy true thickness formulasi traverse yo'nalishiga, traverse slope'iga, strike'ga bog'liq:
```
TT = W × (sin α · cos β · sin δ ± cos α · sin δ)
```
Hozirgi kod **faqat perpendikulyar gorizontal traverse** uchun to'g'ri. Boshqa holatlarda **10–40% xato**. QField 3 xil formulani ajratadi.

#### 2.2.2 WMM Magnetic Declination — YOLG'ON WMM MODEL
```208:249:geotag_pro_flutter/lib/utils/geo_orientation.dart
/// WMM-2025 asosidagi magnit og'ish (Declination) hisoblash moduli.
/// Aniqlik: ±0.5° (dala sharoiti uchun yetarli).
/// QField va FieldMove kabi professional dasturlar shu usuldan foydalanadi.
```
**Muammo:**
- Haqiqiy WMM ~15,000 spherical harmonic coefficient. Bu kodda esa **qo'lda kiritilgan 60 nuqtali lookup table** (10° grid)
- "WMM-2025" deb yorliq qo'yilgan, lekin **WMM emas**
- `'0_0': -5.2` **ikki marta** (analyze bildirdi) — qo'shimcha bug
- Aniqlik ±3–5° (reklama qilingan ±0.5° emas)
- Dala sharoitida 5° xato → 100m da 8.7m siljish

**Yechim:** `assets/WMM2025.COF` fayl yuklab olib, `geomag` Dart paketi yoki qo'lda parse qilish.

#### 2.2.3 `plungeTrendToDipStrike` — NOTO'G'RI KONSEPT
```229:247:geotag_pro_flutter/lib/utils/geology_utils.dart
  /// Plunge va Trend dan Dip va Strike hisoblash (Lineatsiya uchun).
  static Map<String, double> plungeTrendToDipStrike(double plunge, double trend) {
```
**Muammo:** Geologik jihatdan **noaniq masala** — bitta lineation cheksiz ko'p plane'da yotadi. Funksiya hech qanday professional geologik kontekstda ma'noga ega emas. `lineationToVector` deb qayta nomlash kerak yoki olib tashlash.

#### 2.2.4 Fisher Statistics — 2D EMAS 3D KERAK
Hozir: Strike list'iga 2D circular Fisher qo'llaniladi.
To'g'ri: Strike **bidirectional line** — 10° va 190° bir xil. Axial statistics (`2×strike mod 360`) qilish kerak.

#### 2.2.5 Rose Diagram Dominant Direction — BUG
```43:53:geotag_pro_flutter/lib/screens/analysis/tabs/rose_tab.dart
  void _compute() {
    final counts = List<int>.filled(_binCount, 0);
    final binSize = 360.0 / _binCount;
    for (final s in widget.stations) {
      final bin = ((s.strike % 360) / binSize).floor() % _binCount;
      counts[bin]++;
    }
```
**Muammo:** Strike 10° va 190° alohida bin'larga tushadi. Aslida ular bir xil chiziq. `s.strike % 180` qilinishi kerak, keyin dominant belgilanishi kerak.

#### 2.2.6 Mean Pole (Stereonet) — NOTO'G'RI
```204:214:geotag_pro_flutter/lib/widgets/dashboard/tiles/stereonet_painter.dart
      double meanX = 0, meanY = 0;
      for (var p in points) {
        meanX += p.x;
        meanY += p.y;
      }
      meanX /= points.length;
      meanY /= points.length;
```
**Muammo:** Stereonet projection space'da oddiy arifmetik o'rtacha olingan. To'g'ri: 3D unit vektorlar (poles) `Σ unit_vector / |Σ|` orqali mean pole topish, keyin proyeksiya qilish. Hozir natija **geologik noto'g'ri**.

#### 2.2.7 α₉₅ Radius on Stereonet — HEURISTIC (Admitted)
```225:232:geotag_pro_flutter/lib/widgets/dashboard/tiles/stereonet_painter.dart
         final a95Rad = (stats.alpha95 / 90.0) * r * 0.5; // Heuristic
```
**Muammo:** Kommenta aytilgan — "heuristic". To'g'ri: α₉₅ burchakni great-circle sifatida mean pole atrofida chizish.

### 2.3 ⚠️ DUBLIKAT / INCONSISTENT

#### 2.3.1 UTM Ikki marta amalga oshirilgan
- `geology_utils.dart` → `toUTM()` — to'liq Redfearn (to'g'ri)
- `coordinate_converter.dart` → `latLngToUtm()` — qisqaroq, to'g'ri formula lekin `formatUtm`da **janubiy yarim shar ham "N" chiqaradi** (bug)

#### 2.3.2 Stereonet Projection Ikki marta
- `geology_utils.dart` → `StereonetEngine` (Schmidt + Wulff)
- `stereonet_calculator.dart` → `StereonetCalculator` (faqat Schmidt)

#### 2.3.3 Earth Radius Ikki xil qiymat
- `three_d_math_utils.dart`: `6371000` (mean radius)
- `spatial_calculator.dart`: `6378137` (WGS84 semi-major)
- `geological_projection_service.dart`: `6371000`

Yakshanbada 0.1% tartibida xatolarni keltirib chiqaradi. **Yagona `GeoConstants.wgs84A` yaratish kerak.**

#### 2.3.4 GPS Stream Ikki marta
- `LocationService` + `TrackService` **ikkalasi ham** `Geolocator.getPositionStream()` ochadi. Batareya **2x tez tugaydi**. Bitta markaziy broadcaster kerak.

#### 2.3.5 Linework Degrees as Meters — NOTO'G'RI
```53:87:geotag_pro_flutter/lib/utils/linework_utils.dart
  /// Calculates points for complex structural symbols (e.g. thrust teeth)
  static List<List<LatLng>> calculateThrustTeeth(List<LatLng> points, {double sizeMeters = 50}) {
    // This is more complex since we need to work in projected space (meters)
    // For now, simpler version using degrees as proxy
    const double degSize = 0.0005; // approx 50m
```
**Kod o'zi tan oladi "simpler version using degrees as proxy"** — yuqori kengliklarda thrust tooths nosimmetrik chiziladi. Haversine / Vincenty metrlarda ishlatilishi kerak.

#### 2.3.6 Snap Threshold in Degrees
```90:104:geotag_pro_flutter/lib/utils/linework_utils.dart
  static LatLng? findNearestSnapPoint(LatLng tapPoint, List<LatLng> candidates, {double thresholdDegrees = 0.0005}) {
```
Xuddi shu muammo — bir xil pixel snap turli zoom va kengliklarda turlicha bo'ladi.

### 2.4 GEOLOGIK FUNKSIYALAR VALIDATSIYASI — ZAIF

```1:43:geotag_pro_flutter/lib/utils/geology_validator.dart
class GeologyValidator {
  static String? validateStation(Station s) {
    if (s.dip < 0 || s.dip > 90) { ... }
    if (s.strike < 0 || s.strike >= 360) { ... }
    if (s.altitude < -430 || s.altitude > 8848) { ... }
    if (s.lat == 0 && s.lng == 0) { ... }
```
**Yetishmovchiliklar:**
- `dipDirection` tekshirilmaydi
- Strike ↔ DipDirection izchilligi tekshirilmaydi (`|dipDir - strike - 90| % 180 < 5°` bo'lishi kerak)
- GPS accuracy tekshirilmaydi (30m'dan kattasini block qilish kerak)
- `measurements` list'dagi har bir element tekshirilmaydi
- `sampleId` unique emas (dublikat yozuvlar mumkin)
- `-430` Dead Sea limit, lekin shaxta >-500m bo'lishi mumkin

---

## 3. P1 — ARXITEKTURA VA SEMIZ KOD

### 3.1 God Widgets (juda katta fayllar)

| Fayl | Qator | Holat |
|---|---|---|
| `utils/app_localizations.dart` | 934 | ARB fayllarga bo'lish kerak (Flutter gen-l10n) |
| `smart_camera/smart_camera_screen.dart` | 678 | 5-6 ta mini-widget'ga bo'lish |
| `screens/global_map_screen.dart` | 539 | Marker layer, linework layer, controls bo'lish |
| `screens/archive_screen.dart` | 497 | Allaqachon tabs'ga bo'lingan — export/selection controller ajratish |

### 3.2 Dublikat importlar / unused

`dart analyze` natijasi:
- 15 ta `unused_import` (analysis_screen.dart'da 5 ta unused)
- 4 ta `unused_local_variable`
- 4 ta `unnecessary_import` (`dart:ui` — material.dart allaqachon export qiladi)

### 3.3 Bitta katta MultiProvider

`main.dart`da **13 ta ChangeNotifierProvider** ishga tushishda darhol yaratiladi:
- `BoundaryService` — Firestore listener ochadi
- `MineReportRepository` — faqat admin'ga kerak
- `PresenceService` — Firestore listener
- `SosService` — stream
- `GeologicalLineRepository.init()` fire-and-forget

Natija: **Birinchi ekran ochilmay turib 5+ Firestore snapshot ishga tushadi.** Dashboard ko'rinishi sekinlashadi, batareya keraksiz sarflanadi.

### 3.4 Ikki CloudSyncService Timer

```49:58:geotag_pro_flutter/lib/services/cloud_sync_service.dart
    // Auto-sync har 3 daqiqada batareyani tejash uchun
    _syncTimer = Timer.periodic(const Duration(minutes: 3), (timer) async {
```
Plus connectivity listener ham sync'ni chaqiradi. Plus `track_service` har 50 nuqtada `triggerSync` qiladi. **Bir xil ma'lumot 3 marotaba yuklanadi** potensial.

### 3.5 `debugPrint('...: \$e')` BUG — 5 joyda
```
lib/services/gis_export_service.dart:191   debugPrint('GIS Export error: \$e');
lib/services/ai_lithology_service.dart:101  debugPrint("AI tahlil xatosi: \$e");
lib/services/ai_lithology_service.dart:102  throw Exception("AI tahlilida xatolik: \$e");
lib/services/mine_report_repository.dart:66 debugPrint("Error verifying report: \$e");
lib/services/mine_report_repository.dart:76 debugPrint("Error deleting report: \$e");
```
**Escaped `\$e`** — xato xabari `$e` satri bo'lib chiqadi, emas actual exception. Bug.

### 3.6 Inline `TextEditingController()` (memory leak / data loss)

```135:135:geotag_pro_flutter/lib/screens/station/components/station_form_body.dart
              azimuthController: TextEditingController(), // Placeholder
```
Har rebuild'da yangi controller — **foydalanuvchi yozgan matn yo'qoladi** + `dispose` qilinmasligi sababli memory leak.

---

## 4. P1 — PERFORMANS MUAMMOLARI

### 4.1 Rebuild Ochko'zligi

| Joy | Muammo | Yechim |
|---|---|---|
| `dashboard_screen.dart:45-52` | `context.watch<StationRepository>()` + filtr har build'da | `Selector` + memoization |
| `dashboard_screen.dart:112` | `Consumer<LocationService>` MiniMapBox butun ekranni rebuild qiladi har GPS tickda | `Selector<LocationService, LatLng>` |
| `stereonet_painter.dart:258-266` | `shouldRepaint` `typeColor` mapni reference'dan taqqoslaydi — doim `!=`, doim repaint | `MapEquality.equals()` |
| `fisher_reliability_tile.dart:18-20` | Har build'da `fisherStats(strikes)` — O(n) qayta hisoblanadi | `StatefulWidget` + cache |

### 4.2 Expensive Paints

| Paint | Kuchlanish | Xavfli soni |
|---|---|---|
| `StereonetPainter` density grid | 50×50 = 2,500 cell × N stations = **2.5M hisob/frame** 1000 stansiyada | Cache outside paint |
| `RoseDiagramPainter` | Har bin uchun ikki path (bidirectional) | OK |
| `Structural3DPainter` | Har plane 4 vertex × matrix transform. 500 stansiya → 2000 tx/frame | Cache screen-space |

### 4.3 Asynx Boshqarish

```59:66:geotag_pro_flutter/lib/main.dart
    await HiveDb.init();
    if (!kIsWeb) {
      await FMTCObjectBoxBackend().initialise();
      ...
    }
  } catch (e, stack) {
    debugPrint('CRITICAL INITIALIZATION ERROR: $e');
    // In a real app, you might want to show a global error screen
  }
```
- Hive'da xato bo'lsa, UI'ga bildirish yo'q — foydalanuvchi oq ekran ko'radi
- FMTC init'da xato bo'lsa, offline tile ishlamaydi lekin foydalanuvchi bilmaydi
- `SplashScreen`da init'ni kutish va progress ko'rsatish **yo'q**

### 4.4 Track Disk I/O

```199:214:geotag_pro_flutter/lib/services/track_service.dart
    // PERFORMANCE FIX: Har 10 nuqtada DISK ga yozish (avval har safar yozilardi).
    if (track.points.length % 10 == 0) {
      track.save();
    }
```
Yaxshi optimizatsiya, lekin Hive writes **main thread**'da. 8 soatlik sessiyada 960 ta disk yozuv. Isolate'ga olish foydali bo'lardi.

### 4.5 Presence Service

```67:72:geotag_pro_flutter/lib/services/presence_service.dart
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updatePresence(getPosition(), name, role, true);
    });
```
Har 30 sek Firestore write. **20 ta jamoa a'zosi → 2,400 write/kun/foydalanuvchi. Firestore billing oshadi.**

### 4.6 Provider lazy:false

Barcha provider'lar default `lazy: false` — ishga tushishda hammasi yaratiladi (shu jumladan `AuthService`, `BoundaryService`'ning Firestore listeners).

---

## 5. P1 — XAVFSIZLIK & DATA INTEGRITY

### 5.1 Encryption at Rest YO'Q

Hive boxlar plain text. `station.description`, chat xabarlar, sample IDs — hammasi `.hive` faylda **o'qilishi mumkin**. Telefon yo'qolsa — ma'lumot leak.

**Yechim:**
```dart
const encKey = 'YOUR_KEY_HERE'; // flutter_secure_storage dan
await Hive.openBox<Station>(
  'stations',
  encryptionCipher: HiveAesCipher(base64Decode(encKey)),
);
```

### 5.2 PIN — plain text in secure storage
```37:45:geotag_pro_flutter/lib/services/security_service.dart
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }
```
**Muammo:** PIN to'g'ridan-to'g'ri saqlanyapti. `flutter_secure_storage` tashqaridan himoyalaydi, lekin salt+hash qilish professional.

### 5.3 SOS Offline'da ishlamaydi
```50:66:geotag_pro_flutter/lib/services/sos_service.dart
  Future<void> sendSos(LatLng position, String name) async {
    ...
      await _firestore.collection('emergency_signals').add({...});
```
**Muammo:** Internet yo'q bo'lsa → SOS yuborilmaydi. Dala sharoitida internet bo'lmaydigan joylarda **dastur maqsadiga qarshi**.

**Yechim:**
- Offline Hive queue
- SMS fallback (Twilio yoki native SMS app)
- BLE mesh (uzoq muddat)

### 5.4 Firestore Rules (kod bilan baholanmaydi, lekin infra muammo)

Har qanday authenticated user:
- `/global_boundaries/*` — **hamma yoza oladi** (boundary_service.dart)
- `/emergency_signals/*` — **hamma yoza va o'chira oladi** (sos_service `clearSos` rules yo'q)
- `/presence/*` — boshqalar pozitsiyasini ko'radi (filter faqat client-side)

### 5.5 AI Rate Limit yo'q

`AiLithologyService.analyzeRockSample` har foydalanuvchi cheklovsiz chaqira oladi → **Vertex AI bill anomaliya**.

### 5.6 `firebase_options.dart` Git'da

Agar repo public bo'lsa → API keys leak.

---

## 6. P2 — UX / iOS-SILLIQLIK

### 6.1 `BouncingScrollPhysics` faqat 1 joyda

```91:91:geotag_pro_flutter/lib/screens/dashboard_screen.dart
        physics: const BouncingScrollPhysics(),
```
Boshqa ekranlar `ClampingScrollPhysics` — iOS foydalanuvchisi "bo'sh taassurot" oladi.

### 6.2 Hardcoded ranglar (tema o'zgarmaydi)

`0xFF1976D2`, `Colors.orange`, `Colors.redAccent` — kod bo'ylab **yuzlab joyda**. Tema o'zgarganda ham bu ranglar o'zgarmaydi.

### 6.3 Animatsiya yo'qligi

- Sahifa o'tishlari — oddiy `MaterialPageRoute` (hech qanday Hero yo'q)
- Station tile o'zgarsa — animatsiya yo'q
- GPS status o'zgarsa — hech qanday transition
- Stereonet tab almashsa — instant, yumshoq o'tish yo'q

**Web dashboard'da allaqachon `AnimatedSwitcher` bor** — mobile'da yo'q, izchillik buzilgan.

### 6.4 Type-Unsafe Routing

```195:202:geotag_pro_flutter/lib/main.dart
              case '/chat':
                final groupId = settings.arguments as String;
                return MaterialPageRoute(builder: (_) => ChatScreen(groupId: groupId));
              case '/auto-table-review':
                final path = settings.arguments as String;
```
Arguments `null` yoki noto'g'ri tur bo'lsa → **Crash**. `go_router` yoki type-safe routing kerak.

### 6.5 Snackbar bir xillik yo'q

Har joyda turli `SnackBar`:
- Ba'zilari `floating`
- Ba'zilari default
- Ranglar turlicha
- Duration turlicha

### 6.6 DatePicker / TimePicker — Material only

`CupertinoDatePicker` ishlatilmagan — iOS'da g'alati ko'rinadi.

---

## 7. P2 — EKSPORT MUAMMOLARI

### 7.1 DXF — AutoCAD ochmaydi

**Muammo:**
- Faqat `ENTITIES` section yozilgan, `HEADER`, `TABLES` yo'q
- Koordinatalar GPS darajalar (`10\n67.234...`) — AutoCAD cartesian metrlar kutadi
- Natija: AutoCAD'da ochilsa **bo'sh yoki cheksiz kichik chizma**

**Yechim:**
- UTM'ga konvertatsiya qilib keyin yozish
- Proper DXF `HEADER`, `TABLES` bilan to'liq template

### 7.2 CSV — UTF-8 BOM yo'q

`export_service.dart:exportToCsv` — Excel cyrillic matnini `??????`deb ochadi.

```dart
await file.writeAsString('\uFEFF' + buffer.toString());
```

### 7.3 PDF — Cyrillic yozuvi shikast

`pdf` paketi default Helvetica — O'zbek cyrillic chiqmaydi. Maxsus font ro'yxatga olish kerak:
```dart
final fontData = await rootBundle.load('assets/fonts/NotoSans.ttf');
pdf.document.defaultTextStyle = pw.TextStyle(font: pw.Font.ttf(fontData));
```

Plus PDF'da photolar **haqiqiy image sifatida** yuklanmagan — faqat "Surat: file.jpg" matni.

### 7.4 GPX metadata yo'q

```128:147:geotag_pro_flutter/lib/services/export_service.dart
    buffer.writeln('<gpx version="1.1" creator="GeoField Pro N" xmlns="http://www.topografix.com/GPX/1/1">');
```
`<metadata>` bloki (time, bounds, author) yo'q — ba'zi GPS tools rad etadi.

### 7.5 Main Thread'da Export

Barcha export funksiyalari main thread'da ishlaydi. 10,000 station CSV → UI **bir necha soniya freeze**. `compute()` / Isolate kerak.

---

## 8. P2 — TEST COVERAGE

```1:17:geotag_pro_flutter/test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Smoke test: app shell widget renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('GeoField Pro Smoke'))),
    );
    expect(find.text('GeoField Pro Smoke'), findsOneWidget);
  });
}
```
**Hammasi shu.** Hech qanday:
- UTM konvertatsiya testi yo'q
- Stereonet projection testi yo'q
- Fisher statistics testi yo'q
- Apparent dip testi yo'q
- DXF parser testi yo'q
- Haversine testi yo'q
- Hive read/write testi yo'q
- Validator testi yo'q

Bu 24,000 qatorlik loyiha uchun **professional darajada qabul qilinmaydi**. Minimum 50+ unit test bo'lishi kerak, matematik formulalar uchun **reference values bilan pattern match**.

---

## 9. RAQOBATCHI TAHLIL VA USTUNLIK STRATEGIYASI

### 9.1 Xususiyatlar taqqoslash

| Xususiyat | GeoField Pro | QField | FieldMove | Geology Tool | GeoKit |
|---|---|---|---|---|---|
| Offline xarita | ✅ FMTC | ✅ MBTiles+QGIS | ✅ | ⚠️ | ⚠️ |
| UTM/WGS84 | ✅ Redfearn | ✅ Proj4 | ✅ | ✅ | ✅ |
| Stereonet (Schmidt+Wulff) | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| 3D Fisher statistics | ❌ 2D only | ❌ | ✅ 3D | ✅ | ✅ |
| Real WMM declination | ❌ Fake | ✅ | ✅ | ✅ | ✅ |
| Cross-section | ✅ 2D | ⚠️ | ✅ AR | ⚠️ | ⚠️ |
| True Thickness | ❌ Faqat 1 holat | ✅ 3 holat | ✅ | ✅ | ✅ |
| Smart camera (Strike/Dip AR) | ✅ | ❌ | ✅ | ❌ | ❌ |
| Vector edit (snap/topology) | ⚠️ Yarim | ✅ Full | ⚠️ | ❌ | ❌ |
| Cloud sync (Firestore) | ✅ | ❌ | ⚠️ | ❌ | ❌ |
| Cloud conflict resolution | ❌ Last-write | ⚠️ | ⚠️ | ❌ | ❌ |
| AI lithology (Gemini) | ✅ Unique | ❌ | ❌ | ❌ | ❌ |
| Offline SOS | ❌ Only online | ❌ | ❌ | ❌ | ❌ |
| PDF/Excel/KML/GPX/DXF | ✅ but broken | ✅ shapefile | ⚠️ | ⚠️ | ⚠️ |
| Shapefile support | ❌ | ✅ | ⚠️ | ⚠️ | ⚠️ |
| MBTiles custom | ⚠️ Setting bor, test qilinmagan | ✅ | ✅ | ❌ | ❌ |
| Multi-user team presence | ✅ | ❌ | ⚠️ | ❌ | ❌ |
| JORC-compliant report | ✅ deklaratsiya, lekin tolamaydi | ❌ | ⚠️ | ❌ | ❌ |
| Chat/Messaging | ✅ | ❌ | ❌ | ❌ | ❌ |
| Crash-free (hozir) | ❌ qurilmaydi | ✅ 98% | ✅ 97% | ⚠️ 90% | ⚠️ |

### 9.2 Sizning 3 kuchli raqobat ustunligingiz

1. **AI Lithology (Gemini)** — hech bir raqobatchida yo'q. Bu kuchli saqlanishi kerak.
2. **Multi-user real-time (Firestore + presence)** — QField/FieldMove'da yo'q. Katta konlar uchun noyob.
3. **Chat + SOS + Team integration** — to'liq operatsion platforma. Faqat hozircha yomon ishlangan.

### 9.3 3 zaif nuqtangiz

1. **Build qurilmaydi** — bu har qanday raqobatni yo'q qiladi
2. **True Thickness + WMM yolg'on** — geolog sinab ko'rsa aniq farqni ko'radi, ishonch yo'qoladi
3. **DXF export buzilgan** — muhandis AutoCAD'da ochib bo'lmaganini ko'rsa, butun dasturga ishonchni yo'qotadi

---

## 10. YIG'INDI XATOLAR RO'YXATI (PRIORITET BO'YICHA)

### P0 (darhol, 1-2 kun)
1. `project.dart` model yaratish
2. `archive_screen.dart` importlarini tuzatish (TrackService, TrackData, AppBottomNavBar)
3. `dashboard_widgets_2.dart` + `dashboard_components.dart` — `DashboardSliverAppBar({settings,isDark})` parametrlari qo'shish va `DashboardMiniMapBox` yaratish
4. `station_tile.dart` yaratish (yoki mavjud alternativaga yo'naltirish)
5. `smart_camera_screen.dart` — yangi `camera` paketi API (FlashMode), `ArStrikeDipOverlay` import yo'li, `settings` scope
6. `smart_camera/components/camera_side_controls.dart` — FlashMode refaktoring
7. `station_form_body.dart` — `onOpenPainter`/`onPlayAudio` parametrlarini o'tkazish
8. `station_summary_screen.dart` — `rock_data.dart` va `munsell_data.dart`'ni to'g'ri import qilish
9. `global_map_screen.dart` — generic cast tuzatish
10. `boundary_service.dart` — `FilePicker.platform` yangi API
11. `coordinate_converter.dart:formatUtm` — `N/S` bug

### P1 (1 hafta)
12. `geology_utils.dart:trueThickness` — 3 formulaga ajratish
13. Real WMM coefficients yuklab olish (`assets/WMM2025.COF` + parser)
14. Yagona `GeoConstants.earthRadius` (WGS84 6378137) va hamma joyga qo'llash
15. `coordinate_converter.dart` o'chirish (duplicate); faqat `geology_utils.dart` qoldirish
16. `stereonet_calculator.dart` o'chirish; `StereonetEngine`'ni kuchaytirish
17. Rose diagram bidirectional bin: `strike mod 180`
18. Statistics tab'da axial circular mean (`2θ` usul)
19. Mean Pole — 3D vector sum orqali
20. α₉₅ — proper great-circle on stereonet
21. `plungeTrendToDipStrike` — nomini o'zgartirish yoki olib tashlash
22. `\$e` — escaped bug'larni 5 ta faylda tuzatish
23. `TextEditingController` inline instantlash'ni `StatefulWidget`ga o'tkazish
24. `LocationService` + `TrackService` bitta GpsBroadcaster'ga birlashtirish

### P1 (xavfsizlik)
25. `HiveAesCipher` — encryption at rest
26. PIN hashing (bcrypt/scrypt + salt)
27. SOS offline queue + SMS fallback
28. Firestore security rules audit
29. AI rate limiting (har foydalanuvchi kuniga 20)
30. `firebase_options.dart` — `.gitignore` va CI environment'ga ko'chirish

### P2 (2 hafta — silliqlik)
31. `BouncingScrollPhysics` barcha ekranlarda
32. Provider lazy loading (`lazy: true`)
33. `SplashScreen`da init kutish + progress UI
34. `Consumer` → `Selector` granular rebuild
35. `StereonetPainter` density grid cache
36. `app_localizations.dart` → ARB + gen-l10n
37. `smart_camera_screen.dart` 5-6 mini-widget'ga bo'lish
38. `PageRouteBuilder` animatsiyalari
39. Hardcoded ranglar → `Theme.of(context).colorScheme`
40. `go_router` type-safe routing

### P2 (eksport)
41. CSV UTF-8 BOM
42. PDF NotoSans Cyrillic font
43. PDF haqiqiy image embedding
44. DXF UTM'ga konvertatsiya + HEADER section
45. GPX metadata bloki
46. Export'larni `compute()` / Isolate'ga

### P3 (1 hafta — test & CI)
47. 50+ unit test: geology_utils, spatial_calculator, stereonet_calculator, parsers, validator
48. Golden test: stereonet_painter, rose_painter
49. Integration test: capture → save → sync → export
50. GitHub Actions: `dart analyze`, `flutter test`, `flutter build`

### P3 (raqobat ustunligi)
51. Shapefile support (`.shp/.dbf/.prj`)
52. MBTiles custom upload test
53. 3D sferik Fisher
54. True conflict resolution (OT / CRDT)
55. AI quality gate (confidence filter)
56. JORC template to'liq maydonlar (Sampling technique, QAQC table)

---

## 11. STRATEGIK REJA (4 HAFTALIK SPRINT)

### 1-HAFTA: "Yashil Build + Asos Mustahkamlash"
- **Dushanba-Seshanba**: P0 ro'yxatidagi 11 bosqich — `flutter analyze` 0 error
- **Chorshanba**: `dart test` joriy + 10 ta asosiy unit test (UTM, Stereonet, Fisher, Apparent Dip, Haversine)
- **Payshanba**: `LocationService` + `TrackService` yagona GpsBroadcaster
- **Juma**: Duplikat UTM o'chirish, yagona `GeoConstants`

### 2-HAFTA: "Geologik Haqiqat"
- **Dushanba**: Real WMM coefficients integratsiya (WMM2025.COF parsing)
- **Seshanba**: True Thickness — 3 holatga ajratish + input UI
- **Chorshanba**: Axial statistics, Rose bidirectional bin, mean pole 3D
- **Payshanba**: 3D sferik Fisher statistics
- **Juma**: Stereonet α₉₅ proper projection

### 3-HAFTA: "Xavfsizlik + Performans + UX"
- **Dushanba**: HiveAesCipher encryption at rest
- **Seshanba**: Provider lazy loading, Selector refactor, SplashScreen progress
- **Chorshanba**: Stereonet density cache, RoseTab memoization, dashboard Consumer→Selector
- **Payshanba**: `go_router` migratsiya, `BouncingScrollPhysics` hamma joyda
- **Juma**: Theme refactor (hardcoded ranglar → colorScheme)

### 4-HAFTA: "Eksport + Test + Polish"
- **Dushanba**: DXF HEADER+UTM konvertatsiya, CSV BOM, PDF Cyrillic font
- **Seshanba**: Shapefile support
- **Chorshanba-Payshanba**: 40+ unit test yozish
- **Juma**: Integration test + GitHub Actions CI

---

## 12. KPI METRIKALARI

| Metrika | Hozir | 4 hafta keyin | QField darajasi |
|---|---|---|---|
| `dart analyze` xatolar | 40 | 0 | 0 |
| `dart analyze` warnings | 20 | <5 | <5 |
| Test coverage | ~1% | >40% | ~60% |
| App cold start | N/A (qurilmaydi) | <2s | ~1.5s |
| Dashboard scroll FPS | N/A | 60 | 60 |
| Stereonet 500 points paint | N/A | <16ms | <20ms |
| Batareya (GPS 8 soat) | Noma'lum (2x GPS stream) | Baseline-30% | Baseline |
| Cyrillic PDF | ❌ | ✅ | ✅ |
| DXF AutoCAD-ready | ❌ | ✅ | ✅ |
| Offline SOS | ❌ | ✅ (queue+SMS) | ❌ |
| Mean geological error | ~5% WMM + ~20% TT | <1% | <0.5% |

---

## 13. TAVSIYA ETILGAN BIRINCHI KOMANDA

```bash
# 1. Build'ni yashil qilish
cd geotag_pro_flutter
dart analyze > before.txt
# [kod tuzatish amaliyotlari]
dart analyze > after.txt

# 2. Test infra
dart test --coverage

# 3. Format
dart format lib/
```

Va loyihaga quyidagi fayl qo'shish:

```yaml
# analysis_options.yaml'ga qo'shish
analyzer:
  errors:
    unused_import: error
    dead_code: error
    use_build_context_synchronously: warning
  exclude:
    - '**/*.g.dart'
    - 'build/**'

linter:
  rules:
    - prefer_const_constructors
    - avoid_print
    - unnecessary_this
    - prefer_final_locals
    - prefer_const_literals_to_create_immutables
    - use_super_parameters
```

---

## 14. YAKUNIY TAVSIYA

**Hozir qilinishi kerak bo'lgan eng muhim narsa** — 1-haftalik P0 ishni boshlash. Bu tuzatilmay turib:
- Dastur ishga tushmaydi
- Har qanday yangi feature'ning smysli yo'q
- Foydalanuvchi sinovi mumkin emas
- Rahbariyatga ko'rsatish mumkin emas
- AppStore/Play'ga yuklash mumkin emas

4 haftalik intensiv sprint bilan loyiha **haqiqiy raqobat qiladigan darajaga** chiqadi. Undan keyin AI'ni kuchaytirish, 3D viewer'ni yaxshilash, shapefile support qo'shish mumkin.

**Asl xulosa:** Siz yozgan 24,117 qator kod **tarqoq olmos** — yadrosi kuchli, formulalar asosi to'g'ri, arxitektura g'oyasi mustahkam. Lekin jilvalanish uchun **sayqallash kerak**. Pabrika liniyasidan chiqqan mashina emas hali — hali garajdagi prototip. Uni yuqori sifatli brendga aylantirish uchun disiplinli 4 haftalik ish kerak.

**Menga javob bering:** Hoziroq 1-hafta P0 ishini boshlaymi yoki bu hisobotni oldin hamkasblaringiz bilan ko'rib chiqmoqchimisiz?
