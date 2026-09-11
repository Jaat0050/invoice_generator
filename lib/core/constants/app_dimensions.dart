import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Spacing & Padding
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Insets
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 16.0,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets modalPadding = EdgeInsets.all(20.0);

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Heights & Sizes
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;
  static const double bottomNavHeight = 64.0;
  static const double kpiCardMinHeight = 110.0;
}
