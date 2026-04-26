# Ilova ishga tushirish siyosati (Bootstrap)

Barcha mantiqi `lib/app/app_bootstrap.dart` faylida: `runAppBootstrap()`.

## Ketma-ketlik

1. `WidgetsFlutterBinding.ensureInitialized()` — muvaffaqiyatsiz bo‘lsa, foydalanuvchiga [ErrorScreen](lib/screens/error_screen.dart) (qayta urinish).
2. **Firebase** `Firebase.initializeApp` — muvaffaqiyatsiz bo‘lsa:
   - **Web** (`kIsWeb`): dastur davom etadi (dalada faqat oflayn rejim mumkin; Firebase funksiyalari boshqacha yomonlashadi).
   - **iOS / Android / desktop**: muvaffaqiyatsizlik **fatal** — ErrorScreen (Auth/Cloudsiz to‘g‘ri ishlash qiyin).
3. **Hive** `HiveDb.init()` — **har doim** majburiy muvaffaqiyat. Muvaffaqiyatsiz bo‘lsa, ErrorScreen. Bu dala stantsiyalari va sozlamalar shifrlangan mahalliy saqlanishining asosidir.
4. **FMTC** (oflayn xarita keshi) — faqat `!kIsWeb`. Xato bo‘lsa:
   - **Fatal emas** — dastur ochiladi, logda `WARN` qoldiriladi; xarita keshi cheklanishi yoki tarmoqka ko‘p tayanishi mumkin.

## UI oqimi

- `lib/main.dart` faqat `runApp(const AppBootstrapShell())` chaqiradi.
- [app_bootstrap_shell.dart](lib/app/app_bootstrap_shell.dart) `runAppBootstrap` natijasini kutiladi, muvaffaqiyatda `MultiProvider` + [GeoFieldProApp](lib/app/geo_field_pro_app.dart) beriladi; xato matni debug rejimda stack qo‘shilishi mumkin.

## Reliz / identifikator (texnik yordam)

Android paket, imzo, Play tayyorligi: [ANDROID_RELEASE](ANDROID_RELEASE.md) va [PLAY_CHECKLIST](PLAY_CHECKLIST.md). Firebase `google-services.json` loyihada `com.aurum.geofieldpro` ga mos tursin — tafsilotlar shu hujjatlarda.

## Firebase fayllari (maxfiylik)

Quyidagilar `.gitignore` ro‘yxatida va repoda **kuzatilmasligi** ma’qul: `lib/firebase_options.dart`, `android/app/google-services.json`, iOS bo‘lsa `ios/Runner/GoogleService-Info.plist`. Yangi ishchi nusxa: `cd geofield_pro_flutter` dan keyin [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) bilan `flutterfire configure` (Firebase loyihasiga kirish kerak); sozlangan fayllar mahalliy diskda qoladi.
