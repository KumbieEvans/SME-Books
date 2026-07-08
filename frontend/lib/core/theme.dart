import 'package:flutter/material.dart';
import 'theme/colors.dart';
import 'theme/app_theme.dart';

// Re-export AppTheme from the new token system so the app uses it globally.
export 'theme/app_theme.dart';
export 'theme/colors.dart';
export 'theme/spacing.dart';
export 'theme/semantic_colors.dart';

/// Legacy shim — keeps all existing screens compiling while they still import
/// 'core/theme.dart'. The color constants now point to the new brand palette.
class AppTheme {
  // Teal green: primary action colour (teal-600).
  static const Color primaryTeal = AppColors.primary; // 0xFF0D9488

  // Navy blue: structural / sidebar colour (navy-900).
  static const Color navyBlue = AppColors.secondary; // 0xFF102A43

  static ThemeData get lightTheme => _AppTheme.lightTheme;
}

/// Internal alias to avoid name clash with the shim above.
final class _AppTheme {
  static ThemeData get lightTheme {
    // Delegate to the new tokenised theme.
    // This is imported via 'theme/app_theme.dart' exported above.
    return const _Delegate().build();
  }
}

class _Delegate {
  const _Delegate();
  ThemeData build() {
    // Forward to the real AppTheme (imported as core/theme/app_theme.dart).
    // We use a workaround since both classes share the name AppTheme.
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        dataRowColor: WidgetStateProperty.all(Colors.white),
      ),
    );
  }
}
