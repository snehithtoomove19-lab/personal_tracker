import '../models/day_signals.dart';

class FocusCorrelation {
  final String signal;
  final int highSignalAverage;
  final int lowSignalAverage;
  final int highSignalDays;
  final int lowSignalDays;
  final int highSignalDeepWorkPercent;
  final int lowSignalDeepWorkPercent;

  const FocusCorrelation({
    required this.signal,
    required this.highSignalAverage,
    required this.lowSignalAverage,
    required this.highSignalDays,
    required this.lowSignalDays,
    required this.highSignalDeepWorkPercent,
    required this.lowSignalDeepWorkPercent,
  });

  int get difference => highSignalAverage - lowSignalAverage;
}

class FocusInsightsService {
  static const _minimumGroupSize = 2;

  static List<FocusCorrelation> correlations(List<DaySignals> days) {
    final rules = <({String label, bool Function(DaySignals) matches})>[
      (
        label: 'Social media before 10 AM (>45 min)',
        matches: (day) => day.socialMinutesBefore10 > 45
      ),
      (
        label: 'Poor sleep (quality <=2/5)',
        matches: (day) => day.sleepQuality <= 2
      ),
      (
        label: 'Heavy meeting load (>=4 hours)',
        matches: (day) => day.meetingHours >= 4
      ),
      (
        label: 'Late first meal (after 1 PM)',
        matches: (day) => day.mealHour > 13
      ),
      (
        label: 'High screen time (>=5 hours)',
        matches: (day) => day.screenMinutes >= 300
      ),
    ];

    final results = <FocusCorrelation>[];
    for (final rule in rules) {
      final high = days.where(rule.matches).toList();
      final low = days.where((day) => !rule.matches(day)).toList();
      if (high.length < _minimumGroupSize || low.length < _minimumGroupSize) {
        continue;
      }
      results.add(FocusCorrelation(
        signal: rule.label,
        highSignalAverage: _average(high.map((day) => day.focusScore)),
        lowSignalAverage: _average(low.map((day) => day.focusScore)),
        highSignalDays: high.length,
        lowSignalDays: low.length,
        highSignalDeepWorkPercent: _percent(
          high.where((day) => day.deepWorkCompleted).length,
          high.length,
        ),
        lowSignalDeepWorkPercent: _percent(
          low.where((day) => day.deepWorkCompleted).length,
          low.length,
        ),
      ));
    }
    results.sort((a, b) => a.difference.compareTo(b.difference));
    return results;
  }

  static int _average(Iterable<int> values) =>
      (values.reduce((a, b) => a + b) / values.length).round();

  static int _percent(int matches, int total) =>
      (matches * 100 / total).round();

  static int energyCapacity({
    required DaySignals? today,
    required int highPriorityTasksToday,
  }) {
    if (today == null) return 100;
    var capacity = 100;
    capacity -= (5 - today.sleepQuality) * 10;
    capacity -= (today.meetingHours * 8).round();
    capacity -= highPriorityTasksToday * 5;
    if (today.highIntensityWorkout) capacity -= 12;
    return capacity.clamp(0, 100);
  }

  static Duration? estimatedTimeToCritical({
    required int capacity,
    required DaySignals? today,
    required int highPriorityTasksToday,
  }) {
    if (capacity <= 15 || today == null) return Duration.zero;
    final modeledHours =
        today.meetingHours + (highPriorityTasksToday * 0.5) + 1;
    final modeledDrain = 100 - capacity;
    if (modeledDrain == 0) return null;
    final hoursToCritical = ((capacity - 15) / modeledDrain) * modeledHours;
    return Duration(minutes: (hoursToCritical * 60).round());
  }
}
