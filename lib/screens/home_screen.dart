import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../services/app_state.dart';
import '../models/mood_entry.dart';
import '../utils/formatters.dart';
import '../widgets/quick_add_sheet.dart';
import 'tasks_screen.dart';
import 'mood_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);

    final now = DateTime.now();
    final quote = kMotivationalQuotes[now.day % kMotivationalQuotes.length];

    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;

    final hasBirthday =
        app.isMyBirthdayToday || app.todayBirthdayContacts.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.surface,

      // ============================================================
      // QUICK ADD
      // ============================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickAddSheet(context),
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Quick Add',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          bottomPadding,
        ),
        children: [
          // HEADER
          _buildHeader(
            context,
            app,
            now,
          ),

          const SizedBox(height: 18),

          // BIRTHDAY
          if (hasBirthday) ...[
            _buildBirthdayCard(
              context,
              app,
              now,
            ),
            const SizedBox(height: 14),
          ],

          // BALANCE
          _buildBalanceCard(
            context,
            app,
          ),

          const SizedBox(height: 12),

          // EXPENSE STATS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  label: "Today's Expense",
                  value: formatMoney(
                    app.todayExpense,
                    app.currency,
                  ),
                  icon: Icons.today_rounded,
                  color: kExpenseColorLocal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  label: 'This Month',
                  value: formatMoney(
                    app.monthExpense,
                    app.currency,
                  ),
                  icon: Icons.calendar_month_rounded,
                  color: kExpenseColorLocal,
                ),
              ),
            ],
          ),

          // MONTH OVER MONTH
          if (app.monthOverMonthChangePercent != null) ...[
            const SizedBox(height: 12),
            _buildMonthlyChangeCard(
              context,
              app.monthOverMonthChangePercent!,
            ),
          ],

          // OVER BUDGET
          if (app.overBudgetCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildBudgetWarningCard(
              context,
              app.overBudgetCategories.length,
            ),
          ],

          const SizedBox(height: 14),

          // TODAY'S MOOD
          _buildMoodCard(
            context,
            app.todayMood,
          ),

          const SizedBox(height: 14),

          // TASKS
          _buildTasksCard(
            context,
            app,
          ),

          const SizedBox(height: 14),

          // AI
          _buildAiCard(context),

          const SizedBox(height: 14),

          // DAILY QUOTE
          _buildQuoteCard(
            context,
            quote,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader(
    BuildContext context,
    AppState app,
    DateTime now,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                app.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      formatDate(now),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // STREAK
        if (app.streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 20,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${app.streak}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      'day streak',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ================================================================
  // BIRTHDAY CARD
  // ================================================================

  Widget _buildBirthdayCard(
    BuildContext context,
    AppState app,
    DateTime now,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.13),
            colors.secondary.withOpacity(0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.primary.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cake_rounded,
                  color: colors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  app.isMyBirthdayToday
                      ? 'Happy Birthday! ðŸŽ‰'
                      : 'Todayâ€™s Birthdays',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (app.isMyBirthdayToday) ...[
            Text(
              'Happy birthday, ${app.userName}! ðŸŽ‰',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (app.age != null) ...[
              const SizedBox(height: 4),
              Text(
                'You are ${app.age} years young today.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
          if (app.todayBirthdayContacts.isNotEmpty) ...[
            if (app.isMyBirthdayToday) const SizedBox(height: 14),
            Text(
              app.isMyBirthdayToday
                  ? 'Also celebrating today'
                  : 'People celebrating today',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...app.todayBirthdayContacts.map(
              (contact) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${contact.name} (${contact.relation})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'turns ${contact.ageOn(now)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // BALANCE CARD
  // ================================================================

  Widget _buildBalanceCard(
    BuildContext context,
    AppState app,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isPositive = app.totalBalance >= 0;

    final balanceColor = isPositive ? kIncomeColorLocal : kExpenseColorLocal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.12),
            colors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: colors.primary.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: balanceColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: balanceColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatMoney(
                    app.totalBalance,
                    app.currency,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STAT CARD
  // ================================================================

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: 124,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MONTHLY CHANGE
  // ================================================================

  Widget _buildMonthlyChangeCard(
    BuildContext context,
    double change,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final increased = change > 0;

    final accent = increased ? kExpenseColorLocal : kIncomeColorLocal;

    final icon =
        increased ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    final text = '${change.abs().toStringAsFixed(0)}% '
        '${increased ? 'more' : 'less'} spending vs last month';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: accent.withOpacity(0.13),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BUDGET WARNING
  // ================================================================

  Widget _buildBudgetWarningCard(
    BuildContext context,
    int count,
  ) {
    final theme = Theme.of(context);

    const accent = Colors.red;

    final categoryText = count == 1 ? 'category is' : 'categories are';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: accent.withOpacity(0.13),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 19,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count $categoryText over budget this month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MOOD CARD
  // ================================================================

  Widget _buildMoodCard(
    BuildContext context,
    MoodEntry? todayMood,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // IMPORTANT:
    // Keep the nullable MoodEntry and MoodOption properly promoted.
    final mood = todayMood;

    final moodOption = mood == null ? null : moodOptionFor(mood.mood);

    final hasMood = mood != null && moodOption != null;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MoodScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withOpacity(0.10),
              colors.secondary.withOpacity(0.045),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colors.primary.withOpacity(0.10),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: hasMood
                    ? moodOption.color.withOpacity(0.13)
                    : colors.primary.withOpacity(0.11),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                hasMood ? moodOption.icon : Icons.favorite_outline_rounded,
                color: hasMood ? moodOption.color : colors.primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Mood",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasMood
                        ? (mood.note.isEmpty ? moodOption.label : mood.note)
                        : "Tap to log today's mood",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          hasMood ? moodOption.color : colors.onSurfaceVariant,
                      fontWeight: hasMood ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // TASKS CARD
  // ================================================================

  Widget _buildTasksCard(
    BuildContext context,
    AppState app,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final pending = app.tasks.where((task) => !task.completed).take(4).toList();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.7),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
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
                      'Pending Tasks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      pending.isEmpty
                          ? 'You are all caught up'
                          : '${pending.length} task${pending.length == 1 ? '' : 's'} waiting',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TasksScreen(),
                    ),
                  );
                },
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            _buildEmptyTasks(context)
          else
            Column(
              children: pending.map((task) {
                return _buildTaskTile(
                  context,
                  app,
                  task,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // TASK TILE
  // ================================================================

  Widget _buildTaskTile(
    BuildContext context,
    AppState app,
    dynamic task,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => app.toggleTask(task.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: Row(
            children: [
              Checkbox(
                value: task.completed,
                onChanged: (_) {
                  app.toggleTask(task.id);
                },
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              formatDate(task.dueDate!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY TASKS
  // ================================================================

  Widget _buildEmptyTasks(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 34,
            color: colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'No pending tasks',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Nice work. You are all caught up.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // AI CARD
  // ================================================================

  Widget _buildAiCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AiChatScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withOpacity(0.11),
              colors.tertiary.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colors.primary.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colors.primary,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask AI',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Got a question? Ask anything.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }

  // ================================================================
  // DAILY QUOTE
  // ================================================================

  Widget _buildQuoteCard(
    BuildContext context,
    String quote,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.amber,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily thought',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  quote,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: colors.onSurfaceVariant,
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

// ==================================================================
// LOCAL COLORS
// ==================================================================

const kIncomeColorLocal = Color(0xFF2FB380);
const kExpenseColorLocal = Color(0xFFE2574C);
