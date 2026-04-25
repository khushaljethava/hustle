import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors — Productivity-focused trust blue + energetic teal
  static const Color primaryColor = Color(0xFF4F6EF7);    // Trust indigo-blue
  static const Color primaryDark = Color(0xFF3451D1);
  static const Color secondaryColor = Color(0xFF00C9A7);  // Teal – success/active
  static const Color accentColor = Color(0xFFFF6B6B);     // Coral – alerts/CTA

  // Semantic Colors
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Light palette
  static const Color backgroundLight = Color(0xFFF6F8FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F3FF);
  static const Color onSurfaceLight = Color(0xFF1A1D3D);
  static const Color onSurfaceMutedLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E9F8);

  // Dark palette
  static const Color backgroundDark = Color(0xFF0D0F1E);
  static const Color surfaceDark = Color(0xFF171929);
  static const Color cardDark = Color(0xFF1E2138);
  static const Color inputFillDark = Color(0xFF232640);
  static const Color onSurfaceDark = Color(0xFFF1F3FF);
  static const Color onSurfaceMutedDark = Color(0xFF9CA3AF);
  static const Color onSurfaceMutedNavDark = Color(0xFF6B7280);
  static const Color hintColorDark = Color(0xFF4B5563);
  static const Color borderDark = Color(0xFF2A2E4A);

  // Layout constants
  static const double navBarHeight = 68;
  static const double pageHorizontalPadding = 16;
  static const double bottomScrollPadding = 100;

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: onSurfaceLight,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: onSurfaceLight),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 22);
          }
          return const IconThemeData(color: onSurfaceMutedDark, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: onSurfaceMutedDark, fontSize: 11, fontWeight: FontWeight.w500,
          );
        }),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: onSurfaceMutedDark, fontSize: 15),
        labelStyle: const TextStyle(color: onSurfaceMutedLight, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(0, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          minimumSize: const Size(44, 44),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantLight,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        space: 1, thickness: 1, color: borderLight,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: onSurfaceLight),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: onSurfaceLight),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: onSurfaceLight),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurfaceLight),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurfaceLight),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurfaceLight),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: onSurfaceLight),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceLight),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: onSurfaceLight),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: onSurfaceLight),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, color: onSurfaceMutedLight),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceLight),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceMutedLight),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onSurfaceMutedLight),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: onSurfaceDark, letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: onSurfaceDark),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: primaryColor.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 22);
          }
          return const IconThemeData(color: onSurfaceMutedNavDark, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: onSurfaceMutedNavDark, fontSize: 11, fontWeight: FontWeight.w500);
        }),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: hintColorDark, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(0, 52),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: onSurfaceDark),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: onSurfaceDark),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: onSurfaceDark),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurfaceDark),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurfaceDark),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurfaceDark),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: onSurfaceDark),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceDark),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: onSurfaceDark),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: onSurfaceDark),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, color: onSurfaceMutedDark),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceDark),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceMutedDark),
      ),
    );
  }
}
