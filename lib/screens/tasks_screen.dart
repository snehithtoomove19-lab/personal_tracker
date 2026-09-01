import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../models/task.dart';
import '../utils/formatters.dart';
import 'add_task_screen.dart';

// ============================================================================
// TASK HELPERS
// ============================================================================

Color priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return Colors.red;
    case TaskPriority.medium:
      return Colors.orange;
    case TaskPriority.low:
      return Colors.green;
  }
}

String priorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'High';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.low:
      return 'Low';
  }
}

IconData priorityIcon(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return Icons.priority_high_rounded;
    case TaskPriority.medium:
      return Icons.remove_rounded;
    case TaskPriority.low:
      return Icons.keyboard_arrow_down_rounded;
  }
}

List<AppTask> _sortByPriority(List<AppTask> tasks) {
  final order = <TaskPriority, int>{
    TaskPriority.high: 0,
    TaskPriority.medium: 1,
    TaskPriority.low: 2,
  };

  final copy = [...tasks];

  copy.sort((a, b) {
    final priorityA = order[a.priority] ?? 99;
    final priorityB = order[b.priority] ?? 99;

    final priorityComparison = priorityA.compareTo(priorityB);

    if (priorityComparison != 0) {
      return priorityComparison;
    }

    if (a.dueDate != null && b.dueDate != null) {
      return a.dueDate!.compareTo(b.dueDate!);
    }

    if (a.dueDate != null) {
      return -1;
    }

    if (b.dueDate != null) {
      return 1;
    }

    return 0;
  });

  return copy;
}

String _formatMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;

  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;

  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// ============================================================================
