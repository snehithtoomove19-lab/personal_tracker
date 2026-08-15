// Basic smoke test for the Personal Tracker app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personal_tracker/main.dart';

void main() {
  testWidgets('App starts and shows a loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());

    // Before data finishes loading from SharedPreferences, the app shows a
    // simple loading spinner rather than any specific screen content.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
