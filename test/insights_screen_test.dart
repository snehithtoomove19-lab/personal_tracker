import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/screens/insights_screen.dart';
import 'package:personal_tracker/services/app_scope.dart';
import 'package:personal_tracker/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('daily signals remain unknown until selected',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();

    await tester.pumpWidget(
      AppScope(
        appState: app,
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log today'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(app.todaySignals?.sleepQuality, 3);
    expect(app.todaySignals?.focusScore, isNull);
    expect(app.todaySignals?.socialMinutesBefore10, isNull);

    app.dispose();
  });
}
