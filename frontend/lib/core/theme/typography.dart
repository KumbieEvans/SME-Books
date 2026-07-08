import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Deliberate type ramp built on Outfit (Google Fonts).
///
/// Every role carries explicit fontSize / fontWeight / height (line-height) and
/// letterSpacing so screens stop hand-rolling
/// `titleLarge?.copyWith(fontWeight: bold)`. Apply via [textTheme] / [apply].
///
/// Line-heights are expressed as a multiple of font size (Flutter `height`).
class AppTypography {
  AppTypography._();

  /// The base text theme with no colour applied. Colours are layered on per
  /// brightness in [textTheme].
  static TextTheme get _base => GoogleFonts.outfitTextTheme(
        const TextTheme(
          // ---- Display ----
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1.08,
            letterSpacing: -1.0,
          ),
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.12,
            letterSpacing: -0.5,
          ),
          displaySmall: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            height: 1.16,
            letterSpacing: -0.25,
          ),

          // ---- Headline ----
          headlineLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.25,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.22,
            letterSpacing: -0.2,
          ),
          headlineSmall: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            height: 1.26,
            letterSpacing: -0.1,
          ),

          // ---- Title (card headers, section labels) ----
          titleLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.33,
            letterSpacing: -0.2,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.36,
            letterSpacing: 0,
          ),

          // ---- Body ----
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.55,
            letterSpacing: 0,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.55,
            letterSpacing: 0,
          ),
          bodySmall: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0.1,
          ),

          // ---- Label (buttons, chips, captions) ----
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0.2,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0.4,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0.5,
          ),
        ),
      );

  /// Build a fully coloured [TextTheme] for the given [brightness].
  ///
  /// Primary text uses the navy/slate ink colour; the lighter "secondary"
  /// tones are applied by widgets that need muted text (see `AppSemantic`).
  static TextTheme textTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color ink =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return _base.apply(bodyColor: ink, displayColor: ink);
  }

  /// Light-mode text theme convenience accessor.
  static TextTheme get light => textTheme(Brightness.light);

  /// Dark-mode text theme convenience accessor.
  static TextTheme get dark => textTheme(Brightness.dark);
}