// TASKS SCREEN
// ============================================================================

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);

    final now = DateTime.now();

    final allTasks = app.tasks;

    final activeTasks = allTasks.where((task) => !task.completed).toList();

    final completedTasks = allTasks.where((task) => task.completed).toList();

    final overdue = _sortByPriority(
      app.overdueTasks,
    );

    final today = _sortByPriority(
      app.todayTasks,
    );

    final upcoming = allTasks.where((task) {
      if (task.completed || task.dueDate == null) {
        return false;
      }

      final due = task.dueDate!;

      return due.isAfter(now) && !_sameDay(due, now);
    }).toList();

    upcoming.sort((a, b) {
      if (a.dueDate == null || b.dueDate == null) {
        return 0;
      }

      final dateComparison = a.dueDate!.compareTo(b.dueDate!);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return priorityColor(a.priority)
          .value
          .compareTo(priorityColor(b.priority).value);
    });

    final noDate = _sortByPriority(
      allTasks
          .where(
            (task) => !task.completed && task.dueDate == null,
          )
          .toList(),
    );

    final activeCount = activeTasks.length;
    final completedCount = completedTasks.length;
    final totalCount = allTasks.length;

    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    final bottomPadding = MediaQuery.of(context).padding.bottom + 110;

    return Scaffold(
      backgroundColor: colors.surface,

      // ======================================================================
      // FAB
      // ======================================================================

      floatingActionButton: FloatingActionButton.extended(
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTaskScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Task',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // ======================================================================
      // BODY
      // ======================================================================

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          bottomPadding,
        ),
        children: [
          // ==================================================================
          // HEADER
          // ==================================================================

          _buildHeader(
            context,
            activeCount,
            completedCount,
          ),

          const SizedBox(height: 20),

          // ==================================================================
          // OVERVIEW CARD
          // ==================================================================

          if (allTasks.isNotEmpty)
            _buildOverviewCard(
              context,
              activeCount: activeCount,
              completedCount: completedCount,
              overdueCount: overdue.length,
              progress: progress,
            ),

          if (allTasks.isNotEmpty) const SizedBox(height: 18),

          // ==================================================================
          // QUICK STATS
          // ==================================================================

          if (allTasks.isNotEmpty)
            _buildQuickStats(
              context,
              activeCount: activeCount,
              completedCount: completedCount,
              overdueCount: overdue.length,
            ),

          if (allTasks.isNotEmpty) const SizedBox(height: 18),

          // ==================================================================
          // DELETE HINT
          // ==================================================================

          if (allTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 5,
                bottom: 11,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swipe_left_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe left to delete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ==================================================================
          // OVERDUE
          // ==================================================================

          if (overdue.isNotEmpty)
            _TaskSection(
              title: 'Overdue',
              subtitle:
                  '${overdue.length} task${overdue.length == 1 ? '' : 's'} need attention',
              tasks: overdue,
              color: Colors.red,
              icon: Icons.warning_amber_rounded,
            ),

          // ==================================================================
          // TODAY
          // ==================================================================

          if (today.isNotEmpty)
            _TaskSection(
              title: 'Today',
              subtitle:
                  '${today.length} task${today.length == 1 ? '' : 's'} for today',
              tasks: today,
              color: colors.primary,
              icon: Icons.today_rounded,
            ),

          // ==================================================================
          // UPCOMING
          // ==================================================================

          if (upcoming.isNotEmpty)
            _TaskSection(
              title: 'Upcoming',
              subtitle:
                  '${upcoming.length} upcoming task${upcoming.length == 1 ? '' : 's'}',
              tasks: upcoming,
              color: Colors.deepPurple,
              icon: Icons.upcoming_rounded,
            ),

          // ==================================================================
          // NO DATE
          // ==================================================================

          if (noDate.isNotEmpty)
            _TaskSection(
              title: 'No Due Date',
              subtitle:
                  '${noDate.length} task${noDate.length == 1 ? '' : 's'} without a deadline',
              tasks: noDate,
              color: Colors.blueGrey,
              icon: Icons.event_busy_rounded,
            ),

          // ==================================================================
          // COMPLETED
          // ==================================================================

          if (completedTasks.isNotEmpty)
            _TaskSection(
              title: 'Completed',
              subtitle:
                  '${completedTasks.length} task${completedTasks.length == 1 ? '' : 's'} finished',
              tasks: completedTasks,
              color: Colors.green,
              icon: Icons.task_alt_rounded,
              faded: true,
            ),

          // ==================================================================
          // EMPTY
          // ==================================================================

          if (allTasks.isEmpty) _buildEmptyState(context),
        ],
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader(
    BuildContext context,
    int activeCount,
    int completedCount,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stay organized',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'My Tasks',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                activeCount == 0
                    ? 'Everything is done. Great job!'
                    : '$activeCount active task'
                        '${activeCount == 1 ? '' : 's'} to focus on',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.13),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: colors.primary,
                size: 23,
              ),
              const SizedBox(height: 3),
              Text(
                '$completedCount',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              Text(
                'done',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // OVERVIEW
  // ==========================================================================

  Widget _buildOverviewCard(
    BuildContext context, {
    required int activeCount,
    required int completedCount,
    required int overdueCount,
    required double progress,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final total = activeCount + completedCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.12),
            colors.secondary.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: colors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Progress',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedCount of $total completed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.primary.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                colors.primary,
              ),
            ),
          ),
          if (overdueCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '$overdueCount overdue task'
                  '${overdueCount == 1 ? '' : 's'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // QUICK STATS
  // ==========================================================================

  Widget _buildQuickStats(
    BuildContext context, {
    required int activeCount,
    required int completedCount,
    required int overdueCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Active',
            value: '$activeCount',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Done',
            value: '$completedCount',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _StatCard(
            icon: Icons.warning_amber_rounded,
            label: 'Overdue',
            value: '$overdueCount',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // EMPTY STATE
  // ==========================================================================

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 35),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt_rounded,
              size: 40,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No tasks yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Add your first task and start organizing your day.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTaskScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Create Task',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STAT CARD
// ============================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TASK SECTION
// ============================================================================

class _TaskSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AppTask> tasks;
  final Color color;
  final IconData icon;
  final bool faded;

  const _TaskSection({
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.color,
    required this.icon,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 3,
              right: 3,
              bottom: 9,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: color,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: faded
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================================================================
          // TASK LIST CONTAINER
          // ==================================================================

          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.65),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.018),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  for (int i = 0; i < tasks.length; i++)
                    _TaskTile(
                      task: tasks[i],
                      faded: faded,
                      showDivider: i != tasks.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TASK TILE
// ============================================================================

class _TaskTile extends StatelessWidget {
  final AppTask task;
  final bool faded;
  final bool showDivider;

  const _TaskTile({
    required this.task,
    this.faded = false,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);

    final completed = task.completed;
    final priority = priorityColor(task.priority);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,

      // ======================================================================
      // DELETE BACKGROUND
      // ======================================================================

      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(
          right: 22,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 23,
            ),
            SizedBox(height: 2),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),

      // ======================================================================
      // DELETE ACTION
      // ======================================================================

      onDismissed: (_) {
        final removed = task;

        app.deleteTask(task.id);

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Deleted "${removed.title}"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  app.addTask(removed);
                },
              ),
            ),
          );
      },

      // ======================================================================
      // TASK CONTENT
      // ======================================================================

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTaskScreen(
                  existing: task,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              9,
              11,
              8,
              11,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ========================================================
                    // CHECKBOX
                    // ========================================================

                    Checkbox(
                      value: completed,
                      onChanged: (_) {
                        app.toggleTask(task.id);
                      },
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // ========================================================
                    // TASK CONTENT
                    // ========================================================

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: faded
                                        ? colors.onSurfaceVariant
                                        : colors.onSurface,
                                    decoration: completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationThickness: 1.5,
                                  ),
                                ),
                              ),
                              if (!completed) ...[
                                const SizedBox(width: 7),
                                _PriorityBadge(
                                  priority: task.priority,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          _TaskMetadata(
                            task: task,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 3),

                    // ========================================================
                    // EDIT
                    // ========================================================

                    IconButton(
                      tooltip: 'Edit task',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTaskScreen(
                              existing: task,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // ============================================================
                // DIVIDER
                // ============================================================

                if (showDivider)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 48,
                      top: 11,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 0.7,
                      color: colors.outlineVariant.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PRIORITY BADGE
// ============================================================================

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    final label = priorityLabel(priority);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priorityIcon(priority),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TASK METADATA
// ============================================================================

class _TaskMetadata extends StatelessWidget {
  final AppTask task;

  const _TaskMetadata({
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final parts = <Widget>[];

    // ------------------------------------------------------------------------
    // DUE DATE
    // ------------------------------------------------------------------------

    if (task.dueDate != null) {
      parts.add(
        _MetadataItem(
          icon: Icons.event_rounded,
          text: formatDate(task.dueDate!),
        ),
      );

      // ----------------------------------------------------------------------
      // DUE TIME
      // ----------------------------------------------------------------------

      if (task.dueTimeMinutes != null) {
        parts.add(
          _MetadataItem(
            icon: Icons.schedule_rounded,
            text: _formatMinutes(
              task.dueTimeMinutes!,
            ),
          ),
        );
      }
    }

    // ------------------------------------------------------------------------
    // CATEGORY
    // ------------------------------------------------------------------------

    if (task.category.isNotEmpty) {
      parts.add(
        _MetadataItem(
          icon: Icons.label_outline_rounded,
          text: task.category,
        ),
      );
    }

    // ------------------------------------------------------------------------
    // REPEAT
    // ------------------------------------------------------------------------

    if (task.repeat != TaskRepeat.none) {
      parts.add(
        _MetadataItem(
          icon: Icons.repeat_rounded,
          text: 'Repeats ${task.repeat.name}',
        ),
      );
    }

    // ------------------------------------------------------------------------
    // SUBTASKS
    // ------------------------------------------------------------------------

    if (task.subtasks.isNotEmpty) {
      final completedSubtasks = task.subtasks
          .where(
            (subtask) => subtask.completed,
          )
          .length;

      parts.add(
        _MetadataItem(
          icon: Icons.checklist_rounded,
          text: '$completedSubtasks/${task.subtasks.length}',
        ),
      );
    }

    // ------------------------------------------------------------------------
    // EMPTY
    // ------------------------------------------------------------------------

    if (parts.isEmpty) {
      return Text(
        'No additional details',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: parts,
    );
  }
}

// ============================================================================
// METADATA ITEM
// ============================================================================

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetadataItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 170,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
