import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/day_signals.dart';
import 'package:personal_tracker/screens/home_screen.dart';
import 'package:personal_tracker/services/app_scope.dart';
import 'package:personal_tracker/services/app_state.dart';
import 'package:personal_tracker/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester,
    AppState app,
  ) async {
    await tester.pumpWidget(
      AppScope(
        appState: app,
        child: MaterialApp(
          theme: buildAppTheme(
            preset: AppThemePreset.pulse,
            darkMode: false,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('quick water chips add intake and preserve other signals',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    await app.saveDaySignals(
      DaySignals(
        dateKey: daySignalsKey(DateTime.now()),
        waterMl: 400,
        workoutMinutes: 20,
      ),
    );
    await pumpHome(tester, app);

    await tester.ensureVisible(find.text('250 ml water'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('250 ml water'));
    await tester.pumpAndSettle();

    expect(app.todaySignals?.waterMl, 650);
    expect(app.todaySignals?.workoutMinutes, 20);
    app.dispose();
  });

  testWidgets('focus card opens the detailed insights screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    await pumpHome(tester, app);

    await tester.ensureVisible(find.text('Log more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log more'));
    await tester.pumpAndSettle();

    expect(find.text('Focus & Energy Insights'), findsOneWidget);
    expect(find.text('Log today'), findsOneWidget);
    app.dispose();
  });
}
