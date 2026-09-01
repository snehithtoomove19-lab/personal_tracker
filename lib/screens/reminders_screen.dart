import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../utils/formatters.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final soon = today.add(const Duration(days: 30));

    // ============================================================
    // TASKS
    // ============================================================

    final upcomingTasks = app.tasks
        .where(
          (t) =>
              !t.completed &&
              t.dueDate != null &&
              !t.dueDate!.isBefore(today) &&
              t.dueDate!.isBefore(soon),
        )
        .toList()
      ..sort(
        (a, b) => a.dueDate!.compareTo(b.dueDate!),
      );

    final overdueTasks = app.overdueTasks;

    final noDateTasks = app.tasks
        .where(
          (t) => !t.completed && t.dueDate == null,
        )
        .toList();

    // ============================================================
    // GOALS
    // ============================================================

    final upcomingGoals = app.goals
        .where(
          (g) =>
              !g.completed &&
              g.targetDate != null &&
              !g.targetDate!.isBefore(today) &&
              g.targetDate!.isBefore(soon),
        )
        .toList()
      ..sort(
        (a, b) => a.targetDate!.compareTo(b.targetDate!),
      );

    // ============================================================
    // BIRTHDAYS
    // ============================================================

    final upcomingBirthdayContacts = app.birthdayContacts
        .where(
          (c) => c.daysUntil(now) <= 30,
        )
        .toList()
      ..sort(
        (a, b) => a.daysUntil(now).compareTo(
              b.daysUntil(now),
            ),
      );

    // ============================================================
    // BILLS
    // ============================================================

    final billCategoryTx = app.transactions
        .where(
          (t) => t.category == 'Bills',
        )
        .toList()
      ..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    // ============================================================
    // RECURRING TRANSACTIONS
    // ============================================================

    final recurringSeries = <String, dynamic>{};

    for (final t in app.transactions.where(
      (t) => t.repeat.name != 'none',
    )) {
      final key = '${t.type.name}|${t.category}|${t.amount}|${t.paymentMethod}';

      if (!recurringSeries.containsKey(key) ||
          (recurringSeries[key].date as DateTime).isBefore(t.date)) {
        recurringSeries[key] = t;
      }
    }

    final recurringList = recurringSeries.values.toList();

    final hasReminders = overdueTasks.isNotEmpty ||
        upcomingTasks.isNotEmpty ||
        upcomingGoals.isNotEmpty ||
        upcomingBirthdayContacts.isNotEmpty ||
        noDateTasks.isNotEmpty ||
        recurringList.isNotEmpty ||
        billCategoryTx.isNotEmpty;

    // ============================================================
    // HELPERS
    // ============================================================

    String taskDueLabel(dynamic task) {
      final dateStr = formatDate(task.dueDate!);

      if (task.dueTimeMinutes != null) {
        final h = task.dueTimeMinutes ~/ 60;
        final m = task.dueTimeMinutes % 60;

        final period = h >= 12 ? 'PM' : 'AM';
        final displayHour = h % 12 == 0 ? 12 : h % 12;

        return '$dateStr â€¢ $displayHour:${m.toString().padLeft(2, '0')} $period';
      }

      return dateStr;
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom + 32;

    final totalReminders = overdueTasks.length +
        upcomingTasks.length +
        upcomingGoals.length +
        upcomingBirthdayContacts.length;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminders',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 21,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Stay ahead of what matters',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary,
                    colors.primary.withOpacity(0.72),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          bottomPadding,
        ),
        children: [
          // ========================================================
          // HERO SUMMARY
          // ========================================================

          _ReminderSummary(
            overdueCount: overdueTasks.length,
            upcomingCount: upcomingTasks.length + upcomingGoals.length,
            birthdayCount: upcomingBirthdayContacts.length,
            totalReminders: totalReminders,
            hasReminders: hasReminders,
          ),

          const SizedBox(height: 24),

          // ========================================================
          // OVERDUE
          // ========================================================

          if (overdueTasks.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.priority_high_rounded,
              title: 'Needs Attention',
              subtitle:
                  '${overdueTasks.length} overdue task${overdueTasks.length == 1 ? '' : 's'}',
              color: Colors.red,
            ),
            const SizedBox(height: 11),
            _ReminderCard(
              color: Colors.red,
              children: overdueTasks.map(
                (task) {
                  return _ReminderTile(
                    icon: Icons.warning_amber_rounded,
                    title: task.title,
                    subtitle: 'Was due ${formatDate(task.dueDate!)}',
                    color: Colors.red,
                    badge: 'OVERDUE',
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 22),
          ],

          // ========================================================
          // UPCOMING TASKS
          // ========================================================

          if (upcomingTasks.isNotEmpty) ...[
            const _SectionHeader(
              icon: Icons.task_alt_rounded,
              title: 'Upcoming Tasks',
              subtitle: 'Due within the next 30 days',
              color: Colors.blue,
            ),
            const SizedBox(height: 11),
            _ReminderCard(
              color: Colors.blue,
              children: upcomingTasks.map(
                (task) {
                  return _ReminderTile(
                    icon: Icons.task_alt_rounded,
                    title: task.title,
                    subtitle: 'Due ${taskDueLabel(task)}',
                    color: Colors.blue,
                    badge: 'UPCOMING',
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 22),
          ],

          // ========================================================
          // GOALS
          // ========================================================

          if (upcomingGoals.isNotEmpty) ...[
            const _SectionHeader(
              icon: Icons.flag_rounded,
              title: 'Goal Deadlines',
              subtitle: 'Targets coming up soon',
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 11),
            _ReminderCard(
              color: Colors.deepPurple,
              children: upcomingGoals.map(
                (goal) {
                  return _ReminderTile(
                    icon: Icons.flag_rounded,
                    title: goal.title,
                    subtitle: 'Target ${formatDate(goal.targetDate!)}',
                    color: Colors.deepPurple,
                    badge: 'GOAL',
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 22),
          ],

          // ========================================================
          // BIRTHDAYS
          // ========================================================

          if (upcomingBirthdayContacts.isNotEmpty) ...[
            const _SectionHeader(
              icon: Icons.cake_rounded,
              title: 'Upcoming Birthdays',
              subtitle: 'People you should remember',
              color: Colors.pink,
            ),
            const SizedBox(height: 11),
            _ReminderCard(
              color: Colors.pink,
              children: upcomingBirthdayContacts.map(
                (contact) {
                  final days = contact.daysUntil(now);
                  final next = contact.nextOccurrence(now);
                  final age = contact.ageOn(next);

                  final label = days == 0
                      ? 'Today â€¢ turns $age'
                      : days == 1
                          ? 'Tomorrow â€¢ turns $age'
                          : '$days days â€¢ turns $age';

                  return _ReminderTile(
                    icon: Icons.cake_rounded,
                    title: '${contact.name} â€¢ ${contact.relation}',
                    subtitle: '${formatDateShort(contact.date)} â€¢ $label',
                    color: Colors.pink,
                    badge: days == 0 ? 'TODAY' : '$days DAYS',
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 22),
          ],

          // ========================================================
          // TASKS WITHOUT DATES
          // ========================================================

          if (noDateTasks.isNotEmpty) ...[
            const _SectionHeader(
              icon: Icons.event_busy_rounded,
              title: 'Tasks Without Dates',
              subtitle: 'Add a due date to get reminders',
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 11),
            _ReminderCard(
              color: Colors.blueGrey,
              children: noDateTasks.map(
                (task) {
                  return _ReminderTile(
                    icon: Icons.event_busy_rounded,
                    title: task.title,
                    subtitle: 'No due date set',
                    color: Colors.blueGrey,
                    badge: 'NO DATE',
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 22),
          ],

          // ========================================================
          // RECURRING
          // ========================================================

          if (recurringList.isNotEmpty) ...[
            const _SectionHeader(
              icon: Icons.autorenew_rounded,
              title: 'Recurring Transactions',
              subtitle: 'Your repeating money activity',
              color: Colors.indigo,
            ),
            const SizedBox(height: 11),
            _ReminderCard(
              color: Colors.indigo,
              children: recurringList.map(
                (transaction) {
                  return _ReminderTile(
                    icon: Icons.autorenew_rounded,
                    title:
                        '${transaction.category} â€¢ ${transaction.repeat.name}',
                    subtitle:
                        'Last on ${formatDate(transaction.date)} â€¢ ${app.currency}${transaction.amount}',
                    color: Colors.indigo,
                    badge: 'REPEAT',
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 22),
          ],

          // ========================================================
          // BILLS
          // ========================================================

          if (billCategoryTx.isNotEmpty) ...[
            const _SectionHeader(
              icon: Icons.receipt_long_rounded,
              title: 'Recent Bills',
              subtitle: 'Your latest bill payments',
              color: Colors.orange,
            ),
            const SizedBox(height: 11),
            _ReminderCard(
              color: Colors.orange,
              children: billCategoryTx.take(5).map(
                (transaction) {
                  return _ReminderTile(
                    icon: Icons.receipt_long_rounded,
                    title: transaction.category,
                    subtitle: formatDate(transaction.date),
                    color: Colors.orange,
                    badge: 'BILL',
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 22),
          ],

          // ========================================================
          // EMPTY STATE
          // ========================================================

          if (!hasReminders) const _AllCaughtUp(),

          const SizedBox(height: 2),

          // ========================================================
          // INFORMATION CARD
          // ========================================================

          const _InfoCard(),
        ],
      ),
    );
  }
}

// ==================================================================
// SUMMARY / HERO
// ==================================================================

class _ReminderSummary extends StatelessWidget {
  final int overdueCount;
  final int upcomingCount;
  final int birthdayCount;
  final int totalReminders;
  final bool hasReminders;

  const _ReminderSummary({
    required this.overdueCount,
    required this.upcomingCount,
    required this.birthdayCount,
    required this.totalReminders,
    required this.hasReminders,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.primary.withOpacity(0.76),
            colors.secondary.withOpacity(0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.24),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasReminders
                          ? '$totalReminders things to watch'
                          : 'Youâ€™re all caught up',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasReminders
                          ? 'Hereâ€™s what deserves your attention'
                          : 'Nothing urgent right now',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  value: '$overdueCount',
                  label: 'Overdue',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  value: '$upcomingCount',
                  label: 'Upcoming',
                  icon: Icons.event_available_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  value: '$birthdayCount',
                  label: 'Birthdays',
                  icon: Icons.cake_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.78),
            size: 17,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SECTION HEADER
// ==================================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.16),
                color.withOpacity(0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// REMINDER CARD
// ==================================================================

class _ReminderCard extends StatelessWidget {
  final Color color;
  final List<Widget> children;

  const _ReminderCard({
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: color.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: _addDividers(children),
      ),
    );
  }

  List<Widget> _addDividers(List<Widget> items) {
    final result = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);

      if (i != items.length - 1) {
        result.add(
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: color.withOpacity(0.07),
          ),
        );
      }
    }

    return result;
  }
}

// ==================================================================
// REMINDER TILE
// ==================================================================

class _ReminderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String badge;

  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.14),
                  color.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(
              maxWidth: 72,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: color.withOpacity(0.08),
              ),
            ),
            child: Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.45,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// ALL CAUGHT UP
// ==================================================================

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.07),
            Colors.green.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colors.primary.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.10),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.10),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.green,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "You're all caught up!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Nothing needs your attention right now.\nEnjoy the moment!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// INFORMATION CARD
// ==================================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.42),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: colors.outline.withOpacity(0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
              color: colors.primary.withOpacity(0.72),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Reminders are automatically generated from your tasks, goals, birthdays, recurring transactions, and bills. Turn on "Welcome-Back Summary" in Settings for a quick overview when you open the app.',
              style: TextStyle(
                color: colors.onSurface.withOpacity(0.52),
                fontSize: 10,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
