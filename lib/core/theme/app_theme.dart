import 'package:flutter/material.dart';

/// Thème centralisé de l'application.
/// Évite la duplication ThemeData light/dark dans main.dart et garantit
/// la cohérence visuelle (densité adaptative, formes, typographie).
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFFA34832);
  static const Color _cream = Color(0xFFFAF6F0);
  static const Color _night = Color(0xFF211B18);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final generatedScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final colorScheme = generatedScheme.copyWith(
      primary: brightness == Brightness.light ? _seed : const Color(0xFFE6A18D),
      onPrimary: brightness == Brightness.light ? Colors.white : _night,
      surface:
          brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF302824),
      onSurface:
          brightness == Brightness.light
              ? const Color(0xFF2E2420)
              : const Color(0xFFF8EEE8),
      secondary:
          brightness == Brightness.light
              ? const Color(0xFF36745B)
              : const Color(0xFF90D0AD),
      tertiary:
          brightness == Brightness.light
              ? const Color(0xFFAA6818)
              : const Color(0xFFF4BE6D),
    );

    final baseText =
        brightness == Brightness.light
            ? Typography.blackMountainView
            : Typography.whiteMountainView;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: brightness == Brightness.light ? _cream : _night,
      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        displayMedium: baseText.displayMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: baseText.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: baseText.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        indicatorColor: colorScheme.primaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: colorScheme.surface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.primaryContainer,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light ? _cream : _night,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
