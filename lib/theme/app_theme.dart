import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==========================================
  // CENTRALIZED COLORS
  // Change these to update the entire app!
  // ==========================================

  // Light Mode Colors
  static const Color primaryLight = Color(0xFF1D4ED8); // Corporate Blue
  static const Color backgroundLight = Color(0xFFF8FAFC); // Off-white clean background
  static const Color surfaceLight = Color(0xFFFFFFFF); // White cards
  static const Color textDark = Color(0xFF1E293B); // Dark slate text
  static const Color borderLight = Color(0xFFE2E8F0); // Soft gray borders
  static const Color hintLight = Color(0xFF94A3B8); // Gray placeholder text

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFF3B82F6); // Lighter blue for dark mode visibility
  static const Color backgroundDark = Color(0xFF0F172A); // Dark slate background
  static const Color surfaceDark = Color(0xFF1E293B); // Slightly lighter slate for cards
  static const Color textLight = Color(0xFFF8FAFC); // White text
  static const Color borderDark = Color(0xFF334155); // Dark gray borders
  static const Color hintDark = Color(0xFF64748B); // Dark placeholder text

  // Common Constants
  static const double borderRadius = 12.0;
  static const double borderThickness = 1.0;
  static const double focusedBorderThickness = 2.0;

  // ==========================================
  // SHADOWS
  // ==========================================
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get darkShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ==========================================
  // THEME DATA GENERATORS
  // ==========================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        onPrimary: Colors.white,
        surface: surfaceLight,
        onSurface: textDark,
        background: backgroundLight,
        onBackground: textDark,
        outline: borderLight,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.displayLarge),
        displayMedium: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.displayMedium),
        displaySmall: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.displaySmall),
        headlineLarge: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.headlineLarge),
        headlineMedium: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.headlineMedium),
        headlineSmall: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.headlineSmall),
        titleLarge: GoogleFonts.outfit(textStyle: ThemeData.light().textTheme.titleLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderLight, width: borderThickness),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderLight, width: borderThickness),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryLight, width: focusedBorderThickness),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        labelStyle: const TextStyle(color: textDark, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: hintLight, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        onPrimary: Colors.white,
        surface: surfaceDark,
        onSurface: textLight,
        background: backgroundDark,
        onBackground: textLight,
        outline: borderDark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.displayLarge),
        displayMedium: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.displayMedium),
        displaySmall: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.displaySmall),
        headlineLarge: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.headlineLarge),
        headlineMedium: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.headlineMedium),
        headlineSmall: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.headlineSmall),
        titleLarge: GoogleFonts.outfit(textStyle: ThemeData.dark().textTheme.titleLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderDark, width: borderThickness),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: borderDark, width: borderThickness),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryDark, width: focusedBorderThickness),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        labelStyle: const TextStyle(color: textLight, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: hintDark, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
