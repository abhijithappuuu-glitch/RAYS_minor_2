import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette - Premium Dark with Cyan Accent
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color primaryGold = Color(0xFF00E5FF); // alias for compatibility
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentPink = Color(0xFFFF6090);
  static const Color backgroundDark = Color(0xFF0A0E1A);
  static const Color surfaceDark = Color(0xFF141829);
  static const Color surfaceLight = Color(0xFF1E2240);
  static const Color cardDark = Color(0xFF171B30);
  
  // Stress Risk Colors
  static const Color riskLow = Color(0xFF00E676);
  static const Color riskMedium = Color(0xFFFFAB40);
  static const Color riskHigh = Color(0xFFFF5252);
  
  // Glassmorphism
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x22FFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D1);
  static const Color textTertiary = Color(0xFF5A6080);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1F38), Color(0xFF141829)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  
  // Border Radius
  static const double radiusS = 12.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXl = 32.0;
  
  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryCyan,
      scaffoldBackgroundColor: backgroundDark,
      
      // Typography
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
        ),
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentPurple,
        surface: surfaceDark,
      ),
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────────────
  static const Color lightBackground   = Color(0xFFF5F7FF);
  static const Color lightSurface      = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard  = Color(0xFFF0F2FF);
  static const Color lightBorder       = Color(0xFFDDE2F0);
  static const Color lightTextPrimary  = Color(0xFF0D1225);
  static const Color lightTextSecond   = Color(0xFF4A5275);
  static const Color lightTextTertiary = Color(0xFF9BA3BF);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryCyan,
      scaffoldBackgroundColor: lightBackground,

      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: lightTextPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: lightTextPrimary,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: lightTextPrimary,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: lightTextPrimary,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: lightTextSecond,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: lightTextSecond,
          ),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),

      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),

      colorScheme: const ColorScheme.light(
        primary: primaryCyan,
        secondary: accentPurple,
        surface: lightSurface,
      ),
    );
  }
  
  // Get stress color by risk level
  static Color getStressColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return riskLow;
      case 'medium':
        return riskMedium;
      case 'high':
        return riskHigh;
      default:
        return textSecondary;
    }
  }
  
  // Get stress color by score
  static Color getStressColorByScore(int score) {
    if (score >= 70) return riskHigh;
    if (score >= 40) return riskMedium;
    return riskLow;
  }
}
