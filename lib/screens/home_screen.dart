import 'package:flutter/material.dart';

import '../models/day_signals.dart';
import '../models/mood_entry.dart';
import '../models/task.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';
import '../widgets/quick_add_sheet.dart';
import 'calendar_screen.dart';
import 'monthly_review_screen.dart';
import 'mood_screen.dart';
import 'present_mode_screen.dart';
import 'reminders_screen.dart';
import 'insights_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final now = DateTime.now();
    final tasks = app.tasks.where((task) => !task.completed).toList()
      ..sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        final dateOrder = a.dueDate!.compareTo(b.dueDate!);
        if (dateOrder != 0) return dateOrder;
        return (a.dueTimeMinutes ?? 24 * 60)
            .compareTo(b.dueTimeMinutes ?? 24 * 60);
      });
    final focusTasks = tasks.take(3).toList();
    final todaySignals = app.todaySignals;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quick add'),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(now),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        app.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatDate(now),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (app.streak > 0) _StreakBadge(streak: app.streak),
              ],
            ),
            const SizedBox(height: 20),
            _TodayHero(
              name: app.userName,
              tasksLeft: tasks.length,
              moodLogged: app.todayMood != null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PresentModeScreen(),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              title: 'Check in with yourself',
              subtitle: 'No perfect streaks needed. Just notice.',
              trailing: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodScreen()),
                ),
                child: Text(app.todayMood == null ? 'Check in' : 'Edit'),
              ),
            ),
            const SizedBox(height: 10),
            _MoodCard(
              mood: app.todayMood,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoodScreen()),
              ),
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              title: 'Your focus, your pace',
              subtitle: 'Only the signals you chose to log.',
              trailing: IconButton(
                tooltip: 'Open daily signals',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InsightsScreen(),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            const SizedBox(height: 10),
            _DailySignalsCard(
              signals: todaySignals,
              onOpenInsights: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InsightsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              title: 'A few things to focus on',
              subtitle: tasks.isEmpty
                  ? 'You have room to choose what matters.'
                  : '${tasks.length} open task${tasks.length == 1 ? '' : 's'}',
              trailing: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TasksScreen()),
                ),
                child: const Text('See all'),
              ),
            ),
            const SizedBox(height: 10),
            if (focusTasks.isEmpty)
              _EmptyFocusCard(
                onAdd: () => showQuickAddSheet(context),
              )
            else
              ...focusTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskFocusCard(
                    task: task,
                    onToggle: () => app.toggleTask(task.id),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const _SectionHeading(
              title: 'Make space for what matters',
              subtitle: 'Your calendar, reminders, and monthly reset.',
            ),
            const SizedBox(height: 10),
            _Shortcuts(
              onCalendar: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              ),
              onReminders: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
              onReview: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MonthlyReviewScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.name,
    required this.tasksLeft,
    required this.moodLogged,
    required this.onTap,
  });

  final String name;
  final int tasksLeft;
  final bool moodLogged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final darkerPrimary =
        Color.lerp(colors.primary, Colors.black, .16) ?? colors.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, darkerPrimary],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  top: -54,
                  right: -34,
                  child: IgnorePointer(
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .08),
                          width: 26,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(21),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A MOMENT FOR YOU',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: .82),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.15,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_outward_rounded,
                            color: Colors.white.withValues(alpha: .9),
                            size: 19,
                          ),
                        ],
                      ),
                      const SizedBox(height: 19),
                      Text(
                        _headline(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.7,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _subhead(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: .82),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 19),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _HeroDetail(
                                label: 'OPEN TASKS',
                                value: '$tasksLeft',
                                icon: Icons.check_circle_outline_rounded,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 34,
                              color: Colors.white.withValues(alpha: .2),
                            ),
                            Expanded(
                              child: _HeroDetail(
                                label: 'TODAY’S MOOD',
                                value: moodLogged ? 'Checked in' : 'Not yet',
                                icon: moodLogged
                                    ? Icons.favorite_rounded
                                    : Icons.spa_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _headline() {
    if (tasksLeft == 0 && moodLogged) return 'You showed up for yourself.';
    if (tasksLeft == 0) return 'A little breathing room.';
    if (tasksLeft == 1) return 'One thing at a time, $name.';
    return 'Small steps still move you.';
  }

  String _subhead() {
    if (tasksLeft == 0) return 'Check in, reset, or enjoy the open space.';
    return '$tasksLeft open task${tasksLeft == 1 ? '' : 's'} — pick one and start there.';
  }
}

class _HeroDetail extends StatelessWidget {
  const _HeroDetail({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: .9)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: colors.tertiary),
          const SizedBox(width: 5),
          Text(
            '$streak',
            style: TextStyle(
              color: colors.onTertiaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood, required this.onTap});

  final MoodEntry? mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final option = mood == null ? null : moodOptionFor(mood!.mood);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      (option?.color ?? colors.primary).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  option?.icon ?? Icons.mood_rounded,
                  color: option?.color ?? colors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option == null ? 'How are you feeling?' : option.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mood?.note.isNotEmpty == true
                          ? mood!.note
                          : 'A private, no-pressure check-in.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailySignalsCard extends StatefulWidget {
  const _DailySignalsCard({
    required this.signals,
    required this.onOpenInsights,
  });

  final DaySignals? signals;
  final VoidCallback onOpenInsights;

  @override
  State<_DailySignalsCard> createState() => _DailySignalsCardState();
}

class _DailySignalsCardState extends State<_DailySignalsCard> {
  bool _savingWater = false;

  Future<void> _addWater(int amountMl) async {
    if (_savingWater) return;
    final app = AppScope.of(context);
    final current = app.todaySignals;
    final now = DateTime.now();

    setState(() => _savingWater = true);
    try {
      await app.saveDaySignals(
        current == null
            ? DaySignals(
                dateKey: daySignalsKey(now),
                waterMl: amountMl,
              )
            : current.copyWith(
                waterMl: (current.waterMl ?? 0) + amountMl,
              ),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save water intake: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save water intake: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingWater = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onOpenInsights,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final metricWidth = (constraints.maxWidth - 14) / 2;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 18,
                    children: [
                      SizedBox(
                        width: metricWidth,
                        child: _SignalMetric(
                          icon: Icons.water_drop_outlined,
                          label: 'Water',
                          value: widget.signals?.waterMl == null
                              ? 'Not logged'
                              : '${widget.signals!.waterMl} ml',
                          color: colors.tertiary,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: _SignalMetric(
                          icon: Icons.directions_run_rounded,
                          label: 'Movement',
                          value: widget.signals?.workoutMinutes == null
                              ? 'Not logged'
                              : '${widget.signals!.workoutMinutes} min',
                          color: colors.primary,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: _SignalMetric(
                          icon: Icons.bedtime_outlined,
                          label: 'Sleep quality',
                          value: widget.signals?.sleepQuality == null
                              ? 'Not logged'
                              : '${widget.signals!.sleepQuality}/5',
                          color: colors.secondary,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: _SignalMetric(
                          icon: Icons.center_focus_strong_rounded,
                          label: 'Focus score',
                          value: widget.signals?.focusScore == null
                              ? 'Not logged'
                              : '${widget.signals!.focusScore}/10',
                          color: colors.primary,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: _SignalMetric(
                          icon: Icons.work_outline_rounded,
                          label: 'Deep work',
                          value: widget.signals?.deepWorkCompleted == null
                              ? 'Not logged'
                              : widget.signals!.deepWorkCompleted!
                                  ? 'Completed'
                                  : 'Not completed',
                          color: colors.tertiary,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('250 ml water'),
                    onPressed: _savingWater ? null : () => _addWater(250),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('500 ml water'),
                    onPressed: _savingWater ? null : () => _addWater(500),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Log more'),
                    onPressed: widget.onOpenInsights,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View focus & energy insights',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: colors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalMetric extends StatelessWidget {
  const _SignalMetric({
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TaskFocusCard extends StatelessWidget {
  const _TaskFocusCard({required this.task, required this.onToggle});

  final AppTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.dueDate!.day != DateTime.now().day;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onToggle,
        leading: IconButton(
          tooltip: 'Complete ${task.title}',
          onPressed: onToggle,
          icon: Icon(
            Icons.circle_outlined,
            color: colors.primary,
          ),
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          task.dueDate == null
              ? 'No due date'
              : '${formatDate(task.dueDate!)}${task.dueTimeMinutes == null ? '' : ' · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: task.dueTimeMinutes! ~/ 60, minute: task.dueTimeMinutes! % 60))}'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: isOverdue ? colors.error : null),
        ),
        trailing: task.reminderEnabled
            ? Icon(
                Icons.notifications_active_outlined,
                size: 19,
                color: colors.primary,
              )
            : null,
      ),
    );
  }
}

class _EmptyFocusCard extends StatelessWidget {
  const _EmptyFocusCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.spa_outlined, color: colors.primary, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('A clear list is a valid kind of progress.'),
            ),
            TextButton(onPressed: onAdd, child: const Text('Add one')),
          ],
        ),
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({
    required this.onCalendar,
    required this.onReminders,
    required this.onReview,
  });

  final VoidCallback onCalendar;
  final VoidCallback onReminders;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _ShortcutTile(
            icon: Icons.calendar_month_rounded,
            label: 'Calendar',
            color: colors.primary,
            onTap: onCalendar,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ShortcutTile(
            icon: Icons.notifications_active_outlined,
            label: 'Reminders',
            color: colors.secondary,
            onTap: onReminders,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ShortcutTile(
            icon: Icons.auto_awesome_outlined,
            label: 'Monthly',
            color: colors.tertiary,
            onTap: onReview,
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
