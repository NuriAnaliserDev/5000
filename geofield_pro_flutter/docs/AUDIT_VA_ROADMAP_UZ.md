# GeoField Pro — texnik audit va yo‘l xaritasi (2026)

Bu hujjat loyiha holati, aniqlangan mavjudlar va keyingi ishlar tartibini beradi.

## 1. Hozirgi holat (tekshiruv natijalari)

| Tekshiruv | Natija |
|-----------|--------|
| `flutter analyze` | Xato yo‘q |
| `flutter test` | Barcha testlar (67) o‘tdi |
| `flutter build apk --debug` | Muvaffaqiyatli (`app-debug.apk`) |
| `flutter doctor` | Android/Web OK; Windows desktop uchun Visual Studio o‘rnatilmagan |

## 2. Aniqlangan savollar (muammo emas, lekin e’tibor)

1. **Paketlar**: `flutter pub upgrade` chegaralar ichida bajarildi; major versiyalar `pub outdated` bo‘yicha alohida PR.
2. **Firebase**: mobil ham web kabi Firebase yo‘q bo‘lsa **mahalliy rejim** (banner + himoyalangan servislar).
3. **FMTC**: 2 marta urinish; baribir xato bo‘lsa ogohlantirish.
4. **Android fon GPS**: manifestdan `ACCESS_BACKGROUND_LOCATION` olib tashlangan — Play uchun soddaroq; kuchaytirilgan fon kuzatuv keyinroq alohida e’lon bilan qayta qo‘shilishi mumkin.
5. **CI**: `../../.github/workflows/flutter_ci.yml` — `geofield_pro_flutter` papkasi.
6. **Integratsiya testlari**: hali yo‘q — qurilmada qo‘lda sinov tavsiya etiladi.

## 3. Yo‘l xaritasi

### Bosqich A — barqarorlik (1–3 kun)
- [x] GitHub Actions: `flutter pub get`, `analyze`, `test` (workflow qo‘shilgan).
- [ ] `flutter build apk --release` va asosiy foydalanish oqimlari (login, xarita, kamera, arxiv).
- [ ] Play Console uchun fon joylashuvi uchun maxfiylik matni / ekran suratlari.

### Bosqich B — sifat (1–2 hafta)
- [ ] Muhim paketlarni bosqichma-bosqich yangilash (camera 0.12, geolocator 14, va hokazo) + regresiya.
- [ ] `integration_test`: splash → dashboard → xarita → kamera.
- [ ] `geo_field_string_lookup` generatsiya skriptini `flutter gen-l10n` bilan sinxronlash jarayoni (CONTRIBUTING).

### Bosqich C — mahsulot
- [ ] Windows desktop build (Visual Studio + `flutter build windows`) agar kerak bo‘lsa.
- [ ] Monitoring: Crashlytics / xato hisoboti (ixtiyoriy).

## 4. Mahalliy o‘rnatish va tekshiruv

```bash
cd geofield_pro_flutter
flutter pub get
flutter analyze
flutter test
# Qurilmada:
flutter install
# yoki
flutter build apk --debug
```

Yoki: `bash tool/verify.sh` (analyze + test).

## 5. Bartaraf etilgan yaxshilanishlar (shu commit bilan)

- **Firebase yo‘q**: splash, Auth, CloudSync, SOS, presence, chat, chegara, xarita repolar, xabarlar oqimi, `UserFlags`, SOS navbati — `isFirebaseCoreReady` / `firestoreOrNull` bilan xavfsiz.
- **Banner**: `firebase_local_only_banner` (uz/en/tr) + `Provider<FirebaseBootstrapState>`.
- **FMTC**: ikki marta ishga tushirish urinishi.
- **Android**: `ACCESS_BACKGROUND_LOCATION` olib tashlangan (Play soddalashtirish).
- **Paketlar**: `flutter pub upgrade` (patch/minor).
- Kamera AR: `horizon_level` lokalizatsiyasi; `tool/verify.sh`.
