import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // Secondary palette
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color secondaryDark = Color(0xFF5B21B6);

  // Accent colors
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Card status colors
  static const Color newCard = Color(0xFF3B82F6);
  static const Color learning = Color(0xFFF59E0B);
  static const Color review = Color(0xFF8B5CF6);
  static const Color mastered = Color(0xFF10B981);

  // Deck colors
  static const List<Color> deckColors = [
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFEAB308), // Yellow
    Color(0xFF22C55E), // Green
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF6B7280), // Gray
    Color(0xFF92400E), // Brown
  ];

  // Difficulty rating colors
  static const Color again = Color(0xFFEF4444);
  static const Color hard = Color(0xFFF97316);
  static const Color good = Color(0xFF22C55E);
  static const Color easy = Color(0xFF3B82F6);

  // Neutral colors
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF4F4F5);
  static const Color grey200 = Color(0xFFE4E4E7);
  static const Color grey300 = Color(0xFFD4D4D8);
  static const Color grey400 = Color(0xFFA1A1AA);
  static const Color grey500 = Color(0xFF71717A);
  static const Color grey600 = Color(0xFF52525B);
  static const Color grey700 = Color(0xFF3F3F46);
  static const Color grey800 = Color(0xFF27272A);
  static const Color grey900 = Color(0xFF18181B);
}
