import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/core/theme/app_theme.dart';

void main() {
  test('le thème clair utilise une identité chaleureuse', () {
    final theme = AppTheme.light();

    expect(theme.colorScheme.primary, const Color(0xFFA34832));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFFAF6F0));
  });

  test('le thème sombre conserve un fond et des textes distincts', () {
    final theme = AppTheme.dark();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, isNot(const Color(0xFFFAF6F0)));
    expect(theme.colorScheme.onSurface, isNot(theme.scaffoldBackgroundColor));
  });
}
