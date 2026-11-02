// Basic smoke test for the Personal Tracker app.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_tracker/main.dart';
import 'package:personal_tracker/screens/search_screen.dart';
import 'package:personal_tracker/services/app_scope.dart';

void main() {
  testWidgets('App starts and shows a loading indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());

    // Before data finishes loading from SharedPreferences, the app shows a
    // simple loading spinner rather than any specific screen content.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Dark mode updates the app and pushed screens',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AppRoot());
    await tester.pumpAndSettle();

    final root = find.byType(RootShell);
    expect(root, findsOneWidget);
    var context = tester.element(root);
    expect(Theme.of(context).brightness, Brightness.light);

    await AppScope.of(context).setDarkMode(true);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(root)).brightness, Brightness.dark);

    unawaited(Navigator.of(tester.element(root)).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
    ));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SearchScreen))).brightness,
      Brightness.dark,
    );
  });
}
