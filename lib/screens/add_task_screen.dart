import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/task.dart';
import '../utils/formatters.dart';

class AddTaskScreen extends StatefulWidget {
  final AppTask? existing;
  const AddTaskScreen({super.key, this.existing});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  TaskPriority _priority = TaskPriority.medium;
  String _category = kTaskCategories.first;
  TaskRepeat _repeat = TaskRepeat.none;
  bool _reminderEnabled = false;
  final List<SubTask> _subtasks = [];
  final _subtaskCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _dueDate = t.dueDate;
      _dueTime = t.dueTimeMinutes != null ? TimeOfDay(hour: t.dueTimeMinutes! ~/ 60, minute: t.dueTimeMinutes! % 60) : null;
      _priority = t.priority;
      _category = t.category;
      _repeat = t.repeat;
      _reminderEnabled = t.reminderEnabled;
      _subtasks.addAll(t.subtasks.map((s) => SubTask(id: s.id, title: s.title, completed: s.completed)));
    }
  }

  void _addSubtask() {
    final text = _subtaskCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(SubTask(id: DateTime.now().microsecondsSinceEpoch.toString(), title: text));
      _subtaskCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                app.deleteTask(widget.existing!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Task title'),
              autofocus: !isEditing,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description / notes (optional)', alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Checklist', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_subtasks.isNotEmpty)
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: _subtasks
                      .map((s) => CheckboxListTile(
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: s.completed,
                            title: Text(
                              s.title,
                              style: TextStyle(decoration: s.completed ? TextDecoration.lineThrough : null),
                            ),
                            onChanged: (v) => setState(() => s.completed = v ?? false),
                            secondary: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _subtasks.remove(s)),
                            ),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskCtrl,
                    decoration: const InputDecoration(hintText: 'Add a checklist item...'),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addSubtask),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date'),
              subtitle: Text(_dueDate != null ? formatDate(_dueDate!) : 'No due date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reminder time'),
              subtitle: Text(_dueTime != null ? _dueTime!.format(context) : 'No specific time'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _dueTime ?? TimeOfDay.now());
                if (picked != null) setState(() => _dueTime = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Remind me'),
              subtitle: const Text('Show this task in Reminders as it approaches'),
              value: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            const SizedBox(height: 8),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: kTaskCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: const [
                ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                ButtonSegment(value: TaskPriority.medium, label: Text('Medium')),
                ButtonSegment(value: TaskPriority.high, label: Text('High')),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 16),
            const Text('Repeat', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<TaskRepeat>(
              segments: const [
                ButtonSegment(value: TaskRepeat.none, label: Text('None')),
                ButtonSegment(value: TaskRepeat.daily, label: Text('Daily')),
                ButtonSegment(value: TaskRepeat.weekly, label: Text('Weekly')),
                ButtonSegment(value: TaskRepeat.monthly, label: Text('Monthly')),
              ],
              selected: {_repeat},
              onSelectionChanged: (s) => setState(() => _repeat = s.first),
              showSelectedIcon: false,
            ),
            if (_repeat != TaskRepeat.none)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'When you complete this task, the next occurrence is created automatically.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_titleCtrl.text.trim().isEmpty) return;
                final minutes = _dueTime != null ? _dueTime!.hour * 60 + _dueTime!.minute : null;
                if (isEditing) {
                  final updated = widget.existing!
                    ..title = _titleCtrl.text.trim()
                    ..description = _descCtrl.text.trim()
                    ..dueDate = _dueDate
                    ..dueTimeMinutes = minutes
                    ..priority = _priority
                    ..category = _category
                    ..repeat = _repeat
                    ..reminderEnabled = _reminderEnabled
                    ..subtasks = _subtasks;
                  app.updateTask(updated);
                } else {
                  app.addTask(AppTask(
                    id: app.newId(),
                    title: _titleCtrl.text.trim(),
                    description: _descCtrl.text.trim(),
                    dueDate: _dueDate,
                    dueTimeMinutes: minutes,
                    createdAt: DateTime.now(),
                    priority: _priority,
                    category: _category,
                    repeat: _repeat,
                    reminderEnabled: _reminderEnabled,
                    subtasks: _subtasks,
                  ));
                }
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(isEditing ? 'Save Changes' : 'Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
