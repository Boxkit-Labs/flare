import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFFF8F9FA); 
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF3F4F6); 
  
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFFA855F7); // Purple 500
  static const Color secondary = Color(0xFF0F172A); // Slate 900
  
  static const Color error = Color(0xFFF43F5E); // Rose 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500

  static const Color textPrimary = Color(0xFF0F172A); 
  static const Color textSecondary = Color(0xFF64748B); 

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      surface: surface,
      primary: primary,
      secondary: secondary,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: Colors.black.withOpacity(0.08), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -2),
      displayMedium: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1),
      displaySmall: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1),
      headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
      headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
      titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
      titleSmall: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary, height: 1.5),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary, height: 1.5),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary, height: 1.5),
      labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
      labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 0.5),
    );
  }

  static LinearGradient get primaryGradient {
    return const LinearGradient(
      colors: [primary, primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

