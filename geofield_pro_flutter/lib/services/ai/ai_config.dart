class AiConfig {
  /// Toggle this to switch between Mock and Real AI (Gemini)
  static const bool useMock = true;

  /// Debug logging prefix
  static String get modeLog => "[AI MODE] ${useMock ? 'MOCK' : 'GEMINI'}";
}
