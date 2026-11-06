import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/task.dart';
import 'package:personal_tracker/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('monthly end-of-month tasks retain date and reset subtasks', () async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    final task = AppTask(
      id: 'monthly',
      title: 'Monthly review',
      description: 'Review the month',
      dueDate: DateTime(2026, 1, 31),
      dueTimeMinutes: 10 * 60,
      createdAt: DateTime(2026, 1, 1),
      pinned: true,
      priority: TaskPriority.high,
      category: 'Personal',
      repeat: TaskRepeat.monthly,
      reminderEnabled: true,
      subtasks: [
        SubTask(id: 'old-subtask', title: 'Review notes', completed: true),
      ],
    );

    await app.addTask(task);
    await app.toggleTask(task.id);

    final februaryTask = app.tasks.singleWhere((item) => !item.completed);
    expect(februaryTask.dueDate, DateTime(2026, 2, 28));
    expect(februaryTask.pinned, isTrue);
    expect(februaryTask.priority, TaskPriority.high);
    expect(februaryTask.reminderEnabled, isTrue);
    expect(februaryTask.subtasks, hasLength(1));
    expect(februaryTask.subtasks.single.title, 'Review notes');
    expect(februaryTask.subtasks.single.completed, isFalse);
    expect(februaryTask.subtasks.single.id, isNot('old-subtask'));

    await app.toggleTask(februaryTask.id);
    final marchTask = app.tasks.singleWhere((item) => !item.completed);
    expect(marchTask.dueDate, DateTime(2026, 3, 31));
    app.dispose();
  });
}
