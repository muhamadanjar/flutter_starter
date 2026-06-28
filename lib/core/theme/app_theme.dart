import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import './app_colors.dart';
import './app_typography.dart';

class AppTheme {
  AppTheme._();

  // ── DARK THEME ─────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      extensions: const <ThemeExtension<dynamic>>[AppColorScheme.dark],
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.cream,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.cream,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.accent,
        onTertiary: AppColors.cream,
        error: AppColors.error,
        onError: AppColors.cream,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
      ),
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          textStyle: AppTypography.headlineSmall.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
      ),
      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.cream,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            textStyle: AppTypography.buttonLarge,
          ),
        ),
      ),
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            textStyle: AppTypography.buttonLarge,
          ),
        ),
      ),
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            textStyle: AppTypography.buttonMedium,
          ),
        ),
      ),
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextHint),
        ),
        labelStyle: GoogleFonts.inter(
          textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        ),
        errorStyle: GoogleFonts.inter(
          textStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      // Navigation Rail
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.darkTextHint),
        selectedLabelTextStyle: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: AppColors.darkTextHint, fontSize: 12),
      ),
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: GoogleFonts.inter(
          textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
        ),
      ),
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          textStyle: AppTypography.labelMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cream,
      ),
      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.darkTextHint,
        indicatorColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(
          textStyle: AppTypography.labelLarge,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          textStyle: AppTypography.labelMedium,
        ),
      ),
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.darkTextHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.5);
          return AppColors.darkSurfaceVariant;
        }),
      ),
      // Text Theme
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.inter(textStyle: AppTypography.headlineLarge.copyWith(color: AppColors.darkTextPrimary)),
        headlineMedium: GoogleFonts.inter(textStyle: AppTypography.headlineMedium.copyWith(color: AppColors.darkTextPrimary)),
        headlineSmall: GoogleFonts.inter(textStyle: AppTypography.headlineSmall.copyWith(color: AppColors.darkTextPrimary)),
        bodyLarge: GoogleFonts.inter(textStyle: AppTypography.bodyLarge.copyWith(color: AppColors.darkTextPrimary)),
        bodyMedium: GoogleFonts.inter(textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary)),
        bodySmall: GoogleFonts.inter(textStyle: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary)),
        labelLarge: GoogleFonts.inter(textStyle: AppTypography.labelLarge.copyWith(color: AppColors.darkTextPrimary)),
        labelMedium: GoogleFonts.inter(textStyle: AppTypography.labelMedium.copyWith(color: AppColors.darkTextSecondary)),
        labelSmall: GoogleFonts.inter(textStyle: AppTypography.labelSmall.copyWith(color: AppColors.darkTextSecondary)),
      ),
    );
  }

  // ── LIGHT THEME ────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      extensions: const <ThemeExtension<dynamic>>[AppColorScheme.light],
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.cream,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.cream,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.accent,
        onTertiary: AppColors.cream,
        error: AppColors.error,
        onError: AppColors.cream,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
      ),
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          textStyle: AppTypography.headlineSmall.copyWith(
            color: AppColors.lightTextPrimary,
          ),
        ),
      ),
      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.cream,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            textStyle: AppTypography.buttonLarge,
          ),
        ),
      ),
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            textStyle: AppTypography.buttonLarge,
          ),
        ),
      ),
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            textStyle: AppTypography.buttonMedium,
          ),
        ),
      ),
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextHint),
        ),
        labelStyle: GoogleFonts.inter(
          textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
        ),
        errorStyle: GoogleFonts.inter(
          textStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      // Navigation Rail
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.lightTextHint),
        selectedLabelTextStyle: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: AppColors.lightTextHint, fontSize: 12),
      ),
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: GoogleFonts.inter(
          textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
        ),
      ),
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          textStyle: AppTypography.labelMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cream,
      ),
      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.lightTextHint,
        indicatorColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(
          textStyle: AppTypography.labelLarge,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          textStyle: AppTypography.labelMedium,
        ),
      ),
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.lightTextHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.5);
          return AppColors.lightSurfaceVariant;
        }),
      ),
      // Text Theme
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.inter(textStyle: AppTypography.headlineLarge.copyWith(color: AppColors.lightTextPrimary)),
        headlineMedium: GoogleFonts.inter(textStyle: AppTypography.headlineMedium.copyWith(color: AppColors.lightTextPrimary)),
        headlineSmall: GoogleFonts.inter(textStyle: AppTypography.headlineSmall.copyWith(color: AppColors.lightTextPrimary)),
        bodyLarge: GoogleFonts.inter(textStyle: AppTypography.bodyLarge.copyWith(color: AppColors.lightTextPrimary)),
        bodyMedium: GoogleFonts.inter(textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary)),
        bodySmall: GoogleFonts.inter(textStyle: AppTypography.bodySmall.copyWith(color: AppColors.lightTextSecondary)),
        labelLarge: GoogleFonts.inter(textStyle: AppTypography.labelLarge.copyWith(color: AppColors.lightTextPrimary)),
        labelMedium: GoogleFonts.inter(textStyle: AppTypography.labelMedium.copyWith(color: AppColors.lightTextSecondary)),
        labelSmall: GoogleFonts.inter(textStyle: AppTypography.labelSmall.copyWith(color: AppColors.lightTextSecondary)),
      ),
    );
  }
}
