import 'package:flutter/material.dart';

class BankTheme {
  final Color primaryColor;
  final Color secondaryColor;

  BankTheme({required this.primaryColor, required this.secondaryColor});

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
