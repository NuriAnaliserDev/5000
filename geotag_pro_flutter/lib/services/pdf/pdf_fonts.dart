import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// PDF uchun Noto Sans (Kirill / Lotin / o‘zbekcha) — [rootBundle] orqali.
class PdfFonts {
  static pw.Font? _base;
  static pw.Font? _bold;

  static Future<void> ensureLoaded() async {
    if (_base != null && _bold != null) return;
    final r = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final b = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    _base = pw.Font.ttf(r);
    _bold = pw.Font.ttf(b);
  }

  static pw.ThemeData theme() {
    return pw.ThemeData.withFont(base: _base!, bold: _bold!);
  }
}
