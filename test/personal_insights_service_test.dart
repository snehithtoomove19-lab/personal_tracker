import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/day_signals.dart';
import 'package:personal_tracker/models/mood_entry.dart';
import 'package:personal_tracker/models/task.dart';
import 'package:personal_tracker/models/transaction.dart';
import 'package:personal_tracker/services/personal_insights_service.dart';

void main() {
  final now = DateTime(2026, 3, 11, 12);

  test('exercise report uses the previous calendar week', () {
    final result = PersonalInsightsService.answerQuery(
      query: 'How many minutes did I exercise last week?',
      transactions: const [],
      moods: const [],
      tasks: const [],
      signals: const [
        DaySignals(dateKey: '2026-03-02', workoutMinutes: 20),
        DaySignals(dateKey: '2026-03-08', workoutMinutes: 35),
        DaySignals(dateKey: '2026-03-09', workoutMinutes: 90),
      ],
      now: now,
    );

    expect(result, 'Last week: 55 minutes of exercise logged.');
  });

  test('cash-flow report totals the requested month', () {
    final result = PersonalInsightsService.answerQuery(
      query: 'Give me a summary of my cash flow for March 2026',
      transactions: [
        AppTransaction(
          id: 'income',
          type: TxType.income,
          amount: 1000,
          category: 'Salary',
          date: DateTime(2026, 3, 1),
        ),
        AppTransaction(
          id: 'expense',
          type: TxType.expense,
          amount: 250,
          category: 'Food',
          date: DateTime(2026, 3, 10),
        ),
        AppTransaction(
          id: 'other-month',
          type: TxType.expense,
          amount: 100,
          category: 'Food',
          date: DateTime(2026, 2, 28),
        ),
      ],
      moods: const [],
      tasks: const [],
      signals: const [],
      currency: '\$',
      now: now,
    );

    expect(result, contains('Income \$ 1000.00'));
    expect(result, contains('expenses \$ 250.00'));
    expect(result, contains('net \$ 750.00'));
  });

  test('mood forecast needs three observations and reports the recent mode',
      () {
    final moods = [
      MoodEntry(id: '1', date: DateTime(2026, 3, 10), mood: 'good'),
      MoodEntry(id: '2', date: DateTime(2026, 3, 9), mood: 'good'),
      MoodEntry(id: '3', date: DateTime(2026, 3, 8), mood: 'low'),
    ];
    final forecast = PersonalInsightsService.forecast(
      moods: moods,
      signals: const [],
      tasks: const [],
      now: now,
    );

    expect(forecast.likelyMood, 'good');
    expect(forecast.moodObservations, 3);
    expect(forecast.estimatedCapacity, isNull);
  });

  test('present alerts report overdue tasks and tracked budget overruns', () {
    final alerts = PersonalInsightsService.alerts(
      tasks: [
        AppTask(
          id: 'late',
          title: 'Late',
          dueDate: DateTime(2026, 3, 10),
          createdAt: DateTime(2026, 3, 1),
        ),
      ],
      signals: const [],
      overBudgetCategories: const {
        'Food': [130, 100],
      },
      todayExpense: 0,
      transactions: const [],
      now: now,
    );

    expect(alerts.map((alert) => alert.title), [
      '1 overdue task',
      'Food is over budget',
    ]);
  });

  test('AI context uses recent aggregates and excludes raw personal details',
      () {
    final context = PersonalInsightsService.buildAiContext(
      transactions: [
        AppTransaction(
          id: 'income',
          type: TxType.income,
          amount: 800,
          category: 'Salary',
          note: 'private income note',
          merchant: 'private employer',
          date: DateTime(2026, 3, 1),
        ),
        AppTransaction(
          id: 'expense',
          type: TxType.expense,
          amount: 120,
          category: 'Food',
          note: 'private purchase note',
          merchant: 'private cafe',
          date: DateTime(2026, 3, 2),
        ),
        AppTransaction(
          id: 'old',
          type: TxType.expense,
          amount: 900,
          category: 'Other',
          date: DateTime(2026, 2, 1),
        ),
      ],
      moods: [
        MoodEntry(
          id: 'mood',
          date: DateTime(2026, 3, 3),
          mood: 'good',
          note: 'private mood note',
        ),
      ],
      tasks: [
        AppTask(
          id: 'late',
          title: 'Private overdue task title',
          dueDate: DateTime(2026, 3, 1),
          createdAt: DateTime(2026, 2, 1),
        ),
        AppTask(
          id: 'soon',
          title: 'Private upcoming task title',
          dueDate: DateTime(2026, 3, 13),
          createdAt: DateTime(2026, 3, 1),
        ),
      ],
      signals: const [
        DaySignals(
          dateKey: '2026-03-05',
          sleepQuality: 4,
          meetingHours: 2,
          workoutMinutes: 20,
          waterMl: 700,
        ),
        DaySignals(
          dateKey: '2026-02-01',
          sleepQuality: 1,
          meetingHours: 8,
          workoutMinutes: 500,
          waterMl: 9000,
        ),
      ],
      currency: '\$',
      now: now,
    );

    expect(context, contains('income \$ 800.00'));
    expect(context, contains('expenses \$ 120.00'));
    expect(context, contains('net \$ 680.00'));
    expect(context, contains('exercise 20 minutes'));
    expect(context, contains('water 700 ml'));
    expect(context, contains('sleep quality average 4.0 from 1'));
    expect(context, contains('meeting hours average 2.0 from 1'));
    expect(context, contains('Tasks: 1 overdue and 1 due'));
    expect(context, isNot(contains('private')));
    expect(context, isNot(contains('900.00')));
    expect(context, isNot(contains('9000')));
  });
}
