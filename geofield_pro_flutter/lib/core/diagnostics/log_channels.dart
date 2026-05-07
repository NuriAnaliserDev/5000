/// Konsol va `diagnostics.log` uchun yagona prefixlar (FREEZE: log strategy).
enum DiagLogChannel {
  boot('[BOOT]'),
  camera('[CAMERA]'),
  map('[MAP]'),
  gps('[GPS]'),
  ai('[AI]'),
  cache('[CACHE]'),
  sync('[SYNC]'),
  error('[ERROR]');

  const DiagLogChannel(this.prefix);
  final String prefix;
}
