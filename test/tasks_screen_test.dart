import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/task.dart';
import 'package:personal_tracker/screens/tasks_screen.dart';
import 'package:personal_tracker/services/app_scope.dart';
import 'package:personal_tracker/services/app_state.dart';
import 'package:personal_tracker/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('upcoming tasks sort by due date then priority', (tester) async {
    final app = AppState();
    final today = DateTime.now();
    final earlier = DateTime(today.year, today.month, today.day + 2);
    final later = DateTime(today.year, today.month, today.day + 4);

    app.tasks.addAll([
      AppTask(
        id: 'later-high',
        title: 'Later high priority',
        dueDate: later,
        priority: TaskPriority.high,
        createdAt: today,
      ),
      AppTask(
        id: 'earlier-low',
        title: 'Earlier low priority',
        dueDate: earlier,
        priority: TaskPriority.low,
        createdAt: today,
      ),
      AppTask(
        id: 'later-low',
        title: 'Later low priority',
        dueDate: later,
        priority: TaskPriority.low,
        createdAt: today,
      ),
      AppTask(
        id: 'later-medium',
        title: 'Later medium priority',
        dueDate: later,
        priority: TaskPriority.medium,
        createdAt: today,
      ),
    ]);

    await tester.pumpWidget(
      AppScope(
        appState: app,
        child: MaterialApp(
          theme: buildAppTheme(
            preset: AppThemePreset.pulse,
            darkMode: false,
          ),
          home: const TasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final earlierY = tester.getTopLeft(find.text('Earlier low priority')).dy;
    final highY = tester.getTopLeft(find.text('Later high priority')).dy;
    final mediumY = tester.getTopLeft(find.text('Later medium priority')).dy;
    final lowY = tester.getTopLeft(find.text('Later low priority')).dy;

    expect(earlierY, lessThan(highY));
    expect(highY, lessThan(mediumY));
    expect(mediumY, lessThan(lowY));
    app.dispose();
  });
}
