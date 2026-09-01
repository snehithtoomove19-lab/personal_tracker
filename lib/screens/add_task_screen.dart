import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../models/task.dart';
import '../utils/formatters.dart';

class AddTaskScreen extends StatefulWidget {
  final AppTask? existing;

  const AddTaskScreen({
    super.key,
    this.existing,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subtaskCtrl = TextEditingController();

  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  TaskPriority _priority = TaskPriority.medium;
  String _category = kTaskCategories.first;
  TaskRepeat _repeat = TaskRepeat.none;

  bool _reminderEnabled = false;

  final List<SubTask> _subtasks = [];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    if (existing != null) {
      _titleCtrl.text = existing.title;
      _descCtrl.text = existing.description;

      _dueDate = existing.dueDate;

      if (existing.dueTimeMinutes != null) {
        final minutes = existing.dueTimeMinutes!;

        _dueTime = TimeOfDay(
          hour: minutes ~/ 60,
          minute: minutes % 60,
        );
      }

      _priority = existing.priority;

      if (kTaskCategories.contains(existing.category)) {
        _category = existing.category;
      } else {
        _category = kTaskCategories.first;
      }

      _repeat = existing.repeat;
      _reminderEnabled = existing.reminderEnabled;

      _subtasks.addAll(
        existing.subtasks.map(
          (s) => SubTask(
            id: s.id,
            title: s.title,
            completed: s.completed,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subtaskCtrl.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _subtaskCtrl.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _subtasks.add(
        SubTask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: text,
          completed: false,
        ),
      );

      _subtaskCtrl.clear();
    });
  }

  void _removeSubtask(SubTask subtask) {
    setState(() {
      _subtasks.remove(subtask);
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _dueDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
    });
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (picked == null) return;

    setState(() {
      _dueTime = picked;
    });
  }

  void _clearDueDate() {
    setState(() {
      _dueDate = null;
      _dueTime = null;
      _reminderEnabled = false;
    });
  }

  void _clearDueTime() {
    setState(() {
      _dueTime = null;
    });
  }

  void _deleteExistingTask() {
    final existing = widget.existing;

    if (existing == null) return;

    final app = AppScope.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: Text(
            'Are you sure you want to delete "${existing.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                app.deleteTask(existing.id);

                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _saveTask() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final app = AppScope.of(context);

    final minutes =
        _dueTime == null ? null : (_dueTime!.hour * 60) + _dueTime!.minute;

    if (_isEditing) {
      final existing = widget.existing!;

      final updated = AppTask(
        id: existing.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _dueDate,
        dueTimeMinutes: minutes,
        createdAt: existing.createdAt,
        priority: _priority,
        category: _category,
        repeat: _repeat,
        reminderEnabled: _reminderEnabled,
        subtasks: List<SubTask>.from(_subtasks),
      );

      app.updateTask(updated);
    } else {
      final task = AppTask(
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
        subtasks: List<SubTask>.from(_subtasks),
      );

      app.addTask(task);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        titleSpacing: 20,
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Delete task',
                onPressed: _deleteExistingTask,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.error,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              110,
            ),
            children: [
              _buildIntro(context),
              const SizedBox(height: 18),
              _buildMainDetailsCard(context),
              const SizedBox(height: 14),
              _buildChecklistCard(context),
              const SizedBox(height: 14),
              _buildScheduleCard(context),
              const SizedBox(height: 14),
              _buildOrganizationCard(context),
              const SizedBox(height: 14),
              _buildRepeatCard(context),
              const SizedBox(height: 22),
              _buildSaveButton(context),
              if (_isEditing) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _deleteExistingTask,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Delete this task',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // INTRO
  // ===============================================================

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.12),
            colors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
              color: colors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Update your task' : 'Plan something great',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isEditing
                      ? 'Make changes and keep yourself organized.'
                      : 'Add the details now so you can focus later.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // MAIN DETAILS
  // ===============================================================

  Widget _buildMainDetailsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.edit_note_rounded,
            title: 'Task details',
            color: colors.primary,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleCtrl,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: 'Task title',
              hintText: 'What do you need to do?',
              prefixIcon: const Icon(
                Icons.check_circle_outline_rounded,
              ),
              counterText: '',
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a task title';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            minLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Add notes or extra details...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 54),
                child: Icon(Icons.notes_rounded),
              ),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // CHECKLIST
  // ===============================================================

  Widget _buildChecklistCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final completedCount = _subtasks.where((s) => s.completed).length;

    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeading(
                  icon: Icons.checklist_rounded,
                  title: 'Checklist',
                  color: colors.primary,
                ),
              ),
              if (_subtasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completedCount/${_subtasks.length}',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          if (_subtasks.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(
                  alpha: 0.32,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _subtasks.length; i++)
                    _buildSubtaskTile(
                      context,
                      _subtasks[i],
                      i == _subtasks.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _subtaskCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSubtask(),
                  decoration: InputDecoration(
                    hintText: 'Add checklist item...',
                    prefixIcon: const Icon(
                      Icons.add_task_rounded,
                    ),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Add checklist item',
                onPressed: _addSubtask,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (_subtasks.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Break this task into smaller steps if needed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtaskTile(
    BuildContext context,
    SubTask subtask,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          child: Row(
            children: [
              Checkbox(
                value: subtask.completed,
                onChanged: (value) {
                  setState(() {
                    subtask.completed = value ?? false;
                  });
                },
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  subtask.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration:
                        subtask.completed ? TextDecoration.lineThrough : null,
                    color: subtask.completed ? colors.onSurfaceVariant : null,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () => _removeSubtask(subtask),
                icon: Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 48,
            endIndent: 8,
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }

  // ===============================================================
  // SCHEDULE
  // ===============================================================

  Widget _buildScheduleCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.schedule_rounded,
            title: 'Schedule',
            color: colors.primary,
          ),
          const SizedBox(height: 14),
          _buildSettingTile(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Due date',
            subtitle: _dueDate != null ? formatDate(_dueDate!) : 'No due date',
            trailing: _dueDate != null
                ? IconButton(
                    tooltip: 'Clear date',
                    onPressed: _clearDueDate,
                    icon: const Icon(Icons.close_rounded),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
            onTap: _pickDueDate,
            highlighted: _dueDate != null,
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            context,
            icon: Icons.access_time_rounded,
            title: 'Reminder time',
            subtitle: _dueTime != null
                ? _dueTime!.format(context)
                : 'No specific time',
            trailing: _dueTime != null
                ? IconButton(
                    tooltip: 'Clear time',
                    onPressed: _clearDueTime,
                    icon: const Icon(Icons.close_rounded),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
            onTap: _pickDueTime,
            highlighted: _dueTime != null,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(
                alpha: 0.32,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 2,
              ),
              secondary: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: colors.primary,
                  size: 21,
                ),
              ),
              title: const Text(
                'Remind me',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                _dueDate == null
                    ? 'Set a due date first'
                    : 'Show this task in reminders as it approaches',
              ),
              value: _reminderEnabled,
              onChanged: _dueDate == null
                  ? null
                  : (value) {
                      setState(() {
                        _reminderEnabled = value;
                      });
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: highlighted
          ? colors.primary.withValues(alpha: 0.055)
          : colors.surfaceContainerHighest.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: highlighted
                      ? colors.primary.withValues(alpha: 0.11)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: highlighted ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // ORGANIZATION
  // ===============================================================

  Widget _buildOrganizationCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.tune_rounded,
            title: 'Organization',
            color: colors.primary,
          ),
          const SizedBox(height: 15),
          Text(
            'Category',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.folder_open_rounded,
              ),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.35),
            ),
            items: kTaskCategories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _category = value;
              });
            },
          ),
          const SizedBox(height: 17),
          Text(
            'Priority',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          _buildPrioritySelector(context),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PriorityButton(
            label: 'Low',
            icon: Icons.keyboard_arrow_down_rounded,
            color: Colors.green,
            selected: _priority == TaskPriority.low,
            onTap: () {
              setState(() {
                _priority = TaskPriority.low;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PriorityButton(
            label: 'Medium',
            icon: Icons.remove_rounded,
            color: Colors.orange,
            selected: _priority == TaskPriority.medium,
            onTap: () {
              setState(() {
                _priority = TaskPriority.medium;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PriorityButton(
            label: 'High',
            icon: Icons.keyboard_arrow_up_rounded,
            color: Colors.red,
            selected: _priority == TaskPriority.high,
            onTap: () {
              setState(() {
                _priority = TaskPriority.high;
              });
            },
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // REPEAT
  // ===============================================================

  Widget _buildRepeatCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.repeat_rounded,
            title: 'Repeat',
            color: colors.primary,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RepeatChip(
                label: 'None',
                icon: Icons.block_rounded,
                selected: _repeat == TaskRepeat.none,
                onTap: () {
                  setState(() {
                    _repeat = TaskRepeat.none;
                  });
                },
              ),
              _RepeatChip(
                label: 'Daily',
                icon: Icons.today_rounded,
                selected: _repeat == TaskRepeat.daily,
                onTap: () {
                  setState(() {
                    _repeat = TaskRepeat.daily;
                  });
                },
              ),
              _RepeatChip(
                label: 'Weekly',
                icon: Icons.date_range_rounded,
                selected: _repeat == TaskRepeat.weekly,
                onTap: () {
                  setState(() {
                    _repeat = TaskRepeat.weekly;
                  });
                },
              ),
              _RepeatChip(
                label: 'Monthly',
                icon: Icons.calendar_month_rounded,
                selected: _repeat == TaskRepeat.monthly,
                onTap: () {
                  setState(() {
                    _repeat = TaskRepeat.monthly;
                  });
                },
              ),
            ],
          ),
          if (_repeat != TaskRepeat.none) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'When you complete this task, the next occurrence will be created automatically.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===============================================================
  // SAVE BUTTON
  // ===============================================================

  Widget _buildSaveButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _saveTask,
        icon: Icon(
          _isEditing ? Icons.check_rounded : Icons.add_task_rounded,
        ),
        label: Text(
          _isEditing ? 'Save Changes' : 'Create Task',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
      ),
    );
  }
}

// =================================================================
// SECTION CONTAINER
// =================================================================

class _SectionContainer extends StatelessWidget {
  final Widget child;

  const _SectionContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// =================================================================
// SECTION HEADING
// =================================================================

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
        ),
      ],
    );
  }
}

// =================================================================
// PRIORITY BUTTON
// =================================================================

class _PriorityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? color.withValues(alpha: 0.12)
          : colors.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.35)
                  : colors.outlineVariant.withValues(alpha: 0.45),
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? color : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// REPEAT CHIP
// =================================================================

class _RepeatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RepeatChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.11)
          : colors.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
