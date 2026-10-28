import 'package:flutter/material.dart';

import '../models/task.dart';

enum RecoveryReason {
  fatigue,
  emergency,
  poorPlanning,
  other,
}

typedef RecoveryReviewCallback = Future<void> Function({
  required AppTask task,
  required RecoveryReason reason,
  required String reasonDetails,
  required String supportResponse,
  required String proposedGoal,
  required int threshold,
  required int durationDays,
});

typedef RecoveryGoalRecalibrationCallback = Future<void> Function({
  required AppTask task,
  required String proposedGoal,
  required int threshold,
  required int durationDays,
});

class RecoveryReviewScreen extends StatefulWidget {
  final AppTask task;
  final RecoveryReviewCallback onSaveReview;
  final RecoveryGoalRecalibrationCallback? onRecalibrateGoals;

  const RecoveryReviewScreen({
    super.key,
    required this.task,
    required this.onSaveReview,
    this.onRecalibrateGoals,
  });

  @override
  State<RecoveryReviewScreen> createState() => _RecoveryReviewScreenState();
}

class _RecoveryReviewScreenState extends State<RecoveryReviewScreen> {
  static const int _durationDays = 2;
  static const List<(RecoveryReason, String)> _reasonOptions = [
    (RecoveryReason.fatigue, 'Fatigue'),
    (RecoveryReason.emergency, 'Emergency'),
    (RecoveryReason.poorPlanning, 'Poor planning'),
    (RecoveryReason.other, 'Other'),
  ];

  final _reasonDetailsController = TextEditingController();
  final _supportResponseController = TextEditingController();
  late final TextEditingController _proposedGoalController;

  RecoveryReason? _selectedReason;
  int _threshold = 1;
  bool _recalibrateGoals = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _proposedGoalController = TextEditingController(
      text: _defaultGoalText(widget.task),
    );
  }

  @override
  void dispose() {
    _reasonDetailsController.dispose();
    _supportResponseController.dispose();
    _proposedGoalController.dispose();
    super.dispose();
  }

  String _defaultGoalText(AppTask task) =>
      'Take one small step toward ${task.title}';

  Future<void> _saveReview() async {
    final reason = _selectedReason;
    final proposedGoal = _proposedGoalController.text.trim();
    if (_isSaving || reason == null || proposedGoal.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSaveReview(
        task: widget.task,
        reason: reason,
        reasonDetails: _reasonDetailsController.text.trim(),
        supportResponse: _supportResponseController.text.trim(),
        proposedGoal: proposedGoal,
        threshold: _threshold,
        durationDays: _durationDays,
      );

      if (_recalibrateGoals && widget.onRecalibrateGoals != null) {
        await widget.onRecalibrateGoals!(
          task: widget.task,
          proposedGoal: proposedGoal,
          threshold: _threshold,
          durationDays: _durationDays,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Recovery review saved. One step at a time.')),
      );
      await Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your review: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('A gentle reset')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _supportCard(context),
            const SizedBox(height: 18),
            _sectionTitle(
                context, 'A quick check-in', Icons.chat_bubble_outline),
            const SizedBox(height: 10),
            _reasonCard(context),
            const SizedBox(height: 12),
            _textAnswerCard(
              context,
              question: 'What would help make the next step manageable?',
              hint: 'Anything you need more or less of is worth noting.',
              controller: _supportResponseController,
            ),
            const SizedBox(height: 20),
            _sectionTitle(
              context,
              'A lighter plan for 2 days',
              Icons.spa_outlined,
            ),
            const SizedBox(height: 10),
            _recoveryPlanCard(context),
            if (widget.onRecalibrateGoals != null) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _recalibrateGoals,
                onChanged: _isSaving
                    ? null
                    : (value) => setState(
                          () => _recalibrateGoals = value ?? false,
                        ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Save as my active recovery plan'),
                subtitle: const Text(
                    'Keep this smaller target active for the next 2 days.'),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'This is a supportive reset, not a penalty. Your streak is not '
              'reset by taking time to recalibrate.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed:
                _isSaving || _selectedReason == null ? null : _saveReview,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_isSaving ? 'Saving…' : 'Save recovery review'),
          ),
        ),
      ),
    );
  }

  Widget _supportCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.favorite_outline_rounded, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'It’s okay to adjust the plan.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We’re checking in about “${widget.task.title}”—not judging '
                    'your progress.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _reasonCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What got in the way?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose what fits best. There’s no wrong answer.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (reason, label) in _reasonOptions)
                  ChoiceChip(
                    label: Text(label),
                    selected: _selectedReason == reason,
                    onSelected: _isSaving
                        ? null
                        : (selected) => setState(
                              () => _selectedReason = selected ? reason : null,
                            ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonDetailsController,
              enabled: !_isSaving,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Anything else you’d like to share? (optional)',
                hintText: 'A little context can help you choose a kinder plan.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textAnswerCard(
    BuildContext context, {
    required String question,
    required String hint,
    required TextEditingController controller,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              enabled: !_isSaving,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Write a thought, or leave this blank.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recoveryPlanCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proposed smaller goal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _proposedGoalController,
              enabled: !_isSaving,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Goal for the next 2 days',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily threshold',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        'small steps each day · for 2 days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reduce daily threshold',
                  onPressed: _isSaving || _threshold <= 1
                      ? null
                      : () => setState(() => _threshold--),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text(
                  '$_threshold',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: 'Increase daily threshold',
                  onPressed: _isSaving || _threshold >= 5
                      ? null
                      : () => setState(() => _threshold++),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
