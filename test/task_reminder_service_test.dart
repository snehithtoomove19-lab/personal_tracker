import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/task.dart';
import 'package:personal_tracker/services/task_reminder_service.dart';

void main() {
  final now = DateTime(2026, 3, 10, 8);

  test('uses 9:00 AM when a reminder has no selected time', () {
    final task = AppTask(
      id: 'morning',
      title: 'Morning check-in',
      dueDate: DateTime(2026, 3, 10),
      createdAt: now,
      reminderEnabled: true,
    );

    expect(
      TaskReminderService.plannedTime(task, now: now),
      DateTime(2026, 3, 10, 9),
    );
  });

  test('uses the task time when one was selected', () {
    final task = AppTask(
      id: 'meeting',
      title: 'Review',
      dueDate: DateTime(2026, 3, 10),
      dueTimeMinutes: 14 * 60 + 30,
      createdAt: now,
      reminderEnabled: true,
    );

    expect(
      TaskReminderService.plannedTime(task, now: now),
      DateTime(2026, 3, 10, 14, 30),
    );
  });

  test('does not schedule disabled, completed, or past reminders', () {
    final baseTask = AppTask(
      id: 'task',
      title: 'Task',
      dueDate: DateTime(2026, 3, 10, 7),
      dueTimeMinutes: 7 * 60,
      createdAt: now,
      reminderEnabled: true,
    );

    expect(TaskReminderService.plannedTime(baseTask, now: now), isNull);
    expect(
      TaskReminderService.plannedTime(
        AppTask(
          id: 'disabled',
          title: 'Disabled',
          dueDate: DateTime(2026, 3, 10),
          createdAt: now,
        ),
        now: now,
      ),
      isNull,
    );
    expect(
      TaskReminderService.plannedTime(
        AppTask(
          id: 'completed',
          title: 'Completed',
          dueDate: DateTime(2026, 3, 11),
          createdAt: now,
          reminderEnabled: true,
          completed: true,
        ),
        now: now,
      ),
      isNull,
    );
  });

  test('notification identifiers are stable and fit the platform range', () {
    final first = TaskReminderService.notificationIdForTask('same-task');

    expect(first, TaskReminderService.notificationIdForTask('same-task'));
    expect(first, greaterThanOrEqualTo(0));
    expect(first, lessThanOrEqualTo(0x7fffffff));
    expect(first, isNot(TaskReminderService.notificationIdForTask('other')));
  });
}
