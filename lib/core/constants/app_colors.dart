import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightPrimary = Color(0xFF6366F1); // Indigo
  static const Color lightPrimaryContainer = Color(0xFFEEF2F6);
  static const Color lightSecondary = Color(0xFF0EA5E9); // Sky blue
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF090D16); // Ultra dark slate
  static const Color darkSurface = Color(0xFF131B2E); // Deep Navy slate
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkPrimary = Color(0xFF818CF8); // Indigo light
  static const Color darkPrimaryContainer = Color(0xFF312E81); // Dark indigo
  static const Color darkSecondary = Color(0xFF38BDF8); // Sky blue light
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF1E2942); // Slate 700ish

  // Utility colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Syntax highlighting colors - Dark Mode
  static const Color syntaxKeyDark = Color(0xFFF43F5E);      // Rose 500
  static const Color syntaxStringDark = Color(0xFF34D399);   // Emerald 400
  static const Color syntaxNumberDark = Color(0xFFF59E0B);   // Amber 500
  static const Color syntaxBoolDark = Color(0xFF60A5FA);     // Blue 400
  static const Color syntaxNullDark = Color(0xFFA78BFA);     // Violet 400
  static const Color syntaxBracketDark = Color(0xFF94A3B8);  // Slate 400

  // Syntax highlighting colors - Light Mode
  static const Color syntaxKeyLight = Color(0xFFE11D48);     // Rose 600
  static const Color syntaxStringLight = Color(0xFF059669);  // Emerald 600
  static const Color syntaxNumberLight = Color(0xFFD97706);  // Amber 600
  static const Color syntaxBoolLight = Color(0xFF2563EB);    // Blue 600
  static const Color syntaxNullLight = Color(0xFF7C3AED);    // Violet 600
  static const Color syntaxBracketLight = Color(0xFF475569); // Slate 600
}
