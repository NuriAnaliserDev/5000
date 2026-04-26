# Web / Desktop (qisqa smoke)

`PlatformGate` — mobil, veb va desktop UI ajratilgan. O‘zgarishdan keyin (masalan, navigatsiya yoki kamera):

- **Veb (Chrome)**: ilova ochiladi, tizimga kirish (agar kerak), xarita, kamera (ruxsat dialoglari), **Yana** menyu, Admin.
- **Windows / macOS (desktop)**: o‘xshash oqim — xarita, kamera, **Yana**, sozlamalar; oyna o‘lchamini o‘zgartirish (layout buzilmasin).
- **Ipad / katta ekran (ixtiyoriy)**: orientatsiya va keng ekran — bottom bar va suzuvchi tugmalar uchrashmasin.

5–7 daqiqalik tezkor tekshiruv lokal regressiyani kamaytiradi; to‘liq regression turli alohida rejada.

## Holat: reliz / “GeoField Pro” treki (yakunlangan)

Quyidagilar **kod va CI** sifatida bajarib qo‘yilgan: Android/iOS `applicationId` / bundle, Firebase/veb matn muvofiqligi, `key.properties` namunasi, [ANDROID_RELEASE](ANDROID_RELEASE.md), [PLAY_CHECKLIST](PLAY_CHECKLIST.md), [WINDOWS_RELEASE](WINDOWS_RELEASE.md), CI `app-release` AAB, launcher ikonlar, `messages_screen` async lint, manifest. **Firebase prod** qadami (Console da `com.aurum.geofieldpro` ilovasini qo‘shib `google-services.json` / `flutterfire configure`) [ANDROID_RELEASE](ANDROID_RELEASE.md) bo‘yicha sizning konsolingizda.

## Keyingi katta refaktorlar (backlog / alohida sprint; hajm katta)

Bu yerda **hali bajarilishi shart emas** — mahsulot vaqtida alohida PR lar:

- **Global xarita:** `global_map_screen.dart` asosiiy holat hali bitta `StatefulWidget`da (~1.7k qator); yordamchi qatlamlar `map/components/`da. To‘liq `ChangeNotifier` yoki katta parcha — alohida arxitektura loyihasi.
- **L10n soddalashtirish:** ARB + `flutter gen-l10n` allaqachon ishlatiladi; [LOCALIZATION](LOCALIZATION.md) dagidek, `context.loc('kalit')` o‘rniga faqat `GeoFieldStrings` getterlariga o‘tish katta hajmni qamrab oladi — alohida migratsiya rejasida.
