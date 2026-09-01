import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/goal.dart';
import '../utils/formatters.dart';
import 'add_goal_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final active = app.goals.where((g) => !g.completed).toList();
    final completed = app.goals.where((g) => g.completed).toList();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddGoalScreen())),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 90 + bottomInset),
        children: [
          if (active.isEmpty && completed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                  child: Text('No goals yet Ã¢â‚¬â€ tap + to add one',
                      style: TextStyle(color: Colors.grey.shade600))),
            ),
          ...active.map((g) => _GoalCard(goal: g)),
          if (completed.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Completed',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...completed.map((g) => _GoalCard(goal: g)),
          ],
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final AppGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        final removed = goal;
        app.deleteGoal(goal.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${removed.title}"'),
            action: SnackBarAction(
                label: 'Undo', onPressed: () => app.addGoal(removed)),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AddGoalScreen(existing: goal))),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(goal.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: goal.completed
                                  ? TextDecoration.lineThrough
                                  : null)),
                    ),
                    if (goal.completed)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                if (goal.targetDate != null) ...[
                  const SizedBox(height: 4),
                  Builder(builder: (context) {
                    final days = goal.targetDate!
                        .difference(DateTime(DateTime.now().year,
                            DateTime.now().month, DateTime.now().day))
                        .inDays;
                    final daysLabel = goal.completed
                        ? ''
                        : days < 0
                            ? ' Ã‚Â· ${-days} day${-days == 1 ? '' : 's'} overdue'
                            : days == 0
                                ? ' Ã‚Â· due today'
                                : ' Ã‚Â· $days day${days == 1 ? '' : 's'} left';
                    return Text(
                      'Target: ${formatDate(goal.targetDate!)}$daysLabel',
                      style: TextStyle(
                        color: (!goal.completed && days < 0)
                            ? Colors.red
                            : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                      value: goal.progress / 100, minHeight: 10),
                ),
                const SizedBox(height: 6),
                Text('${goal.progress}%',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
