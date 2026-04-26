# emergency_signals (Firestore) — qisqa eslatma

Ilova `SosService` orqali `emergency_signals` hujjatlariga `isActive: false` qilishi uchun **foydalanuvchi o‘z hujjatini yangilay olishi** kerak.

Misol qoida g‘oya (loyiha shartlariga moslab yozing):

- `create`: faqat autentifikatsiyalangan foydalanuvchi, `request.auth.uid` maydoni bilan bir xil.
- `update` / `delete`: yuboruvchi o‘z `senderUid` maydoni bilan mos keladigan hujjatlargagina ruxsat.

Agar `cancelMyActiveSos` tarmoqqa muvaffaq, lekin xarita yangilanishini sezmasangiz, Firestore
Security Rules yoki tarmoq xatosini `debugPrint` orqali tekshiring.

**Desktop / Web:** pastki `AppBottomNavBar` faqat mobil ekranlarda; `PlatformGate` orqali web/desktop alohida UI.
