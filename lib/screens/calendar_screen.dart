import 'package:flutter/material.dart';

import '../models/birthday_contact.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';
import '../models/mood_entry.dart';
import '../widgets/section_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime _selected = DateTime.now();

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _sameDay(date, DateTime.now());
  }

  bool _birthdayOccursOn(DateTime date, DateTime birthday) {
    final isLeapYear =
        date.year % 4 == 0 && (date.year % 100 != 0 || date.year % 400 == 0);
    final birthdayDay =
        birthday.month == DateTime.february && birthday.day == 29 && !isLeapYear
            ? 28
            : birthday.day;

    return date.month == birthday.month && date.day == birthdayDay;
  }

  void _previousMonth() {
    setState(() {
      _month = DateTime(
        _month.year,
        _month.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _month = DateTime(
        _month.year,
        _month.month + 1,
      );
    });
  }

  void _goToToday() {
    final today = DateTime.now();

    setState(() {
      _month = DateTime(
        today.year,
        today.month,
      );
      _selected = today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);

    final firstDay = DateTime(
      _month.year,
      _month.month,
      1,
    );

    final daysInMonth = DateTime(
      _month.year,
      _month.month + 1,
      0,
    ).day;

    final leadingBlanks = firstDay.weekday % 7;

    final dayTasks = app.tasks
        .where(
          (t) =>
              t.dueDate != null &&
              _sameDay(
                t.dueDate!,
                _selected,
              ),
        )
        .toList();

    final dayMood = app.moodForDay(_selected);

    final dayBirthdays = app.birthdayContacts
        .where(
          (contact) => _birthdayOccursOn(_selected, contact.date),
        )
        .toList();
    final isMyBirthday =
        app.birthday != null && _birthdayOccursOn(_selected, app.birthday!);

    final dayGoals = app.goals
        .where(
          (g) =>
              g.targetDate != null &&
              _sameDay(
                g.targetDate!,
                _selected,
              ),
        )
        .toList();

    final dayNotes = app.notes
        .where(
          (n) => _sameDay(
            n.createdAt,
            _selected,
          ),
        )
        .toList();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    final totalItems = dayTasks.length +
        dayGoals.length +
        dayNotes.length +
        dayBirthdays.length +
        (isMyBirthday ? 1 : 0) +
        (dayMood != null ? 1 : 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            32 + bottomInset,
          ),
          children: [
            // ==========================================================
            // HEADER
            // ==========================================================

            _buildHeader(
              context,
              totalItems,
            ),

            const SizedBox(height: 20),

            // ==========================================================
            // CALENDAR CARD
            // ==========================================================

            Container(
              padding: const EdgeInsets.fromLTRB(
                14,
                15,
                14,
                14,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.035,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMonthNavigation(context),
                  const SizedBox(height: 14),
                  _buildWeekdayHeader(context),
                  const SizedBox(height: 7),
                  _buildCalendarGrid(
                    context,
                    app,
                    leadingBlanks,
                    daysInMonth,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==========================================================
            // SELECTED DATE HEADER
            // ==========================================================

            _buildSelectedDateHeader(
              context,
              totalItems,
            ),

            const SizedBox(height: 13),

            if (isMyBirthday || dayBirthdays.isNotEmpty) ...[
              SectionCard(
                title: 'Birthdays',
                child: _buildBirthdaysContent(
                  context,
                  dayBirthdays,
                  isMyBirthday,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ==========================================================
            // MOOD
            // ==========================================================

            if (dayMood != null) ...[
              SectionCard(
                title: 'Mood',
                child: _buildMoodContent(
                  context,
                  dayMood,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ==========================================================
            // TASKS
            // ==========================================================

            SectionCard(
              title: 'Tasks & reminders',
              child: _buildTasksContent(
                context,
                dayTasks,
              ),
            ),

            const SizedBox(height: 10),

            // ==========================================================
            // GOALS
            // ==========================================================

            SectionCard(
              title: 'Goals due',
              child: _buildGoalsContent(
                context,
                dayGoals,
              ),
            ),

            const SizedBox(height: 10),

            // ==========================================================
            // NOTES
            // ==========================================================

            SectionCard(
              title: 'Notes created',
              child: _buildNotesContent(
                context,
                dayNotes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // HEADER
  // ====================================================================

  Widget _buildHeader(
    BuildContext context,
    int totalItems,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary,
                colors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(
                  alpha: 0.20,
                ),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendar',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Your life, organized by day',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (totalItems > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(
                alpha: 0.09,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: colors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  '$totalItems',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ====================================================================
  // MONTH NAVIGATION
  // ====================================================================

  Widget _buildMonthNavigation(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        _monthButton(
          context,
          icon: Icons.chevron_left_rounded,
          onTap: _previousMonth,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                formatMonthYear(_month),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Monthly overview',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _monthButton(
          context,
          icon: Icons.chevron_right_rounded,
          onTap: _nextMonth,
        ),
      ],
    );
  }

  Widget _monthButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.primary.withValues(
        alpha: 0.08,
      ),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.chevron_left_rounded,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // WEEKDAY HEADER
  // ====================================================================

  Widget _buildWeekdayHeader(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    const days = [
      'S',
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
    ];

    return Row(
      children: [
        for (int i = 0; i < days.length; i++)
          Expanded(
            child: Center(
              child: Text(
                days[i],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: i == 0 || i == 6
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ====================================================================
  // CALENDAR GRID
  // ====================================================================

  Widget _buildCalendarGrid(
    BuildContext context,
    dynamic app,
    int leadingBlanks,
    int daysInMonth,
  ) {
    final children = <Widget>[];

    for (int i = 0; i < leadingBlanks; i++) {
      children.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      children.add(
        _buildDayCell(
          context,
          app,
          day,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      crossAxisSpacing: 3,
      mainAxisSpacing: 3,
      childAspectRatio: 0.92,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  // ====================================================================
  // DAY CELL
  // ====================================================================

  Widget _buildDayCell(
    BuildContext context,
    dynamic app,
    int day,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final date = DateTime(
      _month.year,
      _month.month,
      day,
    );

    final isSelected = _sameDay(date, _selected);

    final isToday = _isToday(date);

    final hasTask = app.tasks.any(
      (t) => t.dueDate != null && _sameDay(t.dueDate!, date),
    );

    final hasGoal = app.goals.any(
      (g) => g.targetDate != null && _sameDay(g.targetDate!, date),
    );

    final hasNote = app.notes.any(
      (n) => _sameDay(n.createdAt, date),
    );

    final hasBirthday =
        (app.birthday != null && _birthdayOccursOn(date, app.birthday!)) ||
            app.birthdayContacts.any(
              (contact) => _birthdayOccursOn(date, contact.date),
            );

    final mood = app.moodForDay(date);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selected = date;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : isToday
                  ? colors.primary.withValues(
                      alpha: 0.07,
                    )
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isToday && !isSelected
              ? Border.all(
                  color: colors.primary.withValues(alpha: 0.35),
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? colors.onPrimary : colors.onSurface,
                fontWeight:
                    isToday || isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (mood != null)
              Icon(
                moodOptionFor(mood.mood).icon,
                size: 13,
                color: isSelected
                    ? colors.onPrimary
                    : moodOptionFor(mood.mood).color,
              ),
            _buildEventDots(
              context,
              hasTask: hasTask,
              hasGoal: hasGoal,
              hasNote: hasNote,
              hasBirthday: hasBirthday,
              selected: isSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDots(
    BuildContext context, {
    required bool hasTask,
    required bool hasGoal,
    required bool hasNote,
    required bool hasBirthday,
    required bool selected,
  }) {
    final colors = Theme.of(context).colorScheme;

    final dotColors = <Color>[];

    if (hasBirthday) {
      dotColors.add(selected ? colors.onPrimary : colors.tertiary);
    }

    if (hasTask) {
      dotColors.add(
        selected ? colors.onPrimary : const Color(0xFF4D8FE7),
      );
    }

    if (hasGoal) {
      dotColors.add(
        selected ? colors.onPrimary : const Color(0xFFE0A52B),
      );
    }

    if (hasNote) {
      dotColors.add(
        selected ? colors.onPrimary : const Color(0xFF9A6BDB),
      );
    }

    if (dotColors.isEmpty) {
      return const SizedBox(
        height: 5,
      );
    }

    return SizedBox(
      height: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final color in dotColors.take(4))
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(
                horizontal: 1,
              ),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBirthdaysContent(
    BuildContext context,
    List<BirthdayContact> contacts,
    bool isMyBirthday,
  ) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[];

    if (isMyBirthday) {
      children.add(
        const ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(Icons.cake_rounded),
          title: Text(
            'Your birthday',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    children.addAll(
      contacts.map(
        (contact) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(Icons.cake_outlined, color: colors.tertiary),
          title: Text(
            contact.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(contact.relation),
        ),
      ),
    );

    return Column(children: children);
  }

  // ====================================================================
  // SELECTED DATE HEADER
  // ====================================================================

  Widget _buildSelectedDateHeader(
    BuildContext context,
    int totalItems,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final today = _isToday(_selected);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                today ? 'Today' : formatDate(_selected),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              if (today)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    formatDate(_selected),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!today)
          OutlinedButton.icon(
            onPressed: _goToToday,
            icon: const Icon(
              Icons.today_rounded,
              size: 16,
            ),
            label: const Text('Today'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        if (totalItems > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ====================================================================
  // MOOD
  // ====================================================================

  Widget _buildMoodContent(
    BuildContext context,
    MoodEntry mood,
  ) {
    final option = moodOptionFor(mood.mood);

    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: option.color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: option.color.withValues(
                alpha: 0.13,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              option.icon,
              color: option.color,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (mood.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    mood.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // TASKS
  // ====================================================================

  Widget _buildTasksContent(
    BuildContext context,
    List<dynamic> tasks,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (tasks.isEmpty) {
      return _emptyMessage(
        context,
        Icons.task_alt_rounded,
        'No tasks or reminders due',
        'You have nothing scheduled for this day.',
      );
    }

    return Column(
      children: tasks.map<Widget>((t) {
        final completed = t.completed;
        final dueTime = t.dueTimeMinutes;
        final subtitleParts = <String>[];
        if (dueTime != null) {
          final hour = dueTime ~/ 60;
          final minute = dueTime % 60;
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour % 12 == 0 ? 12 : hour % 12;
          subtitleParts.add(
            '$displayHour:${minute.toString().padLeft(2, '0')} $period',
          );
        }
        if (t.reminderEnabled) {
          subtitleParts.add('Reminder on');
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          leading: Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color:
                completed ? const Color(0xFF2FB380) : colors.onSurfaceVariant,
          ),
          title: Text(
            t.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              decoration: completed ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: subtitleParts.isEmpty
              ? null
              : Text(
                  subtitleParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
        );
      }).toList(),
    );
  }

  // ====================================================================
  // GOALS
  // ====================================================================

  Widget _buildGoalsContent(
    BuildContext context,
    List<dynamic> goals,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (goals.isEmpty) {
      return _emptyMessage(
        context,
        Icons.flag_outlined,
        'No goals due',
        'There are no goal deadlines on this day.',
      );
    }

    return Column(
      children: goals.map<Widget>((g) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: colors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  g.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${g.progress}%',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ====================================================================
  // NOTES
  // ====================================================================

  Widget _buildNotesContent(
    BuildContext context,
    List<dynamic> notes,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (notes.isEmpty) {
      return _emptyMessage(
        context,
        Icons.sticky_note_2_outlined,
        'No notes',
        'No notes were created on this day.',
      );
    }

    return Column(
      children: notes.map<Widget>((n) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sticky_note_2_rounded,
                  color: colors.secondary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  n.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ====================================================================
  // EMPTY MESSAGE
  // ====================================================================

  Widget _emptyMessage(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.3,
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
