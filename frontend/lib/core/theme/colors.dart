import 'package:flutter/material.dart';

/// Brand palette shared across the e-loan ecosystem (website, aggregator app,
/// and this portal): navy (dark anchor) + teal (primary action) + coral (warm
/// accent), over a slate neutral ramp.
class AppColors {
  AppColors._();

  // ---- Brand role colors ----
  // Teal = primary action colour.
  static const Color primary = Color(0xFF0D9488); // teal-600
  static const Color primaryLight = Color(0xFF2DD4BF); // teal-400
  static const Color primaryDark = Color(0xFF0F766E); // teal-700

  // Navy = structural second colour (dark surfaces, sidebar, headings).
  static const Color secondary = Color(0xFF102A43); // navy-900
  static const Color secondaryLight = Color(0xFF334E68); // navy-700
  static const Color secondaryDark = Color(0xFF0B1D32); // navy-950

  // Coral = warm accent.
  static const Color accent = Color(0xFFE14434); // coral-600

  // ---- Brand ramps ----
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal200 = Color(0xFF99F6E4);
  static const Color teal300 = Color(0xFF5EEAD4);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal800 = Color(0xFF115E59);
  static const Color teal900 = Color(0xFF134E4A);

  static const Color coral50 = Color(0xFFFFF1EE);
  static const Color coral100 = Color(0xFFFFE0DA);
  static const Color coral200 = Color(0xFFFFC3B8);
  static const Color coral300 = Color(0xFFFB9D8C);
  static const Color coral400 = Color(0xFFFB7268);
  static const Color coral500 = Color(0xFFF0584B);
  static const Color coral600 = Color(0xFFE14434);
  static const Color coral700 = Color(0xFFBD3324);
  static const Color coral800 = Color(0xFF9F2C20);
  static const Color coral900 = Color(0xFF831F15);

  static const Color navy50 = Color(0xFFF0F4F8);
  static const Color navy100 = Color(0xFFD9E2EC);
  static const Color navy200 = Color(0xFFBCCCDC);
  static const Color navy300 = Color(0xFF9FB3C8);
  static const Color navy400 = Color(0xFF829AB1);
  static const Color navy500 = Color(0xFF627D98);
  static const Color navy600 = Color(0xFF486581);
  static const Color navy700 = Color(0xFF334E68);
  static const Color navy800 = Color(0xFF243B53);
  static const Color navy900 = Color(0xFF102A43);
  static const Color navy950 = Color(0xFF0B1D32);

  // ---- Background and Surface ----
  static const Color backgroundLight = Color(0xFFF8FAFC); // slate-50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0B1D32); // navy-950
  static const Color surfaceDark = Color(0xFF102A43); // navy-900

  // ---- Text colors ----
  static const Color textPrimaryLight = Color(0xFF102A43); // navy-900
  static const Color textSecondaryLight = Color(0xFF62748E); // slate-500
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // slate-50
  static const Color textSecondaryDark = Color(0xFF90A1B9); // slate-400

  // ---- Semantic (aligned with the aggregator app) ----
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ---- Dashboard / chart categorical colors (all on-brand) ----
  static const Color chartPrimary = Color(0xFF14B8A6); // teal-500
  static const Color chartSecondary = Color(0xFFF0584B); // coral-500
  static const Color chartTertiary = Color(0xFF486581); // navy-600
  static const Color chartQuaternary = Color(0xFF115E59); // teal-800

  // ---- Sidebar (dark navy) ----
  static const Color sidebarBackgroundDark = Color(0xFF081320); // deepest navy
  static const Color sidebarItemHover = Color(0xFF243B53); // navy-800
  static const Color sidebarItemSelected = Color(0xFF334E68); // navy-700
}
