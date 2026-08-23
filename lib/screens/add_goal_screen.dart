import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../models/goal.dart';
import '../utils/formatters.dart';

class AddGoalScreen extends StatefulWidget {
  final AppGoal? existing;

  const AddGoalScreen({
    super.key,
    this.existing,
  });

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final TextEditingController _titleCtrl = TextEditingController();

  DateTime? _targetDate;
  double _progress = 0;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    if (existing != null) {
      _titleCtrl.text = existing.title;
      _targetDate = existing.targetDate;
      _progress = existing.progress.toDouble();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Using dynamic here avoids compile-time errors if your AppScope
    // exposes these methods through a different concrete type.
    final dynamic app = AppScope.of(context);

    final int progress = _progress.round();
    final bool completed = progress >= 100;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Goal' : 'Create Goal',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Delete Goal',
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
              onPressed: () {
                _confirmDelete(context, app);
              },
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            30,
          ),
          children: [
            _buildHeroCard(
              context,
              completed,
              progress,
            ),

            const SizedBox(height: 18),

            _buildSectionTitle(
              context,
              icon: Icons.edit_note_rounded,
              title: 'Goal',
              subtitle: 'What do you want to achieve?',
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _titleCtrl,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Learn Flutter',
                prefixIcon: const Icon(
                  Icons.flag_outlined,
                ),
                filled: true,
                fillColor: colors.surfaceContainerHighest
                    .withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            _buildSectionTitle(
              context,
              icon: Icons.calendar_month_rounded,
              title: 'Target Date',
              subtitle: 'When would you like to achieve it?',
            ),

            const SizedBox(height: 10),

            _buildDateCard(
              context,
              colors,
            ),

            const SizedBox(height: 22),

            _buildSectionTitle(
              context,
              icon: Icons.trending_up_rounded,
              title: 'Progress',
              subtitle: 'How far have you come?',
            ),

            const SizedBox(height: 10),

            _buildProgressCard(
              context,
              progress,
              completed,
              colors,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _saveGoal(context, app);
                },
                icon: Icon(
                  isEditing
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  child: Text(
                    isEditing
                        ? 'Save Changes'
                        : 'Create Goal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              completed
                  ? '🎉 Great job! You have completed this goal.'
                  : 'Keep going — every small step counts.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO CARD
  // ============================================================

  Widget _buildHeroCard(
    BuildContext context,
    bool completed,
    int progress,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.16),
            colors.secondary.withValues(alpha: 0.07),
          ],
        ),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed
                  ? Icons.emoji_events_rounded
                  : Icons.flag_rounded,
              size: 31,
              color: colors.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed
                      ? 'Goal Completed!'
                      : isEditing
                          ? 'Keep Moving Forward'
                          : 'Set a New Goal',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  completed
                      ? 'You made it. Well done!'
                      : '$progress% complete • Keep pushing forward',
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

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: colors.primary,
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE CARD
  // ============================================================

  Widget _buildDateCard(
    BuildContext context,
    ColorScheme colors,
  ) {
    final bool hasDate = _targetDate != null;

    return Material(
      color: colors.surfaceContainerHighest.withValues(
        alpha: 0.45,
      ),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: _selectDate,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.event_rounded,
                  color: colors.primary,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDate
                          ? formatDate(_targetDate!)
                          : 'No target date',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: hasDate
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasDate
                          ? 'Tap to change target date'
                          : 'Tap to choose a target date',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROGRESS CARD
  // ============================================================

  Widget _buildProgressCard(
    BuildContext context,
    int progress,
    bool completed,
    ColorScheme colors,
  ) {
    final Color progressColor =
        completed ? Colors.green : colors.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(
          alpha: 0.38,
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: colors.outlineVariant.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress / 100,
                      strokeWidth: 7,
                      backgroundColor:
                          progressColor.withValues(
                        alpha: 0.10,
                      ),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        progressColor,
                      ),
                    ),
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed
                          ? 'Completed 🎉'
                          : '$progress% Complete',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      completed
                          ? 'Amazing work!'
                          : 'Use the slider to update your progress.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 7,
              thumbShape:
                  const RoundSliderThumbShape(
                enabledThumbRadius: 9,
              ),
              overlayShape:
                  const RoundSliderOverlayShape(
                overlayRadius: 18,
              ),
            ),
            child: Slider(
              value: _progress,
              min: 0,
              max: 100,
              divisions: 20,
              label: '$progress%',
              activeColor: progressColor,
              onChanged: (value) {
                setState(() {
                  _progress = value;
                });
              },
            ),
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '50%',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  // ============================================================
  // SAVE GOAL
  // ============================================================

  void _saveGoal(
    BuildContext context,
    dynamic app,
  ) {
    final String title = _titleCtrl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a goal title.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final int progress = _progress.round();

    try {
      if (isEditing) {
        final AppGoal updated = widget.existing!
          ..title = title
          ..targetDate = _targetDate
          ..progress = progress
          ..completed = progress >= 100;

        app.updateGoal(updated);
      } else {
        final AppGoal newGoal = AppGoal(
          id: app.newId(),
          title: title,
          targetDate: _targetDate,
          progress: progress,
          completed: progress >= 100,
          createdAt: DateTime.now(),
        );

        app.addGoal(newGoal);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save goal: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  void _confirmDelete(
    BuildContext context,
    dynamic app,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final colors =
            Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text(
            'Delete Goal?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This goal will be permanently removed. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () {
                try {
                  app.deleteGoal(
                    widget.existing!.id,
                  );

                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                } catch (e) {
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not delete goal: $e',
                      ),
                      behavior:
                          SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}