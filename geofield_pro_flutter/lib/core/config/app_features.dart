/// GeoField Pro **freeze protocol** — bitta manbaga qarab feature yoqiladi/o‘chadi.
///
/// O‘zgartirishdan oldin: `docs/FREEZE_PROTOCOL.md` va dependency checklist.
/// Istalgan `if (something)` o‘rniga bu yerdagi konstantalardan foydalaning.
abstract final class AppFeatures {
  /// ARCore/ARKit geologik qatlam. v0.1-alpha: muzlatilgan (oddiy kamera barqarorligi).
  static const bool enableAR = false;

  /// Gemini / Vertex real backend. `false` → har doim mock client (FREEZE: advanced AI engine).
  static const bool enableAI = false;

  /// Fonlarda sinxron: connectivity listener, periodik queue, [SyncProcessor.run].
  /// `false` → mahalliy saqlash ishlaydi; bulut navbat ishga tushmaydi (partial Firebase freeze).
  static const bool enableCloudSync = false;

  /// V0.1 maqsad: asosiy mijoz Android. Web/desktop buildlar muzlatilgan bo‘lishi mumkin.
  /// Hozircha faqat hujjat/nazorat — compile’da alohida platforma o‘chirilmaydi.
  static const bool enforceAndroidOnlyProductTarget = true;
}
