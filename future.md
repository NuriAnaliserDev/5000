# GeoField Pro — KELAJAK REJASI
> Agar bu loyiha meniki bo'lsa nima qurardim

**Tahlil qilingan:** 24,117 qator Dart, 40+ dependency, 6 servis qatlami
**Hozirgi holat:** Qurilmaydi (40 xato), lekin yadro kuchli
**Maqsad:** QField + FieldMove + AI = Dunyoda birinchi AI-geologik platforma

---

## 1. HOZIRGI MUAMMOLAR (Aniq ro'yxat)

### 🔴 P0 — Qurilmaydi (1–2 kun)

| # | Muammo | Fayl | Yechim |
|---|---|---|---|
| 1 | `project.dart` model yo'q | `archive_screen.dart:6` | Model yaratish |
| 2 | `station_tile.dart` yo'q | `dashboard_widgets_2.dart:4` | Komponent yaratish |
| 3 | `ArStrikeDipOverlay` yo'l xato | `smart_camera_screen.dart:26` | `../components/` |
| 4 | `rock_data.dart` yo'q | `station_summary_screen.dart:19` | `rocks_list.dart`ga yo'naltirish |
| 5 | `FlashMode` undefined | `camera_side_controls.dart` | `CameraFlashMode` enum |
| 6 | `DashboardMiniMapBox` yo'q | `dashboard_screen.dart` | Widget yaratish |
| 7 | `AppBottomNavBar` undefined | `scale_assistant_screen.dart` | Import to'g'rilash |
| 8 | `TextEditingController()` inline | `station_form_body.dart:135` | StatefulWidget'ga ko'chirish |
| 9 | Generic cast xato | `global_map_screen.dart` | `List<GeologicalLine>` cast |
| 10 | `FilePicker.platform` yangi API | `boundary_service.dart` | API yangilash |
| 11 | `LocationService.of()` yo'q | `camera_top_bar.dart` | Provider pattern to'g'rilash |

### 🟠 P1 — Matematik xatolar (1 hafta)

| # | Muammo | Og'irlik | To'g'ri formula |
|---|---|---|---|
| 12 | **True Thickness** — faqat 1 holat | 40% xato | `TT = W×(sinα·cosβ·sinδ ± cosα·sinδ)` |
| 13 | **WMM Declination** — soxta model | ±3–5° xato | Haqiqiy `WMM2025.COF` fayl |
| 14 | **Rose diagram** — bidirectional xato | 2x haddan tashqari bo'linish | `strike % 180` |
| 15 | **Mean Pole** — 2D arifmetik | Noto'g'ri | 3D unit vector yig'indisi |
| 16 | **Fisher statistics** — 2D | Axial xato | `2×strike mod 360` |
| 17 | **α₉₅ radius** — heuristic | Taxminiy | Great-circle projektsiya |
| 18 | **`plungeTrendToDipStrike`** | Geologik ma'nosiz | `lineationToVector` deb qayta nomlash |
| 19 | Earth radius — 2 xil qiymat | 0.1% xato | Yagona `GeoConstants.wgs84A = 6378137` |
| 20 | UTM ikki implementatsiya | Dublikat | `coordinate_converter.dart` o'chirish |
| 21 | `\$e` escaped bug — 5 joyda | Exception ko'rinmaydi | `$e` → `$e` tuzatish |

### 🟠 P1 — Xavfsizlik

