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
  });
}
