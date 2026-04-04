import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF141926);
  static const Color surfaceLight = Color(0xFF1C2233);
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF00D9A6);
  static const Color error = Color(0xFFFF4757);
  static const Color warning = Color(0xFFFFA502);

  static const Color textPrimary = Color(0xDEFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      surface: background,
      primary: primary,
      secondary: secondary,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.inter(color: textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
      displayMedium: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
      displaySmall: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
      headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      titleSmall: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
    );
  }
}
