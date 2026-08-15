import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/task.dart';
import '../utils/formatters.dart';
import 'add_task_screen.dart';

Color priorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return Colors.red;
    case TaskPriority.medium:
      return Colors.orange;
    case TaskPriority.low:
      return Colors.green;
  }
}

String priorityLabel(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return 'High';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.low:
      return 'Low';
  }
}

List<AppTask> _sortByPriority(List<AppTask> tasks) {
  final order = {TaskPriority.high: 0, TaskPriority.medium: 1, TaskPriority.low: 2};
  final copy = [...tasks];
  copy.sort((a, b) => order[a.priority]!.compareTo(order[b.priority]!));
  return copy;
}

String _formatMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final overdue = _sortByPriority(app.overdueTasks);
    final today = _sortByPriority(app.todayTasks);
    final upcoming = _sortByPriority(app.tasks
        .where((t) => !t.completed && t.dueDate != null && t.dueDate!.isAfter(DateTime.now()) && !today.contains(t))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)));
    final noDate = _sortByPriority(app.tasks.where((t) => !t.completed && t.dueDate == null).toList());
    final completed = app.tasks.where((t) => t.completed).toList();

    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen())),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        children: [
          if (app.tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Swipe a task left to delete', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ),
          if (overdue.isNotEmpty) _TaskSection(title: 'Overdue', tasks: overdue, color: Colors.red),
          if (today.isNotEmpty) _TaskSection(title: 'Today', tasks: today, color: Colors.blue),
          if (upcoming.isNotEmpty) _TaskSection(title: 'Upcoming', tasks: upcoming),
          if (noDate.isNotEmpty) _TaskSection(title: 'No Due Date', tasks: noDate),
          if (completed.isNotEmpty) _TaskSection(title: 'Completed', tasks: completed, faded: true),
          if (app.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(child: Text('No tasks yet — tap + to add one', style: TextStyle(color: Colors.grey.shade600))),
            ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final String title;
  final List<AppTask> tasks;
  final Color? color;
  final bool faded;
  const _TaskSection({required this.title, required this.tasks, this.color, this.faded = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
          Card(
            child: Column(
              children: tasks.map((t) => _TaskTile(task: t, faded: faded)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final AppTask task;
  final bool faded;
  const _TaskTile({required this.task, this.faded = false});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        final removed = task;
        app.deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${removed.title}"'),
            action: SnackBarAction(label: 'Undo', onPressed: () => app.addTask(removed)),
          ),
        );
      },
      child: CheckboxListTile(
        value: task.completed,
        onChanged: (_) => app.toggleTask(task.id),
        controlAffinity: ListTileControlAffinity.leading,
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  decoration: task.completed ? TextDecoration.lineThrough : null,
                  color: faded ? Colors.grey : null,
                ),
              ),
            ),
            if (!task.completed)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor(task.priority).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priorityLabel(task.priority),
                  style: TextStyle(fontSize: 11, color: priorityColor(task.priority), fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        subtitle: (task.dueDate != null || task.description.isNotEmpty || task.subtasks.isNotEmpty)
            ? Text(
                [
                  if (task.dueDate != null)
                    formatDate(task.dueDate!) + (task.dueTimeMinutes != null ? ' · ${_formatMinutes(task.dueTimeMinutes!)}' : ''),
                  task.category,
                  if (task.repeat != TaskRepeat.none) 'Repeats ${task.repeat.name}',
                  if (task.subtasks.isNotEmpty)
                    '${task.subtasks.where((s) => s.completed).length}/${task.subtasks.length} checklist',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text(task.category, style: TextStyle(color: Colors.grey.shade600)),
        secondary: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(existing: task))),
        ),
      ),
    );
  }
}
