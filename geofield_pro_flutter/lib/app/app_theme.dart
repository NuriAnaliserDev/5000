import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stitch dashboard mockup’lariga mos: glass kartalar, chuqur ko‘k-qora fon, `#4A90E2` aktsent.
abstract final class AppTheme {
  static const Color stitchBlue = Color(0xFF4A90E2);
  static const Color stitchBlueDeep = Color(0xFF1E4A7A);
  static const Color darkScaffold = Color(0xFF0B0F14);
  static const Color darkSurface = Color(0xFF131B26);
  static const Color darkSurfaceContainer = Color(0xFF1A2433);

  static ThemeData light() {
    const primary = Color(0xFF1E3A5F);
    const secondary = stitchBlue;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      surface: const Color(0xFFF6F8FC),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: baseScheme.copyWith(
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF1A1F26),
        onSurfaceVariant: const Color(0xFF546E7A),
        outline: Colors.black.withValues(alpha: 0.12),
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F4FA),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF0F4FA).withValues(alpha: 0.94),
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.robotoTextTheme(),
    );
  }

  static ThemeData dark() {
    const primary = stitchBlue;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: const Color(0xFF64B5F6),
      surface: darkSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: baseScheme.copyWith(
        onPrimary: Colors.white,
        onSecondary: darkScaffold,
        primaryContainer: stitchBlueDeep,
        onPrimaryContainer: Colors.white,
        onSurface: Colors.white,
        onSurfaceVariant: const Color(0xFFB0BEC5),
        surfaceContainerHighest: darkSurfaceContainer,
        outline: Colors.white.withValues(alpha: 0.14),
      ),
      scaffoldBackgroundColor: darkScaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: darkScaffold.withValues(alpha: 0.72),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurfaceContainer.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
