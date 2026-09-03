import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool _isCurrentMonth(DateTime month) {
    final now = DateTime.now();

    return month.year == now.year && month.month == now.month;
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    if (_isCurrentMonth(_visibleMonth)) {
      return;
    }

    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);

    final todayMood = app.todayMood;

    final summary = app.monthMoodSummary(
      month: _visibleMonth,
    );

    final totalLogged = summary.values.fold<int>(
      0,
      (previous, value) => previous + value,
    );

    final isCurrentMonth = _isCurrentMonth(
      _visibleMonth,
    );

    // Only show missed days for the current month.
    final missedDays = isCurrentMonth ? app.missedMoodDaysThisMonth : [];

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        20 + bottomInset,
      ),
      children: [
        _buildHeader(
          context,
          todayMood,
        ),
        const SizedBox(height: 16),
        if (missedDays.isNotEmpty)
          _buildMissedDaysCard(
            context,
            missedDays.length,
          ),
        if (missedDays.isNotEmpty) const SizedBox(height: 14),
        _buildTodayMoodCard(
          context,
          todayMood,
        ),
        const SizedBox(height: 14),
        _buildCalendarCard(
          context,
          app,
          isCurrentMonth,
        ),
        const SizedBox(height: 14),
        _buildSummaryCard(
          context,
          summary,
          totalLogged,
          colors,
        ),
      ],
    );
  }

  // ===============================================================
  // HEADER
  // ===============================================================

  Widget _buildHeader(
    BuildContext context,
    MoodEntry? todayMood,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final option = todayMood != null ? moodOptionFor(todayMood.mood) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mood',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Understand how you feel over time.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (option != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: option.color.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              option.icon,
              color: option.color,
              size: 25,
            ),
          ),
      ],
    );
  }

  // ===============================================================
  // MISSED DAYS
  // ===============================================================

  Widget _buildMissedDaysCard(
    BuildContext context,
    int missedCount,
  ) {
    final theme = Theme.of(context);
    const color = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_calendar_outlined,
              color: Colors.orange.shade800,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$missedCount day${missedCount == 1 ? '' : 's'} not logged',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a day in the calendar below to record how you felt.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade900.withValues(alpha: 0.75),
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
  // TODAY MOOD
  // ===============================================================

  Widget _buildTodayMoodCard(
    BuildContext context,
    MoodEntry? todayMood,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.10),
            colors.secondary.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling today?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todayMood == null
                          ? 'Choose a mood to start your day'
                          : 'Your mood has been recorded',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 9,
            runSpacing: 10,
            children: kMoodOptions.map((mood) {
              final selected = todayMood?.mood == mood.key;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    _logMood(
                      context,
                      mood.key,
                      DateTime.now(),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 220,
                    ),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? mood.color.withValues(
                              alpha: 0.15,
                            )
                          : colors.surface.withValues(
                              alpha: 0.5,
                            ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selected ? mood.color : colors.outlineVariant,
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: mood.color.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 10,
                                offset: const Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.12 : 1,
                          duration: const Duration(
                            milliseconds: 220,
                          ),
                          child: Icon(
                            mood.icon,
                            size: 29,
                            color: mood.color,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          mood.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: mood.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // CALENDAR CARD
  // ===============================================================

  Widget _buildCalendarCard(
    BuildContext context,
    dynamic app,
    bool isCurrentMonth,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(
            alpha: 0.7,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatMonthYear(
                        _visibleMonth,
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tap a day to log or edit your mood',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Previous month',
                onPressed: _goToPreviousMonth,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                ),
              ),
              IconButton(
                tooltip: isCurrentMonth ? 'Current month' : 'Next month',
                onPressed: isCurrentMonth ? null : _goToNextMonth,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MoodCalendarGrid(
            month: _visibleMonth,
            app: app,
            onDayTap: (date) {
              _pickMoodForDay(
                context,
                date,
              );
            },
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SUMMARY
  // ===============================================================

  Widget _buildSummaryCard(
    BuildContext context,
    Map<String, int> summary,
    int totalLogged,
    ColorScheme colors,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(
            alpha: 0.7,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$totalLogged mood${totalLogged == 1 ? '' : 's'} logged',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (totalLogged == 0)
            _buildEmptySummary(context)
          else
            ...summary.entries.map((entry) {
              final mood = moodOptionFor(
                entry.key,
              );

              final percentage = entry.value / totalLogged;

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 14,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: mood.color.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            mood.icon,
                            size: 17,
                            color: mood.color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            mood.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: mood.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(percentage * 100).round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        color: mood.color,
                        backgroundColor: mood.color.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptySummary(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 26,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 38,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'No moods logged yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start logging your mood to see your monthly pattern.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // PICK MOOD FOR CALENDAR DAY
  // ===============================================================

  void _pickMoodForDay(
    BuildContext context,
    DateTime date,
  ) {
    final now = DateTime.now();
    final todayOnly = _dateOnly(now);
    final selectedDate = _dateOnly(date);

    // Never allow future dates.
    if (selectedDate.isAfter(todayOnly)) {
      return;
    }

    final app = AppScope.of(context);
    final existing = app.moodForDay(
      selectedDate,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              18,
              4,
              18,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSameDay(
                    selectedDate,
                    now,
                  )
                      ? 'Today'
                      : formatDate(selectedDate),
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  existing == null
                      ? 'How were you feeling?'
                      : 'Choose a mood to edit this entry',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kMoodOptions.map(
                    (mood) {
                      final selected = existing?.mood == mood.key;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            15,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);

                            _logMood(
                              context,
                              mood.key,
                              selectedDate,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 180,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? mood.color.withValues(
                                      alpha: 0.14,
                                    )
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(
                                15,
                              ),
                              border: Border.all(
                                color: selected
                                    ? mood.color
                                    : colors.outlineVariant,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mood.icon,
                                  size: 27,
                                  color: mood.color,
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  mood.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: mood.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================================================
  // LOG MOOD
  // ===============================================================

  void _logMood(
    BuildContext context,
    String key,
    DateTime date,
  ) {
    final app = AppScope.of(context);

    final selectedDate = _dateOnly(date);

    final existing = app.moodForDay(
      selectedDate,
    );

    final noteCtrl = TextEditingController(
      text: existing?.note ?? '',
    );

    final option = moodOptionFor(key);

    final isToday = _isSameDay(
      selectedDate,
      DateTime.now(),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;

        return AnimatedPadding(
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              18,
              4,
              18,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: option.color.withValues(
                          alpha: 0.13,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        option.icon,
                        color: option.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday
                                ? 'Today'
                                : formatDate(
                                    selectedDate,
                                  ),
                            style:
                                Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.label,
                            style: TextStyle(
                              color: option.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Mood note',
                    hintText: 'What made you feel this way?',
                    prefixIcon: const Icon(
                      Icons.edit_note_rounded,
                    ),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: colors.surface.withValues(
                      alpha: 0.45,
                    ),
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
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final note = noteCtrl.text.trim();

                      await app.upsertMood(
                        MoodEntry(
                          id: existing?.id ?? app.newId(),
                          date: selectedDate,
                          mood: key,
                          note: note,
                        ),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    icon: const Icon(
                      Icons.check_rounded,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      child: Text(
                        'Save Mood',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      noteCtrl.dispose();
    });
  }
}

// =================================================================
// MOOD CALENDAR
// =================================================================

class _MoodCalendarGrid extends StatelessWidget {
  final DateTime month;
  final dynamic app;
  final void Function(DateTime date) onDayTap;

  const _MoodCalendarGrid({
    required this.month,
    required this.app,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final firstDay = DateTime(
      month.year,
      month.month,
      1,
    );

    final daysInMonth = DateTime(
      month.year,
      month.month + 1,
      0,
    ).day;

    // Sunday = 0, Monday = 1, ..., Saturday = 6.
    final leadingBlanks = firstDay.weekday % 7;

    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    // =============================================================
    // WEEKDAY HEADER
    // =============================================================

    const weekdays = [
      'S',
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
    ];

    final weekdayHeader = Row(
      children: weekdays.map((day) {
        return Expanded(
          child: SizedBox(
            height: 30,
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );

    // =============================================================
    // DATE CELLS
    // =============================================================

    final dayCells = <Widget>[];

    // Empty cells before day 1.
    for (int i = 0; i < leadingBlanks; i++) {
      dayCells.add(
        const SizedBox.shrink(),
      );
    }

    // Actual dates.
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(
        month.year,
        month.month,
        day,
      );

      final mood = app.moodForDay(date);

      final moodOption = mood != null ? moodOptionFor(mood.mood) : null;

      final isFuture = date.isAfter(todayOnly);

      final isToday = date.year == todayOnly.year &&
          date.month == todayOnly.month &&
          date.day == todayOnly.day;

      dayCells.add(
        _MoodDayCell(
          day: day,
          moodOption: moodOption,
          isToday: isToday,
          isFuture: isFuture,
          colors: colors,
          onTap: isFuture ? null : () => onDayTap(date),
        ),
      );
    }

    return Column(
      children: [
        weekdayHeader,
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dayCells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,

            // Fixed height prevents calendar overflow.
            mainAxisExtent: 52,

            crossAxisSpacing: 1,
            mainAxisSpacing: 2,
          ),
          itemBuilder: (context, index) {
            return dayCells[index];
          },
        ),
      ],
    );
  }
}

// =================================================================
// CALENDAR DAY CELL
// =================================================================

class _MoodDayCell extends StatelessWidget {
  final int day;
  final dynamic moodOption;
  final bool isToday;
  final bool isFuture;
  final ColorScheme colors;
  final VoidCallback? onTap;

  const _MoodDayCell({
    required this.day,
    required this.moodOption,
    required this.isToday,
    required this.isFuture,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasMood = moodOption != null;

    final backgroundColor = hasMood
        ? moodOption.color.withValues(
            alpha: 0.08,
          )
        : colors.surface.withValues(
            alpha: 0.25,
          );

    final borderColor = isToday
        ? colors.primary
        : hasMood
            ? moodOption.color.withValues(
                alpha: 0.18,
              )
            : Colors.transparent;

    final textColor = isFuture
        ? colors.onSurface.withValues(
            alpha: 0.18,
          )
        : isToday
            ? colors.primary
            : colors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isToday ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 11,
                  height: 1,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              if (hasMood)
                Icon(
                  moodOption.icon,
                  size: 17,
                  color: moodOption.color,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  size: 10,
                  color: isFuture
                      ? colors.onSurface.withValues(
                          alpha: 0.10,
                        )
                      : colors.onSurfaceVariant.withValues(
                          alpha: 0.45,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
