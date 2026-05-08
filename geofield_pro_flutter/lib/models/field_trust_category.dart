/// Yagona ishonch holati — `warnings` ro‘yxatidan mustaqil, dastur bo‘ylab bir ma’noda.
/// Katta arxitektura emas: faqat deterministik tartib va bir nechta satr.
enum FieldTrustCategory {
  /// Baland ball, GPS va vaqt tanqididan o‘tmagan.
  verified,

  /// Takror, last_known, zaif aniqlik yoki boshqa yumshoq signal.
  suspect,

  /// Fix vaqti eskirgan (lekin mock / invalid emas).
  stale,

  /// GPS/koordinata ishonchli emas yoki yo‘q.
  partial,

  /// `isMocked` yoki ekvivalent signal.
  mocked,

  /// Sinxron bo‘lmagan aniqlik, shubhali fix vaqti, yoki null-island (coord ishonchli deb).
  invalid,
}
