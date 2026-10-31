import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/theme.dart';

void main() {
  test('Pulse is the new-install theme and is available in light and dark', () {
    expect(AppThemePreset.fromId(null), AppThemePreset.pulse);
    final light = buildAppTheme(
      preset: AppThemePreset.pulse,
      darkMode: false,
    );
    final dark = buildAppTheme(
      preset: AppThemePreset.pulse,
      darkMode: true,
    );

    expect(light.useMaterial3, isTrue);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.navigationBarTheme.height, 78);
    expect(dark.navigationBarTheme.height, 78);
    expect(light.cardTheme.shape, isA<RoundedRectangleBorder>());
    expect(light.scaffoldBackgroundColor, kLightBackground);
    expect(dark.scaffoldBackgroundColor, kDarkBackground);
    expect(
      light.colorScheme.surfaceContainerLowest,
      buildLightTheme().colorScheme.surfaceContainerLowest,
    );
  });

  test('theme presets keep the same neutral surfaces and app background', () {
    for (final preset in AppThemePreset.values) {
      final light = buildAppTheme(preset: preset, darkMode: false);
      final dark = buildAppTheme(preset: preset, darkMode: true);

      expect(light.scaffoldBackgroundColor, kLightBackground);
      expect(dark.scaffoldBackgroundColor, kDarkBackground);
      expect(
        light.colorScheme.surface,
        buildLightTheme().colorScheme.surface,
      );
      expect(
        dark.colorScheme.surface,
        buildDarkTheme().colorScheme.surface,
      );
    }
  });
}
