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
    this.background = const Color(0xFFF8FAFC),
    this.surfaceContainer = const Color(0xFFF1F5F9),
  });

  static BankTheme getTheme(String bankName) {
    switch (bankName.toUpperCase()) {
      case 'ASKBL':
        return BankTheme(
          primaryColor: const Color(0xFF0072BC),
          secondaryColor: const Color(0xFF8C8C8C),
        );
      case 'MCB':
        return BankTheme(
          primaryColor: const Color(0xFF00843D),
          secondaryColor: const Color(0xFF005A2B),
        );
      case 'BAF':
        return BankTheme(
          primaryColor: const Color(0xFFD71920),
          secondaryColor: const Color(0xFF808285),
        );
      case 'FSBL':
        return BankTheme(
          primaryColor: const Color(0xFF006C3F),
          secondaryColor: const Color(0xFF8BC53F),
        );
      case 'MBL':
        return BankTheme(
          primaryColor: const Color(0xFF006838),
          secondaryColor: const Color(0xFFC69C3F),
        );
      case 'MMB':
        return BankTheme(
          primaryColor: const Color(0xFFE30613),
          secondaryColor: const Color(0xFF333333),
        );
      case 'SMBL':
        return BankTheme(
          primaryColor: const Color(0xFF7A1F5C),
          secondaryColor: const Color(0xFFB39B6B),
        );
      default:
        return BankTheme(
          primaryColor: const Color(0xFF0057B8),
          secondaryColor: const Color(0xFF0F8B4C),
        );
    }
  }
}
