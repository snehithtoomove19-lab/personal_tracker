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
  final order = {
    TaskPriority.high: 0,
    TaskPriority.medium: 1,
    TaskPriority.low: 2,
  };

  final copy = [...tasks];

  copy.sort((a, b) {
    final priorityComparison = order[a.priority]!.compareTo(order[b.priority]!);

    if (priorityComparison != 0) {
      return priorityComparison;
    }

    // If priorities are equal, sort by due date.
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

    final overdue = _sortByPriority(app.overdueTasks);

    final today = _sortByPriority(app.todayTasks);

    final upcoming = _sortByPriority(
      app.tasks.where((task) {
        if (task.completed || task.dueDate == null) {
          return false;
        }

        final due = task.dueDate!;

        return due.isAfter(now) && !_sameDay(due, now);
      }).toList(),
    );

    // Sort upcoming by actual due date first.
    upcoming.sort((a, b) {
      final dateComparison = a.dueDate!.compareTo(b.dueDate!);

      if (dateComparison != 0) {
        return dateComparison;
      }

      final order = {
        TaskPriority.high: 0,
        TaskPriority.medium: 1,
        TaskPriority.low: 2,
      };

      return order[a.priority]!.compareTo(order[b.priority]!);
    });

    final noDate = _sortByPriority(
      app.tasks
          .where(
            (task) => !task.completed && task.dueDate == null,
          )
          .toList(),
    );

    final completed = app.tasks.where((task) => task.completed).toList();

    final activeCount = app.tasks.where((task) => !task.completed).length;

    final completedCount = completed.length;

    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

    return Scaffold(
      backgroundColor: colors.surface,

      // ======================================================================
      // FAB
      // ======================================================================

      floatingActionButton: FloatingActionButton.extended(
        elevation: 5,
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

          const SizedBox(height: 18),

          // ==================================================================
          // QUICK SUMMARY
          // ==================================================================

          if (app.tasks.isNotEmpty)
            _buildSummaryCard(
              context,
              activeCount,
              completedCount,
              overdue.length,
            ),

          if (app.tasks.isNotEmpty) const SizedBox(height: 16),

          // ==================================================================
          // DELETE HINT
          // ==================================================================

          if (app.tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 4,
                bottom: 10,
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
                    'Swipe left to delete a task',
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

          if (completed.isNotEmpty)
            _TaskSection(
              title: 'Completed',
              subtitle:
                  '${completed.length} task${completed.length == 1 ? '' : 's'} finished',
              tasks: completed,
              color: Colors.green,
              icon: Icons.task_alt_rounded,
              faded: true,
            ),

          // ==================================================================
          // EMPTY STATE
          // ==================================================================

          if (app.tasks.isEmpty) _buildEmptyState(context),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'My Tasks',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
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

        // Completed counter
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.13),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: colors.primary,
                size: 22,
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
  // SUMMARY
  // ==========================================================================

  Widget _buildSummaryCard(
    BuildContext context,
    int activeCount,
    int completedCount,
    int overdueCount,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final total = activeCount + completedCount;

    final progress = total == 0 ? 0.0 : completedCount / total;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.10),
            colors.secondary.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.11),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: colors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Progress',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
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
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: colors.primary.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                colors.primary,
              ),
            ),
          ),
          if (overdueCount > 0) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 15,
                  color: Colors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  '$overdueCount overdue task'
                  '${overdueCount == 1 ? '' : 's'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
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
  // EMPTY STATE
  // ==========================================================================

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 35),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt_rounded,
              size: 38,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first task and start organizing your day.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
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
            label: const Text('Create Task'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SAME DAY
  // ==========================================================================

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section heading
          Padding(
            padding: const EdgeInsets.only(
              left: 3,
              right: 3,
              bottom: 9,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
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

          // Task container
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: colors.outlineVariant.withValues(
                  alpha: 0.65,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.018),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
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

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,

      // ======================================================================
      // DELETE BACKGROUND
      // ======================================================================

      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      // ======================================================================
      // DELETE
      // ======================================================================

      onDismissed: (_) {
        final removed = task;

        app.deleteTask(task.id);

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
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
      // TILE
      // ======================================================================

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
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ==========================================================
                  // CHECKBOX
                  // ==========================================================

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

                  const SizedBox(width: 5),

                  // ==========================================================
                  // TASK CONTENT
                  // ==========================================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
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

                  const SizedBox(width: 5),

                  // ==========================================================
                  // EDIT BUTTON
                  // ==========================================================

                  IconButton(
                    tooltip: 'Edit task',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 19,
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
                    right: 0,
                    top: 12,
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
          color: color.withValues(alpha: 0.12),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_rounded,
              size: 13,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              formatDate(task.dueDate!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

      // ----------------------------------------------------------------------
      // DUE TIME
      // ----------------------------------------------------------------------

      if (task.dueTimeMinutes != null) {
        parts.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formatMinutes(
                  task.dueTimeMinutes!,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    }

    // ------------------------------------------------------------------------
    // CATEGORY
    // ------------------------------------------------------------------------

    if (task.category.isNotEmpty) {
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline_rounded,
              size: 13,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                task.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------------------
    // REPEAT
    // ------------------------------------------------------------------------

    if (task.repeat != TaskRepeat.none) {
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.repeat_rounded,
              size: 13,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Repeats ${task.repeat.name}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------------------
    // SUBTASKS
    // ------------------------------------------------------------------------

    if (task.subtasks.isNotEmpty) {
      final completedSubtasks =
          task.subtasks.where((subtask) => subtask.completed).length;

      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 13,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '$completedSubtasks/${task.subtasks.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------------------
    // NO DETAILS
    // ------------------------------------------------------------------------

    if (parts.isEmpty) {
      return Text(
        'No additional details',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    // ------------------------------------------------------------------------
    // METADATA
    // ------------------------------------------------------------------------

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: parts,
    );
  }
}
