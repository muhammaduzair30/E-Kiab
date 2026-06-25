// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF2563EB);       // Bright blue (Tailwind Blue 600)
  static const Color primaryLight = Color(0xFF60A5FA);  // Blue 400
  static const Color primaryDark = Color(0xFF1E3A8A);   // Blue 900
  static const Color primaryContainer = Color(0xFFDBEAFE); // Blue 100

  // Secondary (green — growth, learning)
  static const Color secondary = Color(0xFF10B981);     // Emerald 500
  static const Color secondaryLight = Color(0xFF34D399); // Emerald 400
  static const Color secondaryDark = Color(0xFF064E3B);  // Emerald 900
  static const Color secondaryContainer = Color(0xFFD1FAE5); // Emerald 100

  // Accent / Urdu highlight
  static const Color accent = Color(0xFFF59E0B);        // Amber 500
  static const Color accentLight = Color(0xFFFBBF24);   // Amber 400

  // Semantic
  static const Color success = Color(0xFF10B981);       // Emerald 500
  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color error = Color(0xFFEF4444);         // Red 500
  static const Color info = Color(0xFF3B82F6);          // Blue 500

  // Subject colors
  static const Color mathColor = Color(0xFF2563EB);
  static const Color scienceColor = Color(0xFF10B981);
  static const Color urduColor = Color(0xFF8B5CF6);     // Violet 500
  static const Color englishColor = Color(0xFF06B6D4);  // Cyan 500
  static const Color islamiatColor = Color(0xFF059669); // Emerald 600
  static const Color historyColor = Color(0xFFD97706);  // Amber 600
  static const Color csColor = Color(0xFF475569);       // Slate 600
  static const Color physicsColor = Color(0xFF1D4ED8);  // Blue 700
  static const Color chemColor = Color(0xFFBE185D);     // Pink 700
  static const Color bioColor = Color(0xFF15803D);      // Green 700

  // Neutrals — Light
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);    // Slate 50
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color outline = Color(0xFFCBD5E1);       // Slate 300
  static const Color onSurface = Color(0xFF0F172A);     // Slate 900
  static const Color onSurfaceVariant = Color(0xFF475569); // Slate 600

  // Neutrals — Dark
  static const Color darkSurface = Color(0xFF1E293B);   // Slate 800
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurfaceVariant = Color(0xFF334155); // Slate 700
  static const Color darkOutline = Color(0xFF475569);   // Slate 600
  static const Color darkOnSurface = Color(0xFFF8FAFC); // Slate 50
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8); // Slate 400

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);

  // Border
  static const Color border = Color(0xFFE2E8F0);        // Slate 200

  // Semantic light variants
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], // Bright blue to deep blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.6)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryContainer,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.2),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.2),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.3),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onSurface, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurface, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.primaryDark,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.secondaryDark,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: AppColors.secondaryLight,
      tertiary: AppColors.accentLight,
      onTertiary: Colors.black,
      error: Color(0xFFF87171), // Red 400
      onError: Colors.black,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.darkBackground,

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.darkOutline, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
        hintStyle: TextStyle(color: AppColors.darkOnSurfaceVariant.withOpacity(0.6)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.darkOnSurfaceVariant,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primaryDark,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkOnSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.darkOnSurface, height: 1.2),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.darkOnSurface, height: 1.2),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.darkOnSurface, height: 1.3),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkOnSurface),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkOnSurface),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkOnSurface),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkOnSurface),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkOnSurface),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkOnSurface),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.darkOnSurface, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.darkOnSurface, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.darkOnSurfaceVariant, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
