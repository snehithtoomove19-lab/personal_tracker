import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/day_signals.dart';
import 'package:personal_tracker/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signal import updates provided fields and preserves missing values',
      () async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    await app.saveDaySignals(const DaySignals(
      dateKey: '2026-10-30',
      sleepQuality: 4,
      workoutMinutes: 10,
    ));

    await app.importDaySignals(const [
      DaySignals(dateKey: '2026-10-30', waterMl: 500, workoutMinutes: 20),
    ]);

    expect(app.daySignals, hasLength(1));
    expect(app.daySignals.single.sleepQuality, 4);
    expect(app.daySignals.single.workoutMinutes, 20);
    expect(app.daySignals.single.waterMl, 500);

    final preferences = await SharedPreferences.getInstance();
    final stored = jsonDecode(preferences.getString('daySignals')!);
    expect(stored, hasLength(1));
    expect(stored.single['sleepQuality'], 4);
    expect(stored.single['workoutMinutes'], 20);
    expect(stored.single['waterMl'], 500);
  });
}
