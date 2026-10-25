import 'package:flutter/material.dart';

/// Test Nest Modern Executive EdTech Design System.
/// UI-only constants; no application/business logic lives here.
class AppColors {
  // Brand Primary (Deep Royal Indigo / Modern EdTech Blue)
  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryLight = Color(0xFF818CF8);
  static const primarySoft = Color(0xFFEEF2FF);

  // Brand Secondary (Vibrant Violet / Student Accent)
  static const secondary = Color(0xFF7C3AED);
  static const secondaryDark = Color(0xFF5B21B6);
  static const secondarySoft = Color(0xFFF5F3FF);

  // Brand Tertiary (Electric Teal / Cyan Accent)
  static const cyan = Color(0xFF0EA5E9);
  static const cyanSoft = Color(0xFFF0F9FF);

  // Semantic Status Colors
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);

  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFFBEB);

  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEF2F2);

  // Neutral Surfaces & Typography
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const text = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
}

class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF6366F1)],
  );

  static const student = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFF4F46E5), Color(0xFF0EA5E9)],
  );

  static const teacherHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5)],
  );

  static const soft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
  );
}

class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.18),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}

class ColorTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.cyan,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
    );
  }
}
