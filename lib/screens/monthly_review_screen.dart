import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';

class MonthlyReviewScreen extends StatefulWidget {
  const MonthlyReviewScreen({super.key});

  @override
  State<MonthlyReviewScreen> createState() => _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends State<MonthlyReviewScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _changeMonth(int offset) {
    final candidate = DateTime(_month.year, _month.month + offset);
    final now = DateTime.now();
    if (candidate.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _month = candidate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final review = AppScope.of(context).monthlyReview(month: _month);
    final moodSummary = Map<String, int>.from(review['moodSummary'] as Map);
    final moodCount = review['moodCheckIns'] as int;
    final activeDays = review['activeDays'] as int;
    final dayCount = _isCurrentMonth
        ? DateTime.now().day
        : DateTime(_month.year, _month.month + 1, 0).day;
    final leadingMood = moodSummary.isEmpty
        ? null
        : moodSummary.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly reset'),
        actions: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Text(
            formatMonthYear(_month),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _ReviewHero(
            activeDays: activeDays,
            dayCount: dayCount,
            headline: moodCount == 0 && activeDays == 0
                ? 'A fresh page.'
                : 'You made space for you.',
            detail: moodCount == 0 && activeDays == 0
                ? 'No data is still data. Start with one small check-in whenever you feel ready.'
                : 'This is a snapshot of what you chose to track. It is not a scorecard.',
          ),
          const SizedBox(height: 22),
          Text(
            'Your month in real life',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -.55,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Missing entries stay unknown — never counted as zero.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.65,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Tasks done',
                value: '${review['tasksCompleted']}',
                color: colors.primary,
              ),
              _MetricCard(
                icon: Icons.flag_outlined,
                label: 'Goals reached',
                value: '${review['goalsAchieved']}',
                color: colors.tertiary,
              ),
              _MetricCard(
                icon: Icons.fitness_center_rounded,
                label: 'Movement',
                value: _minutes(review['workoutMinutes'] as int),
                color: colors.secondary,
              ),
              _MetricCard(
                icon: Icons.water_drop_outlined,
                label: 'Water logged',
                value: _litres(review['waterMl'] as int),
                color: colors.primary,
              ),
              _MetricCard(
                icon: Icons.bedtime_outlined,
                label: 'Sleep check-ins',
                value: _rating(review['averageSleepQuality']),
                color: colors.secondary,
              ),
              _MetricCard(
                icon: Icons.center_focus_strong_outlined,
                label: 'Focus check-ins',
                value: _rating(review['averageFocusScore']),
                color: colors.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _MoodRecap(
            checkIns: moodCount,
            summary: moodSummary,
            leadingMood: leadingMood,
          ),
        ],
      ),
    );
  }

  String _minutes(int minutes) {
    if (minutes == 0) return 'Not logged';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$remaining min';
    return remaining == 0 ? '${hours}h' : '${hours}h ${remaining}m';
  }

  String _litres(int millilitres) {
    if (millilitres == 0) return 'Not logged';
    return '${(millilitres / 1000).toStringAsFixed(1)} L';
  }

  String _rating(Object? value) {
    if (value is! num) return 'Not logged';
    return '${value.toStringAsFixed(1)} / 5';
  }
}

class _ReviewHero extends StatelessWidget {
  const _ReviewHero({
    required this.activeDays,
    required this.dayCount,
    required this.headline,
    required this.detail,
  });

  final int activeDays;
  final int dayCount;
  final String headline;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = dayCount == 0 ? 0.0 : activeDays / dayCount;
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.tertiary],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 25),
          const SizedBox(height: 15),
          Text(
            headline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
          ),
          const SizedBox(height: 7),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .85),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$activeDays',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: .95,
                    ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'days you checked in',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .85),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress.clamp(0, 1),
              backgroundColor: Colors.white.withValues(alpha: .22),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'of $dayCount days so far',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: .8),
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 20, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.35,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodRecap extends StatelessWidget {
  const _MoodRecap({
    required this.checkIns,
    required this.summary,
    required this.leadingMood,
  });

  final int checkIns;
  final Map<String, int> summary;
  final MapEntry<String, int>? leadingMood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mood_rounded, color: colors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Mood, without the judgment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              checkIns == 0
                  ? 'No mood check-ins for this month. Whenever you start is a good time.'
                  : '$checkIns check-in${checkIns == 1 ? '' : 's'} this month${leadingMood == null ? '' : ' · ${moodOptionFor(leadingMood!.key).label} showed up most'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 15),
              for (final entry in summary.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MoodBar(
                    label: moodOptionFor(entry.key).label,
                    count: entry.value,
                    total: checkIns,
                    color: moodOptionFor(entry.key).color,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  const _MoodBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: count / total,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 22,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
