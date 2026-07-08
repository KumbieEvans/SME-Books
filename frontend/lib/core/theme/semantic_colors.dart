import 'package:flutter/material.dart';

import 'colors.dart';

/// Status → colour mapping plus soft background tints for pills, banners and
/// status chips, and the hairline / muted-text tokens used across the portal.
///
/// Bases reuse [AppColors] semantic values so there is a single source of truth.
/// The `*Surface` variants are low-alpha tints meant to sit *behind* the base
/// colour as text/icon (e.g. a green "Approved" pill on a faint green wash).
class AppSemantic {
  AppSemantic._();

  // ---- Base status colours (reuse AppColors) ----
  static const Color success = AppColors.success; // 0xFF22C55E
  static const Color warning = AppColors.warning; // 0xFFF59E0B
  static const Color error = AppColors.error; // 0xFFEF4444
  static const Color info = AppColors.info; // 0xFF3B82F6
  static const Color neutral = AppColors.navy500; // 0xFF627D98

  // ---- Soft surface tints (low-alpha wash for pills / banners) ----
  static Color get successSurface => success.withValues(alpha: 0.12);
  static Color get warningSurface => warning.withValues(alpha: 0.12);
  static Color get errorSurface => error.withValues(alpha: 0.12);
  static Color get infoSurface => info.withValues(alpha: 0.12);
  static Color get neutralSurface => neutral.withValues(alpha: 0.12);

  // ---- Borders / dividers (hairlines) ----
  /// Hairline divider/border on light surfaces (navy @ ~10%).
  static const Color hairlineLight = Color(0x1A102A43);

  /// Hairline divider/border on dark surfaces (white @ ~10%).
  static const Color hairlineDark = Color(0x1AFFFFFF);

  /// Brightness-aware hairline.
  static Color hairline(Brightness b) =>
      b == Brightness.dark ? hairlineDark : hairlineLight;

  // ---- Text tokens ----
  /// Primary "ink" text.
  static const Color textPrimaryLight = AppColors.textPrimaryLight;
  static const Color textPrimaryDark = AppColors.textPrimaryDark;

  /// Secondary text (labels, captions).
  static const Color textSecondaryLight = AppColors.textSecondaryLight;
  static const Color textSecondaryDark = AppColors.textSecondaryDark;

  /// Muted text (placeholders, disabled, very low-emphasis meta).
  static const Color textMutedLight = AppColors.navy400; // 0xFF829AB1
  static const Color textMutedDark = Color(0xFF627D98); // navy-500

  /// Brightness-aware secondary text.
  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  /// Brightness-aware muted text.
  static Color textMuted(Brightness b) =>
      b == Brightness.dark ? textMutedDark : textMutedLight;

  // ---- Lookup helpers ----

  /// Resolve a base colour from a status key.
  static Color forStatus(AppStatus status) {
    switch (status) {
      case AppStatus.success:
        return success;
      case AppStatus.warning:
        return warning;
      case AppStatus.error:
        return error;
      case AppStatus.info:
        return info;
      case AppStatus.neutral:
        return neutral;
    }
  }

  /// Resolve the soft surface tint from a status key.
  static Color surfaceForStatus(AppStatus status) {
    switch (status) {
      case AppStatus.success:
        return successSurface;
      case AppStatus.warning:
        return warningSurface;
      case AppStatus.error:
        return errorSurface;
      case AppStatus.info:
        return infoSurface;
      case AppStatus.neutral:
        return neutralSurface;
    }
  }
}

/// Status key for [AppSemantic.forStatus] / [AppSemantic.surfaceForStatus].
enum AppStatus { success, warning, error, info, neutral }
