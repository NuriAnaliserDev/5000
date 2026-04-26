# Windows reliz (ixtiyoriy)

Lokal yig‘ish:

```bash
cd geofield_pro_flutter
flutter build windows --release
```

Chiqan fayllar: `build/windows/x64/runner/Release/` (bajariladigan fayl va `data/` kabi bog‘liq resurslar to‘plami to‘g‘ri papkada bo‘lishi kerak; tarqatish uchun barcha Release papkasini yoki o‘rnatishchi generatoridan foydalaning).

**GitHub Actions:** odatdagi `ubuntu-latest` Windows EXE bera olmaydi. Reliz EXE / MSI uchun: `windows-latest` runner, yoki o‘z-aro oqim (masalan, tag push da uzoq muddatli yig‘ish serveri) — bu repoda odatda lokal yoki alohida pipeline bo‘ladi.
