# Bosqich 5 — ~10k faol foydalanuvchi va barqarorlik

## Firestore

- **SXema:** `users/{uid}/stations/{id}`, `shift_logs`, `chat_groups/.../messages` — [cloud_sync_service.dart](../../lib/services/cloud_sync_service.dart).
- **Indekslar:** murakkab so‘rovlar paydo bo‘lsa, Firebase konsolida composite index; **xatolikda** link beriladi.
- **Pagination:** katta ro‘yxatlar uchun `limit` + `startAfter` (UI ro‘yxatlar kengayganda).
- **Katta hujjat:** `points` massivi marshrutda — hajm o‘sishi mumkin; kerak bo‘lsa subcollection yoki chunking.

## Firebase Storage

- Stansiya foto/audio yo‘llari xizmat ichida; **hajm** va **retention** (eski media) siyosati — keyinchalik.

## Xavfsizlik

- **Firestore / Storage rules:** repoda `docs/` ostida mavjud bo‘lsa tekshiruvlar (`FIREBASE_*`); productionda **hech kim** `users/{boshqaUid}` ga yozmasligi kerak.
- **Rate limiting:** abuse uchun Cloud Functions yoki App Check (loyiha bosqichi).

## Narx

- O‘qish/yozish profillari: har bir stansiya `set` — ~1 yozuv; chat — ko‘payishi mumkin.
- **Monitoring:** Firebase usage alerts.

## Sifat va yuk

- Yondashuv: **realistik** profil (masalan 1k DAU, har biri ~20 stansiya/kun) — avtomatlashtirilgan emas, lekin checklist.
- Client: katta ro‘yxatlarda `ListView.builder`, xarita `select` optimizatsiyasi ([global_map_screen_state.dart](../../lib/screens/global_map_screen.dart) izohlari).

## Runbook (qisqa)

| Voqea | Harakat |
|-------|-----------|
| Firebase o‘chiq | Mahalliy ish; `SecurityWrapper` / banner ([geo_field_pro_app.dart](../../lib/app/geo_field_pro_app.dart)) |
| Sinxron ilib qolgan | Connectivity, `triggerSync`, log |
| Firestore quota | Indeks/savolni optimallashtirish, pagination |
