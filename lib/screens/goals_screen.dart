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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final active = app.goals.where((g) => !g.completed).toList();
    final completed = app.goals.where((g) => g.completed).toList();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          if (app.goals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${active.length} active',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddGoalScreen())),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 90 + bottomInset),
        children: [
          if (active.isEmpty && completed.isEmpty)
            _EmptyGoalsState(colors: colors),
          ...active.map((g) => _GoalCard(goal: g)),
          if (completed.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: Text(
                'Completed',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...completed.map((g) => _GoalCard(goal: g)),
          ],
        ],
      ),
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  final ColorScheme colors;

  const _EmptyGoalsState({required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flag_rounded,
              size: 38,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Make room for what matters',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a goal and turn a good intention into your next small win.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        child: Icon(Icons.delete_outline_rounded, color: colors.onError),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            decoration: goal.completed
                                ? TextDecoration.lineThrough
                                : null,
                          )),
                    ),
                    if (goal.completed)
                      Icon(Icons.check_circle_rounded, color: colors.primary),
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
                            ? ' · ${-days} day${-days == 1 ? '' : 's'} overdue'
                            : days == 0
                                ? ' · due today'
                                : ' · $days day${days == 1 ? '' : 's'} left';
                    return Text(
                      'Target: ${formatDate(goal.targetDate!)}$daysLabel',
                      style: TextStyle(
                        color: (!goal.completed && days < 0)
                            ? colors.error
                            : colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: goal.progress / 100,
                    minHeight: 8,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      goal.completed ? 'Complete' : 'Progress',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${goal.progress}%',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
