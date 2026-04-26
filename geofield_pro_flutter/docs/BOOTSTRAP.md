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

## Firebase fayllari

`lib/firebase_options.dart` va `android/app/google-services.json` repoda kuzatiladi (**GitHub Actions** analyze/test/build uchun). API kalitlarini Firebase konsolda ilova cheklovlari bilan toraytiring. iOS: `GoogleService-Info.plist` odatda `.gitignore` da, mahalliy `flutterfire configure`.

## Firebase qoidalarni chiqarish

Firestore qoidalari CLI orqali chiqariladi: `cd geofield_pro_flutter && npx firebase-tools deploy --only firestore:rules` (loyiha: `geofield-pro-8529f`, `.firebaserc`). **Storage** qoidalari uchun avvalo [Firebase Console → Storage](https://console.firebase.google.com/project/geofield-pro-8529f/storage) da «Get Started» bilan bucket yoqing, so‘ng `deploy --only storage`.

## GitHub Actions (reliz AAB)

`build-appbundle` ish oqimi: repoda `ANDROID_KEYSTORE_BASE64` (keystore faylining base64), `ANDROID_KEYSTORE_STORE_PASSWORD`, `ANDROID_KEYSTORE_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` **repository secrets** bo‘lsa — `flutter build appbundle --release` va AAB artefakt. Secrets bo‘lmasa — `flutter build apk --debug` va `app-debug-ci` artefakt (mahalliy Play reliz uchun `android/key.properties` va `docs/ANDROID_RELEASE.md`).
