import 'package:flutter/widgets.dart';

/// Tailles d'écran logiques utilisées partout dans l'application.
enum ScreenSize { mobile, tablet, desktop, wide }

/// Seuils en logical pixels. Mobile-first : < 600 = mobile.
class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;

  /// Largeurs max recommandées pour borner le contenu sur grand écran.
  static const double maxFormWidth = 480;
  static const double maxContentWidth = 1100;
  static const double maxListWidth = 1400;
  static const double maxGridWidth = 1600;
}

extension ScreenSizeContext on BuildContext {
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < Breakpoints.mobile) return ScreenSize.mobile;
    if (width < Breakpoints.tablet) return ScreenSize.tablet;
    if (width < Breakpoints.desktop) return ScreenSize.desktop;
    return ScreenSize.wide;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop =>
      screenSize == ScreenSize.desktop || screenSize == ScreenSize.wide;
  bool get isWide => screenSize == ScreenSize.wide;

  /// Renvoie la valeur correspondant à la taille d'écran courante.
  /// `mobile` est obligatoire ; tablet/desktop/wide reprennent la précédente si absents.
  T valueByScreen<T>({required T mobile, T? tablet, T? desktop, T? wide}) {
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.wide:
        return wide ?? desktop ?? tablet ?? mobile;
    }
  }
}
