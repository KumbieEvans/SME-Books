import 'package:flutter/material.dart';

import 'colors.dart';
import 'elevation.dart';
import 'semantic_colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Central theme assembly. Consumes the token layer (typography / spacing /
/// elevation / semantic colours) to produce a flat, hairline, subtle-shadow
/// fintech aesthetic (Mercury / Ramp / Linear) for both light and dark.
class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color scaffold =
        isDark ? AppElevation.darkSurface0 : AppElevation.lightSurface0;
    final Color cardSurface = AppElevation.surface1(brightness);
    final Color hairline = AppSemantic.hairline(brightness);
    final Color onSurface =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: cardSurface,
      error: AppColors.error,
    ).copyWith(
      surface: cardSurface,
      onSurface: onSurface,
      onSurfaceVariant: AppSemantic.textSecondary(brightness),
      onPrimary: isDark ? AppColors.backgroundDark : Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      surfaceTint: Colors.transparent,
      outline: hairline,
      outlineVariant: hairline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: AppTypography.textTheme(brightness),
      dividerColor: hairline,

      // ---- App bar: flat, subtle scrolled-under ----
      appBarTheme: AppBarTheme(
        backgroundColor: cardSurface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: hairline,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme(brightness).titleLarge,
      ),

      // ---- Cards: FLAT — elevation 0, hairline border, consistent radius ----
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : AppColors.secondary.withValues(alpha: 0.02),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(color: hairline, width: 1),
        ),
      ),

      // ---- Inputs: hairline borders, tighter padding, primary focus ring ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: AppSemantic.textMuted(brightness)),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: hairline),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: hairline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
      ),

      // ---- Buttons: flat-ish, consistent radius, label typography ----
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTypography.textTheme(brightness).labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTypography.textTheme(brightness).labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: hairline),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTypography.textTheme(brightness).labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.textTheme(brightness).labelLarge,
        ),
      ),

      // ---- Dialog / divider / chip: tokenised radii + hairlines ----
      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        titleTextStyle: AppTypography.textTheme(brightness).headlineSmall,
        contentTextStyle: AppTypography.textTheme(brightness).bodyMedium,
      ),
      dividerTheme: DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppElevation.surface2(brightness),
        side: BorderSide(color: hairline),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brPill),
        labelStyle: AppTypography.textTheme(brightness).labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(color: hairline),
        ),
      ),
    );
  }
}
