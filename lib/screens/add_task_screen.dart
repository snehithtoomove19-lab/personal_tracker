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

class _AddTaskScreenState extends State<AddTaskScreen>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _animationController;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animationController.forward();

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
    _animationController.dispose();
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
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          child: child!,
        );
      },
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
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.error,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delete task?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete "${existing.title}"?',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () {
                app.deleteTask(existing.id);

                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
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

    final minutes = _dueTime == null
        ? null
        : (_dueTime!.hour * 60) + _dueTime!.minute;

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
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              120,
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
                const SizedBox(height: 12),
                _buildDeleteButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
        ),
      ),
      title: Text(
        _isEditing ? 'Edit Task' : 'New Task',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -.5,
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
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: .20),
            colors.secondary.withValues(alpha: .10),
            colors.tertiary.withValues(alpha: .06),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.primary.withValues(alpha: .15),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  colors.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: .25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _isEditing
                  ? Icons.edit_note_rounded
                  : Icons.add_task_rounded,
              color: colors.onPrimary,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Update your task'
                      : 'Plan something great',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isEditing
                      ? 'Make changes and stay organized.'
                      : 'Add the details now so you can focus later.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            subtitle: 'What needs to get done?',
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _titleCtrl,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            decoration: _inputDecoration(
              context,
              label: 'Task title',
              hint: 'e.g. Finish Flutter project',
              icon: Icons.check_circle_outline_rounded,
            ).copyWith(
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a task title';
              }

              return null;
            },
          ),
          const SizedBox(height: 13),
          TextFormField(
            controller: _descCtrl,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            minLines: 3,
            decoration: _inputDecoration(
              context,
              label: 'Description',
              hint: 'Add notes, links or extra details...',
              icon: Icons.notes_rounded,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Padding(
        padding: alignLabelWithHint
            ? const EdgeInsets.only(bottom: 50)
            : EdgeInsets.zero,
        child: Icon(icon),
      ),
      filled: true,
      fillColor: colors.surfaceContainerHighest.withValues(
        alpha: .35,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colors.outlineVariant.withValues(alpha: .35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colors.error,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildChecklistCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final completedCount =
        _subtasks.where((s) => s.completed).length;

    final progress = _subtasks.isEmpty
        ? 0.0
        : completedCount / _subtasks.length;

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
                  subtitle: _subtasks.isEmpty
                      ? 'Break big tasks into steps'
                      : '$completedCount of ${_subtasks.length} completed',
                ),
              ),
              if (_subtasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_subtasks.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor:
                    colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(
                  alpha: .28,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: .3),
                ),
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
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _subtaskCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSubtask(),
                  decoration: _inputDecoration(
                    context,
                    label: '',
                    hint: 'Add checklist item...',
                    icon: Icons.add_task_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary,
                      colors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: IconButton(
                  tooltip: 'Add checklist item',
                  onPressed: _addSubtask,
                  color: colors.onPrimary,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
          if (_subtasks.isEmpty) ...[
            const SizedBox(height: 9),
            Text(
              'Optional • Add smaller steps to make this task easier.',
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
            horizontal: 9,
            vertical: 5,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: subtask.completed
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
                    decoration: subtask.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  child: Text(
                    subtask.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            indent: 52,
            endIndent: 10,
            color: colors.outlineVariant.withValues(alpha: .4),
          ),
      ],
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.schedule_rounded,
            title: 'Schedule',
            color: colors.primary,
            subtitle: 'When should this happen?',
          ),
          const SizedBox(height: 15),
          _buildSettingTile(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Due date',
            subtitle: _dueDate != null
                ? formatDate(_dueDate!)
                : 'No due date',
            trailing: _dueDate != null
                ? IconButton(
                    tooltip: 'Clear date',
                    onPressed: _clearDueDate,
                    icon: const Icon(Icons.close_rounded),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: _pickDueDate,
            highlighted: _dueDate != null,
          ),
          const SizedBox(height: 9),
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
                : const Icon(Icons.chevron_right_rounded),
            onTap: _pickDueTime,
            highlighted: _dueTime != null,
          ),
          const SizedBox(height: 9),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(
                alpha: .30,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .3),
              ),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 3,
              ),
              secondary: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                _dueDate == null
                    ? 'Set a due date first'
                    : 'Get a reminder when this task approaches',
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
          ? colors.primary.withValues(alpha: .07)
          : colors.surfaceContainerHighest.withValues(alpha: .30),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: highlighted
                      ? colors.primary.withValues(alpha: .12)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: highlighted
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
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
            subtitle: 'Keep your tasks structured',
          ),
          const SizedBox(height: 17),
          Text(
            'Category',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: _inputDecoration(
              context,
              label: '',
              hint: 'Select category',
              icon: Icons.folder_open_rounded,
            ),
            items: kTaskCategories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
          const SizedBox(height: 18),
          Text(
            'Priority',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
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
            subtitle: 'Automate recurring tasks',
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 9,
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
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: .10),
                    colors.secondary.withValues(alpha: .05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.primary.withValues(alpha: .10),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: .10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'When you complete this task, the next occurrence will be created automatically.',
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
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

  Widget _buildSaveButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colors.primary,
            colors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: _saveTask,
        icon: Icon(
          _isEditing
              ? Icons.check_rounded
              : Icons.add_task_rounded,
        ),
        label: Text(
          _isEditing ? 'Save Changes' : 'Create Task',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: _deleteExistingTask,
      icon: Icon(
        Icons.delete_outline_rounded,
        color: colors.error,
      ),
      label: Text(
        'Delete this task',
        style: TextStyle(
          color: colors.error,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(
          color: colors.error.withValues(alpha: .30),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      ),
    );
  }
}


// ============================================================================
// SECTION CONTAINER
// ============================================================================

class _SectionContainer extends StatelessWidget {
  final Widget child;

  const _SectionContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: .55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness ==
                      Brightness.dark
                  ? .16
                  : .025,
            ),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}


// ============================================================================
// SECTION HEADING
// ============================================================================

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: .16),
                color.withValues(alpha: .07),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


// ============================================================================
// PRIORITY BUTTON
// ============================================================================

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: .18),
                  color.withValues(alpha: .07),
                ],
              )
            : null,
        color: selected
            ? null
            : colors.surfaceContainerHighest.withValues(
                alpha: .30,
              ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected
              ? color.withValues(alpha: .45)
              : colors.outlineVariant.withValues(alpha: .4),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 13,
              horizontal: 7,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: .12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? color
                        : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? color
                        : colors.onSurfaceVariant,
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
// REPEAT CHIP
// ============================================================================

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: .16),
                  colors.secondary.withValues(alpha: .08),
                ],
              )
            : null,
        color: selected
            ? null
            : colors.surfaceContainerHighest.withValues(
                alpha: .32,
              ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? colors.primary.withValues(alpha: .35)
              : colors.outlineVariant.withValues(alpha: .4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? colors.primary
                        : colors.onSurfaceVariant,
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