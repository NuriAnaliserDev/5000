/// Production diagnostikasida yagona `domain` — qidiruv/filter uchun.
enum DiagnosticDomain {
  startup,
  appLifecycle,
  camera,
  gps,
  firebase,
  failure,
  sync,
  storage,
  /// Sessiya / auth / sinxron navbatni qayta tiklash (offline, crash keyin).
  session,
}
