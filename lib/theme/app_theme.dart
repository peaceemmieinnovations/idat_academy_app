import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1B0151);
  static const Color secondary = Color(0xFF283CE9);
  static const Color accent = Color(0xFFF2BC12);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color dark = Color(0xFF374151);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFE5E7EB);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF8FAFC);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.scaffoldBg,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.secondary.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightGrey,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

// Text Styles
class AppTextStyles {
  static const TextStyle h1 = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.3);
  static const TextStyle h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary);
  static const TextStyle h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark);
  static const TextStyle h4 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.dark);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textGrey);
  static const TextStyle label = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textGrey);
  static const TextStyle accent = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.secondary);
}
