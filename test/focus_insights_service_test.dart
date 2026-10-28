import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/day_signals.dart';
import 'package:personal_tracker/services/focus_insights_service.dart';

DaySignals _signals({
  required String date,
  required int focus,
  int social = 0,
  int sleep = 4,
  double meetings = 1,
  int mealHour = 12,
  int screen = 120,
  bool intense = false,
}) =>
    DaySignals(
      dateKey: date,
      sleepQuality: sleep,
      socialMinutesBefore10: social,
      screenMinutes: screen,
      mealHour: mealHour,
      meetingHours: meetings,
      focusScore: focus,
      deepWorkCompleted: focus >= 7,
      workoutMinutes: intense ? 40 : 0,
      highIntensityWorkout: intense,
    );

void main() {
  test('daily signals serialize and read older entries without water data', () {
    final oldEntry = _signals(date: '2026-01-01', focus: 6).toJson()
      ..remove('waterMl');
    final restored = DaySignals.fromJson(oldEntry);
    expect(restored.waterMl, 0);
    expect(restored.toJson()['focusScore'], 6);
  });

  test('correlations need two observations in both groups', () {
    final result = FocusInsightsService.correlations([
      _signals(date: '2026-01-01', focus: 3, social: 60),
      _signals(date: '2026-01-02', focus: 4, social: 70),
      _signals(date: '2026-01-03', focus: 8),
      _signals(date: '2026-01-04', focus: 9),
    ]);

    final social = result.firstWhere(
      (item) => item.signal.startsWith('Social media'),
    );
    expect(social.highSignalDays, 2);
    expect(social.lowSignalDays, 2);
    expect(social.difference, -5);
    expect(social.highSignalDeepWorkPercent, 0);
    expect(social.lowSignalDeepWorkPercent, 100);
  });

  test('capacity applies documented load deductions and clamps to range', () {
    expect(
      FocusInsightsService.energyCapacity(
        today: _signals(
            date: '2026-01-01', focus: 5, sleep: 2, meetings: 3, intense: true),
        highPriorityTasksToday: 2,
      ),
      24,
    );
    expect(
      FocusInsightsService.energyCapacity(
        today: _signals(
            date: '2026-01-01',
            focus: 5,
            sleep: 1,
            meetings: 10,
            intense: true),
        highPriorityTasksToday: 10,
      ),
      0,
    );
  });
}
