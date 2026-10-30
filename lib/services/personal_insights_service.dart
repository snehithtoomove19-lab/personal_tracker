import '../models/day_signals.dart';
import '../models/mood_entry.dart';
import '../models/task.dart';
import '../models/transaction.dart';
import 'focus_insights_service.dart';

class PersonalForecast {
  final String? likelyMood;
  final int? estimatedCapacity;
  final int moodObservations;
  final int signalObservations;
  final String recommendation;

  const PersonalForecast({
    required this.likelyMood,
    required this.estimatedCapacity,
    required this.moodObservations,
    required this.signalObservations,
    required this.recommendation,
  });
}

class PresentAlert {
  final String title;
  final String detail;

  const PresentAlert(this.title, this.detail);
}

class ReportPeriod {
  final DateTime start;
  final DateTime end;
  final String label;

  const ReportPeriod(this.start, this.end, this.label);
}

class PersonalInsightsService {
  static String buildAiContext({
    required List<AppTransaction> transactions,
    required List<MoodEntry> moods,
    required List<AppTask> tasks,
    required List<DaySignals> signals,
    required String currency,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final start = today.subtract(const Duration(days: 29));
    bool inRecentWindow(DateTime date) {
      final day = _dateOnly(date);
      return !day.isBefore(start) && !day.isAfter(today);
    }

    var income = 0.0;
    var expenses = 0.0;
    for (final transaction
        in transactions.where((item) => inRecentWindow(item.date))) {
      if (transaction.type == TxType.income) {
        income += transaction.amount;
      } else {
        expenses += transaction.amount;
      }
    }

    final moodCounts = <String, int>{};
    for (final mood in moods.where((item) => inRecentWindow(item.date))) {
      moodCounts.update(mood.mood, (count) => count + 1, ifAbsent: () => 1);
    }

    final recentSignals = signals.where((signal) {
      final date = DateTime.tryParse(signal.dateKey);
      return date != null && inRecentWindow(date);
    }).toList();
    final sleep = recentSignals
        .where((signal) => signal.sleepQuality != null)
        .map((signal) => signal.sleepQuality!)
        .toList();
    final meetingHours = recentSignals
        .where((signal) => signal.meetingHours != null)
        .map((signal) => signal.meetingHours!)
        .toList();
    final workoutMinutes = recentSignals.fold<int>(
        0, (total, signal) => total + (signal.workoutMinutes ?? 0));
    final waterMl = recentSignals.fold<int>(
        0, (total, signal) => total + (signal.waterMl ?? 0));
    final overdueTasks = tasks.where((task) {
      final due = task.dueDate;
      return !task.completed && due != null && _dateOnly(due).isBefore(today);
    }).length;
    final upcomingTasks = tasks.where((task) {
      final due = task.dueDate;
      return !task.completed &&
          due != null &&
          !_dateOnly(due).isBefore(today) &&
          !_dateOnly(due).isAfter(today.add(const Duration(days: 6)));
    }).length;
    final moodSummary = moodCounts.isEmpty
        ? 'No mood check-ins were logged.'
        : moodCounts.entries
            .map((entry) => '${moodOptionFor(entry.key).label}: ${entry.value}')
            .join(', ');

    return [
      'User-approved personal context; aggregated records from the last 30 days ending $today.',
      'Do not infer missing data. State when records are absent. Treat these as self-reported tracker data, not medical advice or causal evidence.',
      'Cash flow: income $currency ${income.toStringAsFixed(2)}, expenses $currency ${expenses.toStringAsFixed(2)}, net $currency ${(income - expenses).toStringAsFixed(2)}.',
      'Mood check-ins: $moodSummary.',
      'Daily signals: ${recentSignals.length} days with records; '
          'exercise $workoutMinutes minutes logged; water $waterMl ml logged; '
          'sleep quality average ${_average(sleep)} from ${sleep.length} known entries; '
          'meeting hours average ${_averageDecimal(meetingHours)} from ${meetingHours.length} known entries.',
      'Tasks: $overdueTasks overdue and $upcomingTasks due in the next 7 days.',
      'Privacy: no notes, transaction descriptions, merchant names, task titles, or raw daily records are included.',
    ].join('\n');
  }

  static PersonalForecast forecast({
    required List<MoodEntry> moods,
    required List<DaySignals> signals,
    required List<AppTask> tasks,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final recentMoods = moods
        .where((mood) =>
            !_dateOnly(mood.date).isAfter(today) &&
            !_dateOnly(mood.date)
                .isBefore(today.subtract(const Duration(days: 13))))
        .toList();
    final moodCounts = <String, int>{};
    for (final mood in recentMoods) {
      moodCounts.update(mood.mood, (count) => count + 1, ifAbsent: () => 1);
    }
    String? likelyMood;
    if (recentMoods.length >= 3) {
      likelyMood =
          moodCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    final recentSignals = signals.where((signal) {
      final date = DateTime.tryParse(signal.dateKey);
      return date != null &&
          !date.isAfter(today) &&
          !date.isBefore(today.subtract(const Duration(days: 6)));
    }).toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    final tomorrowHighPriorityTasks = tasks
        .where((task) =>
            !task.completed &&
            task.priority == TaskPriority.high &&
            task.dueDate != null &&
            _sameDay(task.dueDate!, tomorrow))
        .length;

    int? capacity;
    if (recentSignals.isNotEmpty &&
        (recentSignals.first.sleepQuality != null ||
            recentSignals.first.meetingHours != null ||
            recentSignals.first.highIntensityWorkout == true ||
            tomorrowHighPriorityTasks > 0)) {
      capacity = FocusInsightsService.energyCapacity(
        today: recentSignals.first,
        highPriorityTasksToday: tomorrowHighPriorityTasks,
      );
    }

    final tomorrowTasks = tasks
        .where((task) =>
            !task.completed &&
            task.dueDate != null &&
            _sameDay(task.dueDate!, tomorrow))
        .length;
    final lowSleep = recentSignals.isNotEmpty &&
        recentSignals.first.sleepQuality != null &&
        recentSignals.first.sleepQuality! <= 2;
    final recommendation = lowSleep || (capacity != null && capacity < 45)
        ? 'Keep tomorrow light: choose one priority and leave room for breaks.'
        : tomorrowTasks >= 4
            ? 'Tomorrow looks busy. Consider moving one non-urgent task or '
                'adding a buffer between commitments.'
            : tomorrowTasks == 0
                ? 'Choose one small habit for tomorrow and protect a little '
                    'unscheduled time.'
                : 'Start with your most important task, then take a short '
                    'reset before the next one.';

    return PersonalForecast(
      likelyMood: likelyMood,
      estimatedCapacity: capacity,
      moodObservations: recentMoods.length,
      signalObservations: recentSignals.length,
      recommendation: recommendation,
    );
  }

  static List<PresentAlert> alerts({
    required List<AppTask> tasks,
    required List<DaySignals> signals,
    required Map<String, List<double>> overBudgetCategories,
    required double todayExpense,
    required List<AppTransaction> transactions,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final alerts = <PresentAlert>[];
    final overdueCount = tasks.where((task) {
      final due = task.dueDate;
      return !task.completed && due != null && _dateOnly(due).isBefore(today);
    }).length;
    final dueToday = tasks.where((task) {
      final due = task.dueDate;
      return !task.completed && due != null && _sameDay(due, today);
    }).length;
    if (overdueCount > 0) {
      alerts.add(PresentAlert(
        '$overdueCount overdue ${overdueCount == 1 ? 'task' : 'tasks'}',
        'Review or reschedule them when you are ready.',
      ));
    }
    if (dueToday > 0) {
      alerts.add(PresentAlert(
        '$dueToday ${dueToday == 1 ? 'task' : 'tasks'} due today',
        'Your task list has commitments scheduled for today.',
      ));
    }
    final todaySignal =
        signals.where((signal) => signal.dateKey == daySignalsKey(today));
    if (todaySignal.isNotEmpty &&
        todaySignal.first.sleepQuality != null &&
        todaySignal.first.sleepQuality! <= 2) {
      alerts.add(const PresentAlert(
        'Low sleep-quality check-in',
        'Consider a gentler plan today. This is a self-reported signal, not a diagnosis.',
      ));
    }
    if (todaySignal.isNotEmpty &&
        todaySignal.first.meetingHours != null &&
        todaySignal.first.meetingHours! >= 4) {
      alerts.add(const PresentAlert(
        'Heavy meeting load logged',
        'A short break between commitments may help protect focus.',
      ));
    }
    for (final entry in overBudgetCategories.entries) {
      if (entry.value.length >= 2) {
        alerts.add(PresentAlert(
          '${entry.key} is over budget',
          'Tracked spending is ${entry.value[0].toStringAsFixed(2)} '
              'against a ${entry.value[1].toStringAsFixed(2)} budget.',
        ));
      }
    }

    final priorDailyExpenses = <DateTime, double>{};
    for (final transaction in transactions) {
      if (transaction.type != TxType.expense) continue;
      final day = _dateOnly(transaction.date);
      if (day.isBefore(today) &&
          !day.isBefore(today.subtract(const Duration(days: 30)))) {
        priorDailyExpenses.update(
          day,
          (amount) => amount + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    if (priorDailyExpenses.length >= 3 && todayExpense > 0) {
      final average = priorDailyExpenses.values.reduce((a, b) => a + b) /
          priorDailyExpenses.length;
      if (average > 0 && todayExpense >= average * 2) {
        alerts.add(PresentAlert(
          'Today’s spending is above your recent pattern',
          'Today: ${todayExpense.toStringAsFixed(2)}; recent logged-day '
              'average: ${average.toStringAsFixed(2)}.',
        ));
      }
    }
    return alerts;
  }

  static String answerQuery({
    required String query,
    required List<AppTransaction> transactions,
    required List<MoodEntry> moods,
    required List<AppTask> tasks,
    required List<DaySignals> signals,
    String currency = '',
    DateTime? now,
  }) {
    final normalized = query.toLowerCase();
    final reference = _dateOnly(now ?? DateTime.now());
    final period = _periodFor(normalized, reference);
    bool inPeriod(DateTime date) =>
        !_dateOnly(date).isBefore(period.start) &&
        _dateOnly(date).isBefore(period.end);
    final prefix = '${period.label}: ';

    if (normalized.contains('exercise') ||
        normalized.contains('workout') ||
        normalized.contains('water')) {
      final matchingSignals = signals.where((signal) {
        final date = DateTime.tryParse(signal.dateKey);
        return date != null && inPeriod(date);
      });
      if (normalized.contains('water')) {
        final total = matchingSignals.fold<int>(
            0, (sum, signal) => sum + (signal.waterMl ?? 0));
        return '$prefix$total ml of water logged.';
      }
      final total = matchingSignals.fold<int>(
          0, (sum, signal) => sum + (signal.workoutMinutes ?? 0));
      return '$prefix$total minutes of exercise logged.';
    }

    if (normalized.contains('mood') ||
        normalized.contains('feel') ||
        normalized.contains('happy')) {
      final matchingMoods = moods.where((mood) => inPeriod(mood.date)).toList();
      if (matchingMoods.isEmpty) {
        return '${prefix}No mood check-ins were logged.';
      }
      final counts = <String, int>{};
      for (final mood in matchingMoods) {
        counts.update(mood.mood, (count) => count + 1, ifAbsent: () => 1);
      }
      final common =
          counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final label = moodOptionFor(common.key).label;
      return '$prefix$label was your most logged mood '
          '(${common.value} of ${matchingMoods.length} check-ins).';
    }

    if (normalized.contains('task') || normalized.contains('overdue')) {
      final matchingTasks = tasks.where((task) {
        if (task.completed || task.dueDate == null) return false;
        if (normalized.contains('overdue')) {
          return _dateOnly(task.dueDate!).isBefore(reference);
        }
        return inPeriod(task.dueDate!);
      }).length;
      return normalized.contains('overdue')
          ? '$matchingTasks incomplete overdue ${matchingTasks == 1 ? 'task' : 'tasks'}.'
          : '$prefix$matchingTasks incomplete ${matchingTasks == 1 ? 'task is' : 'tasks are'} due.';
    }

    if (normalized.contains('cash flow') ||
        normalized.contains('spent') ||
        normalized.contains('expense') ||
        normalized.contains('income') ||
        normalized.contains('money')) {
      var income = 0.0;
      var expense = 0.0;
      for (final transaction
          in transactions.where((item) => inPeriod(item.date))) {
        if (transaction.type == TxType.income) {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }
      final net = income - expense;
      return '${prefix}Income $currency ${income.toStringAsFixed(2)}, '
          'expenses $currency ${expense.toStringAsFixed(2)}, '
          'net $currency ${net.toStringAsFixed(2)}.';
    }

    return 'I can report tracked exercise minutes, water, mood, tasks, and '
        'income/expenses. Try “exercise minutes last week” or “cash flow '
        'this month”.';
  }

  static ReportPeriod _periodFor(String query, DateTime today) {
    if (query.contains('last week') || query.contains('previous week')) {
      final thisMonday =
          today.subtract(Duration(days: today.weekday - DateTime.monday));
      final start = thisMonday.subtract(const Duration(days: 7));
      return ReportPeriod(start, thisMonday, 'Last week');
    }
    if (query.contains('this week')) {
      final start =
          today.subtract(Duration(days: today.weekday - DateTime.monday));
      return ReportPeriod(
          start, today.add(const Duration(days: 1)), 'This week');
    }
    if (query.contains('last month') || query.contains('previous month')) {
      final start = DateTime(today.year, today.month - 1);
      return ReportPeriod(
          start, DateTime(today.year, today.month), 'Last month');
    }
    if (query.contains('this month')) {
      return ReportPeriod(
        DateTime(today.year, today.month),
        today.add(const Duration(days: 1)),
        'This month',
      );
    }
    const months = <String, int>{
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    for (final entry in months.entries) {
      if (query.contains(entry.key)) {
        final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(query);
        final year =
            yearMatch == null ? today.year : int.parse(yearMatch.group(1)!);
        return ReportPeriod(
          DateTime(year, entry.value),
          DateTime(year, entry.value + 1),
          '${entry.key[0].toUpperCase()}${entry.key.substring(1)} $year',
        );
      }
    }
    return ReportPeriod(
      DateTime(today.year, today.month, today.day),
      today.add(const Duration(days: 1)),
      'Today',
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _average(List<int> values) => values.isEmpty
      ? 'not available'
      : (values.reduce((a, b) => a + b) / values.length).toStringAsFixed(1);

  static String _averageDecimal(List<double> values) => values.isEmpty
      ? 'not available'
      : (values.reduce((a, b) => a + b) / values.length).toStringAsFixed(1);

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
