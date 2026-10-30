import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/day_signals.dart';
import 'package:personal_tracker/models/mood_entry.dart';
import 'package:personal_tracker/models/task.dart';
import 'package:personal_tracker/services/personal_insights_service.dart';

void main() {
  final now = DateTime(2026, 3, 11, 12);

  test('exercise report uses the previous calendar week', () {
    final result = PersonalInsightsService.answerQuery(
      query: 'How many minutes did I exercise last week?',
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

  test('present alerts report overdue tasks', () {
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
      now: now,
    );

    expect(alerts.map((alert) => alert.title), ['1 overdue task']);
  });

  test('AI context uses aggregates and excludes raw personal details', () {
    final context = PersonalInsightsService.buildAiContext(
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
      now: now,
    );

    expect(context, contains('exercise 20 minutes'));
    expect(context, contains('water 700 ml'));
    expect(context, contains('sleep quality average 4.0 from 1'));
    expect(context, contains('meeting hours average 2.0 from 1'));
    expect(context, contains('Tasks: 1 overdue and 1 due'));
    expect(context, isNot(contains('private')));
    expect(context, isNot(contains('9000')));
  });

  test('local reports do not offer removed cash-flow tracking', () {
    final result = PersonalInsightsService.answerQuery(
      query: 'Give me a summary of my cash flow for March 2026',
      moods: const [],
      tasks: const [],
      signals: const [],
      now: now,
    );

    expect(result, contains('exercise minutes, water, mood, tasks, and goals'));
    expect(result, isNot(contains('cash flow')));
  });
}
