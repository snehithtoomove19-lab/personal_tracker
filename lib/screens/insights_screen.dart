import 'package:flutter/material.dart';

import '../models/day_signals.dart';
import '../services/app_scope.dart';
import '../services/app_state.dart';
import '../services/focus_insights_service.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = app.todaySignals;
    final highPriorityTasks =
        app.todayTasks.where((task) => task.priority.name == 'high').length;
    final capacity = FocusInsightsService.energyCapacity(
      today: today,
      highPriorityTasksToday: highPriorityTasks,
    );
    final timeToCritical = FocusInsightsService.estimatedTimeToCritical(
      capacity: capacity,
      today: today,
      highPriorityTasksToday: highPriorityTasks,
    );
    final correlations = FocusInsightsService.correlations(app.daySignals);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus & Energy Insights')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editSignals(context, app),
        icon: const Icon(Icons.edit_note_rounded),
        label: Text(today == null ? 'Log today' : 'Update today'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 96,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated energy',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    today == null
                        ? 'Log sleep and today’s load for a personalized estimate.'
                        : 'A planning estimate, not a medical measurement.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 104,
                        height: 104,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: today == null ? 0 : capacity / 100,
                              strokeWidth: 10,
                              backgroundColor: colors.surfaceContainerHighest,
                              color: capacity <= 15
                                  ? colors.error
                                  : colors.primary,
                            ),
                            Text(today == null ? '—' : '$capacity%',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          today == null
                              ? 'Based on your inputs, meetings, priorities, and workout load.'
                              : capacity <= 15
                                  ? 'Your estimated capacity is low. Consider a lighter plan or a break.'
                                  : timeToCritical == null
                                      ? 'Your logged load is light so far. Check in as plans change.'
                                      : 'At the current modeled pace, the estimate reaches 15% around ${TimeOfDay.fromDateTime(DateTime.now().add(timeToCritical)).format(context)} (about ${_durationLabel(timeToCritical)} from now).',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Model: starts at 100; subtracts for sleep quality, meeting hours, high-priority tasks, and intense workouts. It does not read calendars or predict health.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (app.recoveryReviews.any((review) =>
              review['type'] == 'active_plan' &&
              DateTime.tryParse(review['expiresAt'] as String? ?? '')
                      ?.isAfter(DateTime.now()) ==
                  true))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gentle recovery plans',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...app.recoveryReviews
                        .where((review) =>
                            review['type'] == 'active_plan' &&
                            DateTime.tryParse(
                                        review['expiresAt'] as String? ?? '')
                                    ?.isAfter(DateTime.now()) ==
                                true)
                        .map((review) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.spa_outlined),
                              title: Text(review['proposedGoal'] as String? ??
                                  'Smaller steps'),
                              subtitle: Text(
                                'Threshold ${review['threshold']} · '
                                'active until ${review['expiresAt'].toString().substring(0, 10)}',
                              ),
                            )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          if (app.voiceLogs.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Voice quick logs',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...app.voiceLogs.take(7).map((entry) {
                      final details = <String>[
                        if (entry.waterMl > 0) '${entry.waterMl} ml water',
                        if (entry.workoutMinutes > 0)
                          '${entry.workoutMinutes} min ${entry.workoutType}',
                        if (entry.expenseAmount != null)
                          '${app.currency}${entry.expenseAmount!.toStringAsFixed(2)} ${entry.expenseCategory ?? 'expense'}',
                        if (entry.mood != null) 'Mood: ${entry.mood}',
                      ];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.mic_none_rounded),
                        title: Text(details.join(' · ')),
                        subtitle: Text(
                          '${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}-${entry.createdAt.day.toString().padLeft(2, '0')}',
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          if (app.voiceLogs.isNotEmpty) const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cross-signal patterns',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Compares your logged focus on higher-signal and lower-signal days. These are associations, not proof of cause.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (correlations.isEmpty)
                    const Text(
                        'Add daily logs. Each comparison needs at least 2 days in both groups.')
                  else
                    ...correlations.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.signal,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(
                                'Focus average: ${item.highSignalAverage}/10 on ${item.highSignalDays} days vs ${item.lowSignalAverage}/10 on ${item.lowSignalDays} other days (${item.difference > 0 ? '+' : ''}${item.difference} points).',
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Deep work completed: ${item.highSignalDeepWorkPercent}% vs ${item.lowSignalDeepWorkPercent}%.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Divider(height: 16),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your recent logs',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (app.daySignals.isEmpty)
                    const Text('No daily signal logs yet.')
                  else
                    ...app.daySignals.take(7).map((day) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(day.dateKey),
                          subtitle: Text(
                            'Focus ${day.focusScore}/10 · sleep ${day.sleepQuality}/5 · '
                            '${day.meetingHours.toStringAsFixed(1)} meeting hours · '
                            '${day.socialMinutesBefore10} social minutes before 10',
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _durationLabel(Duration duration) {
    if (duration.inMinutes < 60) return '${duration.inMinutes} minutes';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return minutes == 0 ? '$hours hours' : '$hours h $minutes min';
  }

  Future<void> _editSignals(BuildContext context, AppState app) async {
    final existing = app.todaySignals;
    final result = await showDialog<DaySignals>(
      context: context,
      builder: (_) => _DailySignalsDialog(existing: existing),
    );
    if (result != null) await app.saveDaySignals(result);
  }
}

class _DailySignalsDialog extends StatefulWidget {
  final DaySignals? existing;
  const _DailySignalsDialog({required this.existing});

  @override
  State<_DailySignalsDialog> createState() => _DailySignalsDialogState();
}

class _DailySignalsDialogState extends State<_DailySignalsDialog> {
  late int sleep;
  late int social;
  late int screen;
  late int mealHour;
  late double meetings;
  late int focus;
  late int workoutMinutes;
  late int waterMl;
  late bool deepWork;
  late bool intense;

  @override
  void initState() {
    super.initState();
    final day = widget.existing;
    sleep = day?.sleepQuality ?? 3;
    social = day?.socialMinutesBefore10 ?? 0;
    screen = day?.screenMinutes ?? 0;
    mealHour = day?.mealHour ?? 12;
    meetings = day?.meetingHours ?? 0;
    focus = day?.focusScore ?? 5;
    workoutMinutes = day?.workoutMinutes ?? 0;
    waterMl = day?.waterMl ?? 0;
    deepWork = day?.deepWorkCompleted ?? false;
    intense = day?.highIntensityWorkout ?? false;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Today’s signals'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _slider('Sleep quality', sleep, 1, 5, (v) => sleep = v,
                    suffix: '/5'),
                _slider('Social media before 10 AM', social, 0, 180,
                    (v) => social = v,
                    suffix: ' min'),
                _slider('Total screen time', screen, 0, 900, (v) => screen = v,
                    suffix: ' min'),
                _slider('First meal time', mealHour, 6, 18, (v) => mealHour = v,
                    suffix: ':00'),
                _slider('Meetings', meetings.round(), 0, 10,
                    (v) => meetings = v.toDouble(),
                    suffix: ' hrs'),
                _slider('Focus score', focus, 0, 10, (v) => focus = v,
                    suffix: '/10'),
                _slider('Workout duration', workoutMinutes, 0, 180,
                    (v) => workoutMinutes = v,
                    suffix: ' min'),
                _slider('Water intake', waterMl, 0, 4000, (v) => waterMl = v,
                    suffix: ' ml', step: 100),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Completed deep work'),
                  value: deepWork,
                  onChanged: (value) => setState(() => deepWork = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('High-intensity workout'),
                  value: intense,
                  onChanged: (value) => setState(() => intense = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              DaySignals(
                dateKey: daySignalsKey(DateTime.now()),
                sleepQuality: sleep,
                socialMinutesBefore10: social,
                screenMinutes: screen,
                mealHour: mealHour,
                meetingHours: meetings,
                focusScore: focus,
                deepWorkCompleted: deepWork,
                workoutMinutes: workoutMinutes,
                highIntensityWorkout: intense,
                waterMl: waterMl,
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      );

  Widget _slider(
      String label, int value, int min, int max, ValueChanged<int> onChanged,
      {String suffix = '', int step = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value$suffix'),
        Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: ((max - min) / step).round(),
          onChanged: (next) => setState(
            () => onChanged((next / step).round() * step),
          ),
        ),
      ],
    );
  }
}
