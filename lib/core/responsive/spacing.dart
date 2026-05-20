import 'package:flutter/widgets.dart';

/// Échelle d'espacement utilisée partout dans l'application.
/// Préférer ces constantes plutôt que des `EdgeInsets.all(16)` magiques.
class Spacing {
  Spacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets pageMobile = EdgeInsets.all(md);
  static const EdgeInsets pageTablet = EdgeInsets.all(lg);
  static const EdgeInsets pageDesktop = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
}
