import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barcha [ColorScheme] / tema tokenlari — hardcoded 0xFF qoldirmaslik uchun markaz.
abstract final class AppTheme {
  static const Color _primaryLight = Color(0xFF263238);
  static const Color _secondaryLight = Color(0xFF1565C0);
  static const Color _scaffoldLight = Color(0xFFF5F5F5);
  static const Color _primaryDark = Color(0xFF455A64);
  static const Color _secondaryDark = Color(0xFF42A5F5);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primaryLight,
        secondary: _secondaryLight,
        surface: Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: _scaffoldLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: _scaffoldLight,
        foregroundColor: _primaryLight,
        elevation: 0,
      ),
      textTheme: GoogleFonts.robotoTextTheme(),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryDark,
        secondary: _secondaryDark,
        surface: Color(0xFF121212),
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
    );
  }
}