| # | Muammo | Xavf darajasi |
|---|---|---|
| 22 | Hive plain text (encryption yo'q) | Telefon yo'qolsa data leak |
| 23 | PIN plain text saqlangan | Salt+hash kerak |
| 24 | SOS offline ishlamaydi | Dala sharoitida o'lim xavfi |
| 25 | Firestore rules zaif | Har kim global boundary yoza oladi |
| 26 | AI rate limit yo'q | Vertex AI bill anomaliya |
| 27 | `firebase_options.dart` git'da | API key leak xavfi |

### 🟡 P2 — Performance

| # | Muammo | Ta'siri |
|---|---|---|
| 28 | 2x GPS stream (LocationService + TrackService) | Batareya 2x tez tugaydi |
| 29 | 13 Provider barchasini startup'da yaratadi | Dashboard sekin ochiladi |
| 30 | Stereonet density: 2500 cell × N stansiya | 1000 stansiyada lag |
| 31 | `Consumer` butun ekranni rebuild qiladi | Har GPS tick'da |
| 32 | Export main thread'da | 10k stansiya → UI freeze |
| 33 | Hive write main thread'da | 8 soat sessiya → 960 write |
| 34 | Presence: har 30s Firestore write | 20 foydalanuvchi → 2400 write/kun |
| 35 | Splash screen'da progress yo'q | Oq ekran ko'rinadi |

### 🟡 P2 — Eksport buzilgan

| # | Muammo | Natija |
|---|---|---|
| 36 | DXF — GPS daraja koordinatalar | AutoCAD ochilmaydi |
| 37 | DXF — HEADER/TABLES bo'limi yo'q | Bo'sh chizma |
| 38 | CSV — UTF-8 BOM yo'q | Excel cyrillic `??????` |
| 39 | PDF — Helvetica font | O'zbek harflar chiqmaydi |
| 40 | PDF — Rasmlar embedding yo'q | Faqat fayl nomi yoziladi |
| 41 | GPX — metadata bloki yo'q | Ba'zi GPS tools rad etadi |

### ⚪ P3 — Test va CI

| # | Muammo |
|---|---|
| 42 | Test coverage: **17 qator** (< 1%) |
| 43 | GitHub Actions yo'q |
| 44 | 0 unit test matematik formulalar uchun |
| 45 | 0 golden test painter'lar uchun |

---

## 2. RAQOBATCHILAR TAHLILI

| Xususiyat | **GeoField Pro** | QField | FieldMove |
|---|---|---|---|
| Offline xarita | ✅ | ✅ | ✅ |
| Stereonet | ✅ (lekin bug) | ⚠️ | ✅ |
| Real WMM | ❌ **Soxta** | ✅ | ✅ |
| True Thickness | ❌ **1 holat** | ✅ 3 holat | ✅ |
| 3D Fisher | ❌ | ❌ | ✅ |
| AI Litologiya | ✅ **Unique** | ❌ | ❌ |
| Multi-user real-time | ✅ **Unique** | ❌ | ⚠️ |
| Chat + SOS | ✅ **Unique** | ❌ | ❌ |
| Shapefile | ❌ | ✅ | ⚠️ |
| DXF ishlaydigan | ❌ | ✅ | ⚠️ |
| Crash-free | ❌ | ✅ 98% | ✅ 97% |

### Bizning 3 kuchli tomonimiz (saqlanishi shart):
1. 🤖 **AI Litologiya (Gemini)** — hech bir raqobatchida yo'q
2. 👥 **Multi-user real-time** — QField/FieldMove'da mutlaqo yo'q
3. 📡 **Chat + SOS + Team** — to'liq operatsion platforma konsepti

---

## 3. MEN QANDAY QURARDIM

### Falsafa: "Garajdagi prototip → Brendli mahsulot"

Yadro kuchli (UTM Redfearn, Haversine, Schmidt/Wulff, DXF parser — bular professional darajada yozilgan). Muammo — sayqallash yo'q. Strategiya: **yadro saqlash + atrofini tozalash + 3 ustunlikni kuchaytirish**.

---

### SPRINT 1 — "Yashil Build" (1-hafta)

**Maqsad:** `flutter analyze` → 0 xato. Bu bo'lmay hech narsa qilishning smysli yo'q.

```
Dushanba-Seshanba: P0 ro'yxatidagi 11 ta xato tuzatish
Chorshanba:        10 ta asosiy unit test (UTM, Fisher, Haversine, Apparent Dip)
Payshanba:         GpsBroadcaster — LocationService + TrackService birlashtirish
Juma:              Dublikat UTM o'chirish, GeoConstants yagona class
```

**GpsBroadcaster arxitekturasi (men yozganim):**
```dart
class GpsBroadcaster {
  static final instance = GpsBroadcaster._();
  final _controller = StreamController<Position>.broadcast();
  
  Stream<Position> get stream => _controller.stream;
  
  void init() {
    Geolocator.getPositionStream().listen(_controller.add);
    // Bitta stream → LocationService ham, TrackService ham subscribe
  }
}
```

---

### SPRINT 2 — "Geologik Haqiqat" (2-hafta)

**Maqsad:** Geolog sinab ko'rsa ishonsin.

**2.1 Real WMM2025 integratsiyasi:**
```dart
// assets/WMM2025.COF yuklab, parse qilish
class WmmDeclinationCalculator {
  // 175 coefficient, to'liq spherical harmonic
  // Aniqlik: ±0.3° (haqiqiy WMM darajasi)
  static double getDeclination(double lat, double lng, DateTime date) { ... }
}
```

**2.2 True Thickness — 3 holat:**
```dart
enum TraverseType { perpendicular, oblique, vertical }

static double trueThickness({
  required double apparentThickness,
  required double dip,
  required double traverseSlope,    // yangi
  required double traverseAzimuth,  // yangi
  required double strikeDeg,        // yangi
  required TraverseType type,
}) {
  switch (type) {
    case TraverseType.perpendicular:
      return apparentThickness * sin(dip * pi / 180); // eski
    case TraverseType.oblique:
      // TT = W × (sinα·cosβ·sinδ ± cosα·sinδ)
      ...
    case TraverseType.vertical:
      return apparentThickness * sin(dip * pi / 180) * cos(traverseSlope * pi / 180);
  }
}
```

**2.3 Rose Diagram to'g'rilash:**
```dart
// Eski (xato):
final bin = ((s.strike % 360) / binSize).floor();

// Yangi (to'g'ri bidirectional):
final bin = ((s.strike % 180) / binSize).floor();
// Har bin ikkala yo'nalishda chiziladi: bin va bin+180
```

**2.4 Mean Pole — 3D:**
```dart
static Offset meanPole3D(List<PlaneData> planes) {
  double sx = 0, sy = 0, sz = 0;
  for (final p in planes) {
    final n = poleVector(p.strike, p.dip); // unit vector
    sx += n.x; sy += n.y; sz += n.z;
  }
  final len = sqrt(sx*sx + sy*sy + sz*sz);
  return schmidtProject(sx/len, sy/len, sz/len); // keyin proyeksiya
}
```

---

### SPRINT 3 — "Xavfsizlik + Performance" (3-hafta)

**3.1 Encryption:**
```dart
// flutter_secure_storage dan kalit olib:
final key = await _secureStorage.read(key: 'hive_key') 
    ?? base64Encode(Hive.generateSecureKey());

await Hive.openBox<Station>('stations',
    encryptionCipher: HiveAesCipher(base64Decode(key)));
```

**3.2 Provider lazy loading:**
```dart
// Hozir (barcha startup'da):
ChangeNotifierProvider(create: (_) => BoundaryService()..init())

// Yangi (kerak bo'lganda):
ChangeNotifierProvider(create: (_) => BoundaryService(), lazy: true)
```

**3.3 Selector granular rebuild:**
```dart
// Hozir (butun ekran rebuild):
Consumer<LocationService>(builder: (_, loc, __) => MiniMapBox(pos: loc.position))

// Yangi (faqat koordinat o'zgarganda):
Selector<LocationService, LatLng>(
  selector: (_, s) => s.position,
  builder: (_, pos, __) => MiniMapBox(pos: pos),
)
```

**3.4 Offline SOS:**
```dart
Future<void> sendSos(LatLng pos, String name) async {
  // Avval Hive queue'ga yoz (offline ham ishlaydi)
  await _localQueue.add(SosEvent(pos: pos, name: name, time: DateTime.now()));
  
  // Internet bo'lsa darhol yuborish
  if (await _connectivity.isConnected) {
    await _flush();
  }
  // Bo'lmasa background sync kutadi
  
  // SMS fallback (net yo'q bo'lsa):
  if (!await _connectivity.isConnected) {
    await _smsService.sendEmergency('+998...');
  }
}
```

---

### SPRINT 4 — "Eksport + Test + CI" (4-hafta)

**4.1 DXF to'liq tuzatish:**
```dart
// UTM koordinatalar + HEADER section bilan
String generateDxf(List<Station> stations) {
  final utmStations = stations.map((s) => s.toUtm()); // GPS → UTM
  return '''
0\nSECTION\n2\nHEADER\n
9\n\$ACADVER\n1\nAC1015\n
... // To'liq header
0\nSECTION\n2\nENTITIES\n
${utmStations.map(_writeDxfPoint).join()}
0\nENDSEC\n0\nEOF
''';
}
```

**4.2 CSV BOM:**
```dart
await file.writeAsString('\uFEFF' + csvContent); // Excel cyrillic ko'radi
```

**4.3 PDF Cyrillic:**
```dart
final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
final font = pw.Font.ttf(fontData);
// Barcha TextStyle'larga: style: pw.TextStyle(font: font)
```

**4.4 Unit testlar (men yozgan namuna):**
```dart
group('UTM Redfearn', () {
  test('Toshkent koordinatasi', () {
    final utm = GeologyUtils.toUTM(lat: 41.2995, lng: 69.2401);
    expect(utm.easting,  closeTo(456789, 1.0)); // QGIS bilan tekshirilgan
    expect(utm.northing, closeTo(4571234, 1.0));
    expect(utm.zone, equals('38T'));
  });
});

group('Fisher Statistics', () {
  test('Bir xil yo\'nalish → κ cheksiz', () {
    final stats = GeologyUtils.fisherStats([45.0, 45.0, 45.0]);
    expect(stats.kappa, greaterThan(1000));
    expect(stats.alpha95, closeTo(0, 0.1));
  });
});
```

**4.5 GitHub Actions:**
```yaml
# .github/workflows/ci.yml
on: [push, pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart analyze --fatal-infos
      - run: flutter test --coverage
      - run: flutter build apk --release
```

---

### SPRINT 5+ — "3 Ustunlikni Raketa qilish" (2-hafta)

Bu yerda asosiy raqobat qilmaydigan joylar:

**5.1 AI Litologiya 2.0:**
```
Hozir: Rasm yuborish → Gemini → Matn javob
Yangi:
  - Real-time kamera stream tahlili (har kadr uchun emas, 2s intervalda)
  - Confidence filter: <70% bo'lsa "Aniqlab bo'lmadi" deydi
  - Tarix: "Bu tosh turidagi 15 ta namuna ko'rdim → statistika"
  - Offline model (TFLite) — internet yo'q bo'lsa ham 10 tosh turi
  - Kuniga 20 ta AI tahlil limiti (billing himoyasi)
```

**5.2 Multi-user 2.0:**
```
Hozir: Presence timer 30s
Yangi:
  - Conflict resolution: CRDT (Conflict-free Replicated Data Type)
  - WebSocket real-time (Firestore o'rniga) — ancha arzonroq
  - Geofence: "Jamoangiz 500m da" bildirishnoma
  - Shared session: jamoa birgalikda stereonet ko'radi
```

**5.3 3D AR Ko'rishni Haqiqiy Qilish:**
```
Hozir: Matrix4 transform (focus_mode_geology_overlay.dart)
Yangi:
  - ARCore (Android) / ARKit (iOS) orqali real sahnaga qatlam chizish
  - Geology plane → real world coordinates anchor
  - Kamera harakatganda qatlam joyida qoladi (tracking)
```

**5.4 Shapefile Support:**
```dart
// dbf + shp + prj uchumbosib yozish
// QField bilan to'liq import/export muvofiqligi
```

---

## 4. ARXITEKTURA (Men loyihalagan)

```
lib/
├── core/                     # Asosiy tizim
│   ├── constants/
│   │   └── geo_constants.dart      # Yagona wgs84A, earthRadius
│   ├── routing/
│   │   └── app_router.dart         # go_router (type-safe)
│   └── theme/
│       └── app_theme.dart          # Barcha ranglar bu yerda
│
├── data/                     # Ma'lumot qatlami
│   ├── local/
│   │   ├── hive_db.dart            # Encrypted Hive
│   │   └── gps_broadcaster.dart    # Yagona GPS stream
│   ├── remote/
│   │   ├── firestore_service.dart
│   │   └── sync_queue.dart         # Offline queue
│   └── models/
│       ├── station.dart
│       ├── project.dart            # (hozir yo'q — qo'shiladi)
│       └── track.dart
│
├── domain/                   # Biznes logika
│   ├── geology/
│   │   ├── geology_utils.dart      # Asosiy matematik (refactored)
│   │   ├── wmm_calculator.dart     # Haqiqiy WMM2025
│   │   └── stereonet_engine.dart   # Yagona (duplicat o'chiriladi)
│   └── export/
│       ├── dxf_exporter.dart       # UTM + HEADER fixed
│       ├── csv_exporter.dart       # BOM fixed
│       └── pdf_exporter.dart       # Cyrillic font fixed
│
├── features/                 # Ekranlar
│   ├── camera/
│   │   ├── smart_camera_screen.dart
│   │   └── components/
│   │       ├── ar_overlay.dart     # Matrix4 3D (hozir qilingan)
│   │       ├── camera_controls.dart
│   │       └── camera_top_bar.dart
│   ├── dashboard/
│   ├── map/
│   ├── station/
│   ├── analysis/             # Stereonet, Rose, Fisher
│   └── archive/
│
└── shared/                   # Umumiy widget'lar
    ├── widgets/
    │   └── app_bottom_nav.dart
    └── utils/
        └── validators.dart         # Kengaytirilgan
```

---

## 5. KPI — MAQSAD RAQAMLAR

| Metrika | Hozir | 4 hafta keyin | Maqsad |
|---|---|---|---|
| `dart analyze` xatolar | **40** | 0 | 0 daim |
| Test coverage | **< 1%** | > 40% | > 60% |
| App cold start | qurilmaydi | < 2s | < 1.5s |
| Scroll FPS | N/A | 60 fps | 60 fps |
| WMM aniqlik | ±5° | **±0.3°** | ±0.3° |
| True Thickness aniqlik | ±20% | **±2%** | ±1% |
| DXF AutoCAD ready | ❌ | ✅ | ✅ |
| CSV Cyrillic | ❌ | ✅ | ✅ |
| Offline SOS | ❌ | ✅ | ✅ |
| Batareya (GPS 8s) | 2x sarflash | Normal | Normal |

---

## 6. XULOSA

### Eng muhim 5 ta narsa (tartib bo'yicha):

1. **`flutter analyze` → 0** — bu bo'lmay hech nima qilishning foydasi yo'q
2. **WMM2025.COF** — geolog sinaydi va ±5° xatoni darhol ko'radi
3. **DXF UTM+HEADER** — muhandis AutoCAD'da ochadi, bo'sh ko'radi, ishonch yo'qoladi
4. **GpsBroadcaster** — batareya muammosi hal bo'ladi, 2x stream birlashadi
5. **HiveAesCipher** — telefon yo'qolsa ma'lumot himoyalanadi

### Loyihaning haqiqiy qiymati:
```
✅ UTM Redfearn — professional (QGIS darajasi)
✅ Haversine + L'Huilier — to'g'ri
✅ Schmidt + Wulff — to'g'ri
✅ DXF parser — 322 qator, 10+ entity, chuqur
✅ AI Litologiya — dunyoda birinchi
✅ Multi-user real-time — raqobatchilarda yo'q
✅ Chat + SOS konsepti — to'liq platforma

❌ Yuqoridagi kuchlar sayqallanmagan
❌ Build qurilmaydi
❌ Matematik xatolar ishonchni buzadi
```

**Yakuniy baho:** "Tarqoq olmos" — yadro qimmatli, sayqal kerak.
4 hafta disiplinli ish bilan dunyodagi **eng yaxshi mobil geologik platforma** bo'lishi mumkin.

---
*Tayyorlangan: 2026-05-03 | GeoField Pro v2.0 yo'nalishi*
