// THEME LOCK: dark — source: domain signal (law enforcement, night/vehicle use)
// Scaffold.backgroundColor = AppTheme.backgroundDark — ALL screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryContainer = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryContainer = Color(0xFF6D28D9);

  // ── Semantic Colors ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  // ── Dark Surfaces ─────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceVariantDark = Color(0xFF16213E);
  static const Color glassSurface = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white

  // ── Light Surfaces ────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF4F6FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEEF2FF);

  // ── Category Colors ───────────────────────────────────────────────────────
  static const Color categoryAsayis = Color(0xFF3B82F6);
  static const Color categoryTrafik = Color(0xFF10B981);
  static const Color categoryNarkotik = Color(0xFF8B5CF6);
  static const Color categoryYangin = Color(0xFFEF4444);
  static const Color categoryKayip = Color(0xFFF59E0B);
  static const Color categoryAile = Color(0xFFEC4899);

  // =========================================================================
  // DARK THEME
  // =========================================================================
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFFDBEAFE),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFFEDE9FE),
      surface: surfaceDark,
      onSurface: Color(0xFFE8E8F0),
      surfaceContainerHighest: surfaceVariantDark,
      onSurfaceVariant: Color(0xFFB0B0C8),
      error: error,
      onError: Colors.white,
      outline: Color(0xFF3A3A5C),
      outlineVariant: Color(0xFF252540),
      inverseSurface: Color(0xFFE8E8F0),
      onInverseSurface: Color(0xFF1A1A2E),
      shadow: Color(0x66000000),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme:
        GoogleFonts.ibmPlexSansTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            displayMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            headlineLarge: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
            headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            bodyLarge: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            bodySmall: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            labelLarge: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            labelMedium: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ).apply(
          bodyColor: const Color(0xFFE8E8F0),
          displayColor: const Color(0xFFE8E8F0),
        ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Color(0xFFE8E8F0),
    ),
    cardTheme: CardThemeData(
      color: glassSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: glassBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: glassSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: glassBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: glassBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      labelStyle: const TextStyle(color: Color(0xFF8888A8), fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF5A5A7A), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: glassSurface,
      selectedColor: primary.withAlpha(64),
      disabledColor: glassSurface,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      side: const BorderSide(color: glassBorder, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF252540),
      thickness: 1,
    ),
    iconTheme: const IconThemeData(color: Color(0xFFB0B0C8), size: 22),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: CircleBorder(),
    ),
  );

  // =========================================================================
  // LIGHT THEME
  // =========================================================================
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: Color(0xFF1D4ED8),
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surfaceLight,
      onSurface: Color(0xFF1A1A2E),
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: Color(0xFF4A4A6A),
      error: error,
      onError: Colors.white,
      outline: Color(0xFFCCCCDD),
      outlineVariant: Color(0xFFEEEEF5),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.ibmPlexSansTextTheme().apply(
      bodyColor: const Color(0xFF1A1A2E),
      displayColor: const Color(0xFF1A1A2E),
    ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Color(0xFF1A1A2E),
    ),
  );
}
