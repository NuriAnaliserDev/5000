/// Bulut funksiyalari — vaqtincha yoki loyiha bosqichiga qarab.
///
/// **Firebase Storage** hozircha o‘chiq (billing / konsolda yoqilmagan yoki keyinroq
/// o‘z server). `false` bo‘lsa stantsiya foto/audio va chat media **Firestore’ga URL
/// siz** sinxronlanadi; yuklash chaqirilmaydi (xato va ortiqcha xarajat yo‘q).
///
/// O‘z serveringiz yoki Firebase Storage tayyor bo‘lganda `true` qiling.
const bool kFirebaseStorageUploadsEnabled = false;
