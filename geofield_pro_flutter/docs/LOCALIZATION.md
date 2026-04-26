# Lokalizatsiya (yagona manba strategiyasi)

- **ARB** qat’iy manba: `lib/l10n/app_en.arb`, `app_tr.arb`, `app_uz.arb` — yangi qatorlar avval shu yerga qo‘shiladi.
- **Sinov:** `python tool/verify_l10n_arb_keys.py` — uchta ARBda bir xil kalitlar borligini tekshiradi (CIda `Generate l10n` dan keyin ishga tushadi).
- **Codegen:** `flutter gen-l10n` (`l10n.yaml` → `GeoFieldStrings`), CI kiritilgan.
- **Eslatma:** `app_strings.dart` / `app_strings_*.dart` hozircha import zanjiri uchun ishlatilmoqda; to‘liq ARB + codegen ga o‘tish alohida migratsiya (barcha importlarni yangilash).
- **Holat (2026):** Asosiy matn manbai ARB; `loc` / [geo_field_string_lookup.dart](../lib/utils/geo_field_string_lookup.dart) dinamik kalit orqali ishlaydi. **Keyingi bosqich** — barcha chaqiriqlarni to‘g‘ridan-to‘g‘ri `GeoFieldStrings` getterlariga olib kelish; bu [QA_PLATFORMS](QA_PLATFORMS.md) dagi alohida backlog elementi, reliz “qattiqlashtirish”dan mustaqil.
