import 'package:flutter/material.dart';

class BankTheme {
  final Color primaryColor; // Accent color per bank
  final Color secondaryColor;
  final Color primaryNeutral; // Charcoal
  final Color background; // Soft gray
  final Color surfaceContainer; // Light gray for inputs

  BankTheme({
    required this.primaryColor,
    required this.secondaryColor,
    this.primaryNeutral = const Color(0xFF0F172A),
    this.background = const Color(0xFFFAF8FF),
    this.surfaceContainer = const Color(0xFFFFFFFF),
  });

  static BankTheme getTheme(String bankName) {
    switch (bankName.toUpperCase()) {
      case 'ASKBL':
        return BankTheme(
          primaryColor: const Color(0xFF0072BC),
          secondaryColor: const Color(0xFF1E3A8A),
          background: const Color(0xFFFAF8FF),
          primaryNeutral: const Color(0xFF0F172A),
          surfaceContainer: const Color(0xFFFFFFFF),
        );
      case 'MCB':
        return BankTheme(
          primaryColor: const Color(0xFF00843D),
          secondaryColor: const Color(0xFF047857),
          background: const Color(0xFFFAF8FF),
          primaryNeutral: const Color(0xFF0F172A),
          surfaceContainer: const Color(0xFFFFFFFF),
        );
      case 'BAF':
        return BankTheme(
          primaryColor: const Color(0xFFD71920),
          secondaryColor: const Color(0xFFB91C1C),
          background: const Color(0xFFFAF8FF),
          primaryNeutral: const Color(0xFF0F172A),
          surfaceContainer: const Color(0xFFFFFFFF),
        );
      default:
        return BankTheme(
          primaryColor: const Color(0xFF004AAF),
          secondaryColor: const Color(0xFF505F76),
          background: const Color(0xFFFAF8FF),
          primaryNeutral: const Color(0xFF0F172A),
          surfaceContainer: const Color(0xFFFFFFFF),
        );
    }
  }
}
