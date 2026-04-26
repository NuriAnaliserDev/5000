# Android reliz (AAB/APK)

**Holat (reliz “qattiqlashtirish” treki):** Gradle `applicationId`, Kotlin paket, `google-services` `package_name`, `web_verification` user-agent, iOS bundle, CI reliz AAB, imzo shabloni va hujjatlar repoda bajarilgan. **Sizning qadmingiz (prod):** Firebase Consoleda `com.aurum.geofieldpro` uchun Android ilova qo‘shilganini tasdiqlang va (kerak bo‘lsa) `google-services.json` + `flutterfire configure` orqali `firebase_options.dart`ni yangi `mobilesdk_app_id` bilan almashtiring.

**Ilova ID:** `com.aurum.geofieldpro` — `android/app/build.gradle.kts` dagi `applicationId` va `android/app/google-services.json` dagi `package_name` bir xil bo‘lishi shart.

## Firebase va `google-services.json`

- Firebase Console → Loyiha sozlamalari → **Android ilova** sifatida aynan `com.aurum.geofieldpro` paketli ilova ro‘yxatdan o‘tgan bo‘lsin. Agar fayl boshqa paketga tegishli bo‘lsa, Firebase ilovasini qo‘shib, yangi `google-services.json` ni yuklab, `android/app/` dagi faylni almashtiring.
- Dart tomonda: `lib/firebase_options.dart` — Android `appId` yangi fayl bilan mos kelishi kerak. Odatda `flutterfire configure` bajariladi.

## Imzo (Play Store)

1. `keytool` bilan keystore (bir marta, parolni xavfsiz saqlang).
2. Ushbu repodagi `android/key.properties.example` bo‘yicha `android/key.properties` yarating; `key.properties` gitda yo‘q.
3. `storeFile` fayl (`upload-keystore.jks`) lokal yoki xavfsiz arxivda saqlansin, repoga kiritilmasin.

**Namuna yaratish (Windows / Git Bash / macOS / Linux):**

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Lokal reliz:

```bash
cd geofield_pro_flutter
flutter build appbundle --release
# yoki tezkor sinov: flutter build apk --release
```

Agar `android/key.properties` bo‘lmasa, **`assembleRelease` / `bundleRelease` buildlari Gradle xatosi bilan to‘xtaydi** — tasodifiy debug-imzoli Play artefakti chiqmasin. Ichki `assembleDebug` ga ta’sir qilmaydi. Play uchun `key.properties` va keystore ni [yuqoridagi](#imzo-play-store) bo‘lim bo‘yicha sozlang.

## R8 / ProGuard

Minifikatsiya yoqilgan. Agar relizda Firestore, Gson yoki refleksiya bo‘yicha g‘alati xatolar chiqsa, `android/app/proguard-rules.pro` ga aniq log bo‘yicha qoidalar qo‘shiladi.

## Sifat va 16 KB sahifa hajmi

- Yangi **Flutter / AGP** ga yangilagach: `flutter build appbundle --release` ni qayta bajarib, **haqiqiy** Android qurilmasida o‘rnatib sinang (Google 16 KB memory page size talablari keyingi NDK/ushbu stack yangilanishlarida muhim bo‘lishi mumkin).
- `targetSdk` va `versionCode` ni Play Console rejangizga muvofiq ushlab boring (`pubspec.yaml` + lokal `flutter build`).

## CI va artefakt

GitHub Actions reliz AAB yig‘ish va `app-release.aab` artefaktini saqlaydi. **Imzoli** do‘konga yuklash uchun: repoda `key.properties` bo‘lmasa artefakt odatda debug imzo (ichki trak) yoki siz o‘rnatgan **GitHub secrets** orqali imzo siyosatiga tayanadi; produksiya odatda lokal yoki alohida imzolash oqimida bajariladi.
