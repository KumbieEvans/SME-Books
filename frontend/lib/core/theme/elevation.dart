import 'package:flutter/material.dart';

import 'colors.dart';

/// Surface elevation system for a flat, hairline fintech aesthetic.
///
/// Instead of drop-shadow-heavy "floating" cards, depth is communicated mostly
/// by *surface level* (a lightness ramp) plus an optional very subtle shadow.
///
/// Light mode: a near-white ramp on a slate-50 scaffold.
/// Dark mode: OPAQUE navy steps that get slightly lighter per level — no
/// alpha-based "fake glass" (which has no backdrop in this app and reads muddy).
class AppElevation {
  AppElevation._();

  // ---- Light surface ramp ----
  /// Scaffold / app background (slate-50).
  static const Color lightSurface0 = AppColors.backgroundLight; // 0xFFF8FAFC
  /// Resting card / panel surface (white).
  static const Color lightSurface1 = AppColors.surfaceLight; // 0xFFFFFFFF
  /// Slightly raised surface (white — depth carried by border/shadow).
  static const Color lightSurface2 = Color(0xFFFFFFFF);
  /// Highest light surface (white).
  static const Color lightSurface3 = Color(0xFFFFFFFF);

  // ---- Dark surface ramp (opaque, lightening per step) ----
  /// Scaffold / app background (navy-950).
  static const Color darkSurface0 = AppColors.backgroundDark; // 0xFF0B1D32
  /// Resting card / panel surface (navy-900).
  static const Color darkSurface1 = AppColors.surfaceDark; // 0xFF102A43
  /// Raised surface (navy-800).
  static const Color darkSurface2 = Color(0xFF18334F);
  /// Highest dark surface (between navy-800 and navy-700).
  static const Color darkSurface3 = Color(0xFF20415F);

  /// Pick the resting surface (level 1) for a brightness.
  static Color surface1(Brightness b) =>
      b == Brightness.dark ? darkSurface1 : lightSurface1;

  /// Pick the raised surface (level 2) for a brightness.
  static Color surface2(Brightness b) =>
      b == Brightness.dark ? darkSurface2 : lightSurface2;

  /// Pick the highest surface (level 3) for a brightness.
  static Color surface3(Brightness b) =>
      b == Brightness.dark ? darkSurface3 : lightSurface3;

  // ---- Subtle shadows (low-alpha navy / black) ----

  /// Whisper shadow for resting flat cards.
  static const List<BoxShadow> shadowSm = <BoxShadow>[
    BoxShadow(
      color: Color(0x05000000), // black @ ~2%
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Slightly more present shadow for raised/hover surfaces and menus.
  static const List<BoxShadow> shadowMd = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A000000), // black @ ~4%
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x05000000), // black @ ~2%
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Overlay shadow for popovers / dialogs.
  static const List<BoxShadow> shadowLg = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F0B1D32), // deep navy @ ~12%
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  /// Dark-mode shadows use black (navy is too low-contrast on navy).
  static const List<BoxShadow> shadowSmDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x33000000), // black @ ~20%
      blurRadius: 8,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMdDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x40000000), // black @ ~25%
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Brightness-aware small shadow.
  static List<BoxShadow> sm(Brightness b) =>
      b == Brightness.dark ? shadowSmDark : shadowSm;

  /// Brightness-aware medium shadow.
  static List<BoxShadow> md(Brightness b) =>
      b == Brightness.dark ? shadowMdDark : shadowMd;
}
