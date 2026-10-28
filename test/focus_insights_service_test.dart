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
    final oldEntry = <String, dynamic>{'dateKey': '2026-01-01'};
    final restored = DaySignals.fromJson(oldEntry);
    expect(restored.waterMl, isNull);
    expect(restored.focusScore, isNull);
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

  test('unknown signals are excluded from comparisons and estimates', () {
    final days = [
      _signals(date: '2026-01-01', focus: 3, social: 60),
      _signals(date: '2026-01-02', focus: 4, social: 70),
      _signals(date: '2026-01-03', focus: 8),
      _signals(date: '2026-01-04', focus: 9),
      const DaySignals(dateKey: '2026-01-05', workoutMinutes: 20),
    ];
    final social = FocusInsightsService.correlations(days)
        .firstWhere((item) => item.signal.startsWith('Social media'));
    expect(social.highSignalDays, 2);
    expect(social.lowSignalDays, 2);

    expect(
      FocusInsightsService.energyCapacity(
        today: const DaySignals(dateKey: '2026-01-05', workoutMinutes: 20),
        highPriorityTasksToday: 2,
      ),
      90,
    );
    expect(
      FocusInsightsService.estimatedTimeToCritical(
        capacity: 90,
        today: const DaySignals(dateKey: '2026-01-05', workoutMinutes: 20),
        highPriorityTasksToday: 0,
      ),
      isNull,
    );
  });

  test('focus comparisons work when deep-work completion is unknown', () {
    final result = FocusInsightsService.correlations(const [
      DaySignals(
        dateKey: '2026-02-01',
        focusScore: 2,
        socialMinutesBefore10: 60,
      ),
      DaySignals(
        dateKey: '2026-02-02',
        focusScore: 4,
        socialMinutesBefore10: 70,
      ),
      DaySignals(
        dateKey: '2026-02-03',
        focusScore: 8,
        socialMinutesBefore10: 0,
      ),
      DaySignals(
        dateKey: '2026-02-04',
        focusScore: 10,
        socialMinutesBefore10: 10,
      ),
    ]);

    final social = result.firstWhere(
      (item) => item.signal.startsWith('Social media'),
    );
    expect(social.highSignalDays, 2);
    expect(social.lowSignalDays, 2);
    expect(social.highSignalDeepWorkPercent, isNull);
  });
}
