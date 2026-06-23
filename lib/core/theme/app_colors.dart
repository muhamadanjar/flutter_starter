import 'package:flutter/material.dart';

// ============================================================
// Color Palette based on: #607456, #EEE0CC, #BA6A4C, #7B2525
// ============================================================
//
// #607456 — Sage Olive Green  → Primary
// #EEE0CC — Warm Cream        → Light Background / Dark Text
// #BA6A4C — Terracotta        → Accent / CTA
// #7B2525 — Deep Burgundy     → Secondary / Danger
//
// ============================================================

class AppColors {
  AppColors._();

  // ── Primary: Sage Olive Green ──────────────────────────
  static const Color primary = Color(0xFF607456);
  static const Color primaryLight = Color(0xFF7A9470);
  static const Color primaryDark = Color(0xFF4A5C43);
  static const Color primaryContainer = Color(0xFFD6E4D0);

  // ── Secondary: Deep Burgundy ───────────────────────────
  static const Color secondary = Color(0xFF7B2525);
  static const Color secondaryLight = Color(0xFF9E3E3E);
  static const Color secondaryDark = Color(0xFF5C1C1C);
  static const Color secondaryContainer = Color(0xFFE8C4C4);

  // ── Accent: Terracotta ─────────────────────────────────
  static const Color accent = Color(0xFFBA6A4C);
  static const Color accentLight = Color(0xFFD4896E);
  static const Color accentDark = Color(0xFF965038);
  static const Color accentContainer = Color(0xFFF4DDD2);

  // ── Neutral: Warm Cream ────────────────────────────────
  static const Color cream = Color(0xFFEEE0CC);
  static const Color creamLight = Color(0xFFF5EDE0);
  static const Color creamDark = Color(0xFFD9C9B0);

  // ── DARK MODE Backgrounds ──────────────────────────────
  static const Color darkBackground = Color(0xFF141914);
  static const Color darkSurface = Color(0xFF1E241C);
  static const Color darkSurfaceVariant = Color(0xFF283026);
  static const Color darkCardBackground = Color(0xFF222820);

  // ── LIGHT MODE Backgrounds ─────────────────────────────
  static const Color lightBackground = Color(0xFFEEE0CC);
  static const Color lightSurface = Color(0xFFF5EDE0);
  static const Color lightSurfaceVariant = Color(0xFFE8DFD0);
  static const Color lightCardBackground = Color(0xFFF2EAD8);

  // ── DARK MODE Text ─────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFEEE0CC);
  static const Color darkTextSecondary = Color(0xFFA8B0A0);
  static const Color darkTextHint = Color(0xFF6B7466);
  static const Color darkTextDisabled = Color(0xFF4A5246);

  // ── LIGHT MODE Text ────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF2A2E28);
  static const Color lightTextSecondary = Color(0xFF5A6258);
  static const Color lightTextHint = Color(0xFF8A9288);
  static const Color lightTextDisabled = Color(0xFFB0B8AC);

  // ── Status Colors ──────────────────────────────────────
  static const Color success = Color(0xFF4E8C4A);
  static const Color successLight = Color(0xFF6AAF66);
  static const Color warning = Color(0xFFC49A2A);
  static const Color warningLight = Color(0xFFD9B44A);
  static const Color error = Color(0xFF7B2525);
  static const Color errorLight = Color(0xFF9E3E3E);
  static const Color info = Color(0xFF4A7B8C);

  // ── DARK MODE Dividers & Borders ───────────────────────
  static const Color darkDivider = Color(0xFF2E352C);
  static const Color darkBorder = Color(0xFF3A4238);

  // ── LIGHT MODE Dividers & Borders ──────────────────────
  static const Color lightDivider = Color(0xFFD4CBB8);
  static const Color lightBorder = Color(0xFFC8BFAC);

  // ── Gradients ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4E8C4A), Color(0xFF6AAF66)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================================
// Theme Extension — context-aware colors for light/dark mode
// ============================================================

class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryContainer;
  final Color secondary;
  final Color secondaryLight;
  final Color secondaryContainer;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color accentContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textDisabled;
  final Color divider;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const AppColorScheme({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryContainer,
    required this.secondary,
    required this.secondaryLight,
    required this.secondaryContainer,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.accentContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textDisabled,
    required this.divider,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  // ── Dark Mode Colors ───────────────────────────────────
  static const dark = AppColorScheme(
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    primaryDark: AppColors.primaryDark,
    primaryContainer: AppColors.primaryContainer,
    secondary: AppColors.secondary,
    secondaryLight: AppColors.secondaryLight,
    secondaryContainer: AppColors.secondaryContainer,
    accent: AppColors.accent,
    accentLight: AppColors.accentLight,
    accentDark: AppColors.accentDark,
    accentContainer: AppColors.accentContainer,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    cardBackground: AppColors.darkCardBackground,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    textDisabled: AppColors.darkTextDisabled,
    divider: AppColors.darkDivider,
    border: AppColors.darkBorder,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
  );

  // ── Light Mode Colors ──────────────────────────────────
  static const light = AppColorScheme(
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    primaryDark: AppColors.primaryDark,
    primaryContainer: AppColors.primaryContainer,
    secondary: AppColors.secondary,
    secondaryLight: AppColors.secondaryLight,
    secondaryContainer: AppColors.secondaryContainer,
    accent: AppColors.accent,
    accentLight: AppColors.accentLight,
    accentDark: AppColors.accentDark,
    accentContainer: AppColors.accentContainer,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    cardBackground: AppColors.lightCardBackground,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textHint: AppColors.lightTextHint,
    textDisabled: AppColors.lightTextDisabled,
    divider: AppColors.lightDivider,
    border: AppColors.lightBorder,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
  );

  @override
  AppColorScheme copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? primaryContainer,
    Color? secondary,
    Color? secondaryLight,
    Color? secondaryContainer,
    Color? accent,
    Color? accentLight,
    Color? accentDark,
    Color? accentContainer,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? textDisabled,
    Color? divider,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppColorScheme(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      accentDark: accentDark ?? this.accentDark,
      accentContainer: accentContainer ?? this.accentContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      textDisabled: textDisabled ?? this.textDisabled,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

// ============================================================
// BuildContext extension for easy access
// ============================================================

extension BuildContextColors on BuildContext {
  AppColorScheme get colors => Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.dark;
}
