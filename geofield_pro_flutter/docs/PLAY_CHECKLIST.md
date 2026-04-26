# Google Play: qisqa tayyorlik ro‘yxati

Do‘konda nazorat yoki tavsif matnlarida quyidagilarni yoritishni unutmang (so‘zlar in-app siyosat yoki tavsif bo‘yicha sozlang).

## Ruxsatlar

- **Joylashuv (aniq / taxminan):** dala o‘lchovlari, xarita, trassirovka. **Orqa fon** joylashuvi fonda ishlaydigan treking uchun: Play siyosatiga muvofiq tushuntiring (batareya, qachon fonda ishlaydi).
- **Kamera / galereya:** stansiya fotosi, hujjatlarni rasmga olish, OCR loyihada ishlatilsa, shu kontekstni bering.
- **Mikrofon / audio** (agar ekran yoki tahlil ishlatilsa): qayerda yoki nima maqsadda yozuv qilinishi.
- **Bildirishnomalar** (API 33+): foydali, lekin haddan tashqari yubormaslik.
- **Biometrik / PIN:** faqat foydalanuvchi qulayligi yoki lokal shifrlash, serverga barmoq izi yuborilmaydi (agar shunday bo‘lsa, ayting).

## Ofis tavsif va kontent siyosati

- Ilova nomi va brend: **GeoField Pro** (yoki sizdagi yuridik matn) bilan dastur ichidagi nom mos bo‘lsin.
- Tashqi `feature graphic` / skrinshotlar: Play Material dizayn rejasiga muvofiq, **logo** muhim elementlari (mask cheti) chetda qirqilmasin. Do‘konda katta yorliq/markaz simvol uchun **1024×1024+** (kvadrat) manbaga ega bo‘lgan alohida asset tavsiya etiladi; `flutter_launcher_icons` hozirgi `assets/logo.png` dan parcha/adapter yaratadi (hozirgi fayl odatda 669×373 o‘lchamda — ikon muhitida yaxshilab tekshirib oling).

## Texnik

- [ANDROID_RELEASE.md](ANDROID_RELEASE.md) — AAB, imzo, 16 KB sinovi.
