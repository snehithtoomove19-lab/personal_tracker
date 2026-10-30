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
    final now = DateTime.now();
    final today = app.todaySignals;
    final highPriorityTasks =
        app.todayTasks.where((task) => task.priority.name == 'high').length;
    final hasCapacityInputs = highPriorityTasks > 0 ||
        today?.sleepQuality != null ||
        today?.meetingHours != null ||
        today?.highIntensityWorkout != null;
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
                    !hasCapacityInputs
                        ? 'Log sleep and today’s load for a personalized estimate.'
                        : today?.sleepQuality == null &&
                                today?.meetingHours == null &&
                                today?.highIntensityWorkout == null
                            ? 'Partial estimate from available inputs; record sleep and the day’s planned load for more context.'
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
                              value: !hasCapacityInputs ? 0 : capacity / 100,
                              strokeWidth: 10,
                              backgroundColor: colors.surfaceContainerHighest,
                              color: capacity <= 15
                                  ? colors.error
                                  : colors.primary,
                            ),
                            Text(!hasCapacityInputs ? '—' : '$capacity%',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          !hasCapacityInputs
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
                    'Model: starts at 100; subtracts for recorded sleep quality, meeting hours, high-priority tasks, and intense workouts. Any time-to-threshold is a rough extrapolation, not a calendar forecast or health prediction.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (app.recoveryReviews.any((review) => _isActivePlan(review, now)))
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
                        .where((review) => _isActivePlan(review, now))
                        .map((review) {
                      final expiresAt = DateTime.tryParse(
                        review['expiresAt'] as String? ?? '',
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.spa_outlined),
                        title: Text(review['proposedGoal'] as String? ??
                            'Smaller steps'),
                        subtitle: Text(
                          'Threshold ${review['threshold']} · '
                          'active until ${expiresAt == null ? 'unknown' : _dateLabel(expiresAt)}',
                        ),
                      );
                    }),
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
                                'Deep work completed: ${item.highSignalDeepWorkPercent == null ? 'not enough data' : '${item.highSignalDeepWorkPercent}%'} vs ${item.lowSignalDeepWorkPercent == null ? 'not enough data' : '${item.lowSignalDeepWorkPercent}%'}.',
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
                            'Focus ${day.focusScore?.toString() ?? '—'}/10 · '
                            'sleep ${day.sleepQuality?.toString() ?? '—'}/5 · '
                            '${day.meetingHours?.toStringAsFixed(1) ?? '—'} meeting hours · '
                            '${day.socialMinutesBefore10?.toString() ?? '—'} social minutes before 10 · '
                            '${day.waterMl?.toString() ?? '—'} ml water',
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

  bool _isActivePlan(Map<String, dynamic> review, DateTime now) {
    if (review['type'] != 'active_plan') return false;
    final expiresAt = DateTime.tryParse(review['expiresAt'] as String? ?? '');
    return expiresAt != null && expiresAt.isAfter(now);
  }

  String _dateLabel(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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
  late bool sleepLogged;
  late bool socialLogged;
  late bool screenLogged;
  late bool mealLogged;
  late bool meetingsLogged;
  late bool focusLogged;
  late bool workoutLogged;
  late bool waterLogged;
  late bool deepWorkLogged;
  late bool intensityLogged;

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
    sleepLogged = day?.sleepQuality != null;
    socialLogged = day?.socialMinutesBefore10 != null;
    screenLogged = day?.screenMinutes != null;
    mealLogged = day?.mealHour != null;
    meetingsLogged = day?.meetingHours != null;
    focusLogged = day?.focusScore != null;
    workoutLogged = day?.workoutMinutes != null;
    waterLogged = day?.waterMl != null;
    deepWorkLogged = day?.deepWorkCompleted != null;
    intensityLogged = day?.highIntensityWorkout != null;
  }

  bool get _hasLoggedSignal =>
      sleepLogged ||
      socialLogged ||
      screenLogged ||
      mealLogged ||
      meetingsLogged ||
      focusLogged ||
      workoutLogged ||
      waterLogged ||
      deepWorkLogged ||
      intensityLogged;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Today’s signals'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Only turn on signals you know. Unlogged values stay unknown, not zero.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                _optionalSignal(
                  'Sleep quality',
                  sleepLogged,
                  (value) => sleepLogged = value,
                  _slider('Sleep quality', sleep, 1, 5, (v) => sleep = v,
                      suffix: '/5'),
                ),
                _optionalSignal(
                  'Social media before 10 AM',
                  socialLogged,
                  (value) => socialLogged = value,
                  _slider('Social media before 10 AM', social, 0, 180,
                      (v) => social = v,
                      suffix: ' min'),
                ),
                _optionalSignal(
                  'Total screen time',
                  screenLogged,
                  (value) => screenLogged = value,
                  _slider(
                      'Total screen time', screen, 0, 900, (v) => screen = v,
                      suffix: ' min'),
                ),
                _optionalSignal(
                  'First meal time',
                  mealLogged,
                  (value) => mealLogged = value,
                  _slider(
                      'First meal time', mealHour, 6, 18, (v) => mealHour = v,
                      suffix: ':00'),
                ),
                _optionalSignal(
                  'Meeting load',
                  meetingsLogged,
                  (value) => meetingsLogged = value,
                  _slider('Meetings', meetings.round(), 0, 10,
                      (v) => meetings = v.toDouble(),
                      suffix: ' hrs'),
                ),
                _optionalSignal(
                  'Focus score',
                  focusLogged,
                  (value) => focusLogged = value,
                  _slider('Focus score', focus, 0, 10, (v) => focus = v,
                      suffix: '/10'),
                ),
                _optionalSignal(
                  'Workout duration',
                  workoutLogged,
                  (value) => workoutLogged = value,
                  _slider('Workout duration', workoutMinutes, 0, 180,
                      (v) => workoutMinutes = v,
                      suffix: ' min'),
                ),
                _optionalSignal(
                  'Water intake',
                  waterLogged,
                  (value) => waterLogged = value,
                  _slider('Water intake', waterMl, 0, 4000, (v) => waterMl = v,
                      suffix: ' ml', step: 100),
                ),
                _optionalSignal(
                  'Deep-work outcome',
                  deepWorkLogged,
                  (value) => deepWorkLogged = value,
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Completed deep work'),
                    value: deepWork,
                    onChanged: (value) => setState(() => deepWork = value),
                  ),
                ),
                _optionalSignal(
                  'Workout intensity',
                  intensityLogged,
                  (value) => intensityLogged = value,
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('High-intensity workout'),
                    value: intense,
                    onChanged: (value) => setState(() => intense = value),
                  ),
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
            onPressed: _hasLoggedSignal
                ? () => Navigator.pop(
                      context,
                      DaySignals(
                        dateKey: daySignalsKey(DateTime.now()),
                        sleepQuality: sleepLogged ? sleep : null,
                        socialMinutesBefore10: socialLogged ? social : null,
                        screenMinutes: screenLogged ? screen : null,
                        mealHour: mealLogged ? mealHour : null,
                        meetingHours: meetingsLogged ? meetings : null,
                        focusScore: focusLogged ? focus : null,
                        deepWorkCompleted: deepWorkLogged ? deepWork : null,
                        workoutMinutes: workoutLogged ? workoutMinutes : null,
                        highIntensityWorkout: intensityLogged ? intense : null,
                        waterMl: waterLogged ? waterMl : null,
                      ),
                    )
                : null,
            child: const Text('Save'),
          ),
        ],
      );

  Widget _optionalSignal(
    String title,
    bool enabled,
    ValueChanged<bool> onChanged,
    Widget input,
  ) =>
      Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title),
            value: enabled,
            onChanged: (value) => setState(() => onChanged(value)),
          ),
          if (enabled) input,
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
