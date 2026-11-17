import 'package:flutter/material.dart';

/// Core social-impact design system for Kindoverse.
/// Uses an accessible Emerald/Teal primary palette, warm Amber accents,
/// and a clean off-white canvas optimized for both Web and Mobile.
class AppColors {
  AppColors._();

  // Primary Palette (Emerald / Deep Teal)
  static const Color primaryEmerald = Color(0xFF065F46);
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color primarySurface = Color(0xFFECFDF5);

  // Secondary / Accent Palette (Warm Amber / Gold)
  static const Color accentAmber = Color(0xFFD97706);
  static const Color accentAmberLight = Color(0xFFFEF3C7);
  static const Color accentGold = Color(0xFFF59E0B);

  // Neutral / Surface Palette
  static const Color backgroundOffWhite = Color(0xFFF9FAFB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF3F4F6);
  static const Color borderSubtle = Color(0xFFE5E7EB);

  // Text & Contrast (WCAG AA/AAA compliant)
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF6B7280);

  // Semantic Status Colors
  static const Color verifiedBlue = Color(0xFF0284C7);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color warningOrange = Color(0xFFEA580C);
  static const Color errorRed = Color(0xFFDC2626);

  // Category Marker Colors
  static const Color categoryEducation = Color(0xFF2563EB);
  static const Color categoryVillage = Color(0xFF9333EA);
  static const Color categoryPlantation = Color(0xFF15803D);
  static const Color categoryAgriculture = Color(0xFFCA8A04);
  static const Color categoryWaterSanitation = Color(0xFF0284C7);
  static const Color categoryCommunalWelfare = Color(0xFFE11D48);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryEmerald,
      primary: AppColors.primaryEmerald,
      secondary: AppColors.accentAmber,
      tertiary: AppColors.primaryTeal,
      surface: AppColors.surfaceWhite,
      error: AppColors.errorRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundOffWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryEmerald,
          side: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSubtle,
        selectedColor: AppColors.primaryLight,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
