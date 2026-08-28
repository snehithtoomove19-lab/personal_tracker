
import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';

class MonthlyReviewScreen extends StatefulWidget {
  const MonthlyReviewScreen({super.key});

  @override
  State<MonthlyReviewScreen> createState() => _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends State<MonthlyReviewScreen> {
  DateTime _month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    return _month.year == _currentMonth.year &&
        _month.month == _currentMonth.month;
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
    if (_isCurrentMonth) return;

    final next = DateTime(
      _month.year,
      _month.month + 1,
    );

    if (next.isAfter(_currentMonth)) return;

    setState(() {
      _month = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);

    final review = app.monthlyReview(
      month: _month,
    );

    final moodSummary = _parseMoodSummary(
      review['moodSummary'],
    );

    final topMood = _getTopMood(moodSummary);

    // moodOptionFor() is defined in models/mood_entry.dart
    final topMoodOption = topMood == null
        ? null
        : moodOptionFor(topMood.key);

    final totalSpent = _toDouble(
      review['totalSpent'],
    );

    final totalIncome = _toDouble(
      review['totalIncome'],
    );

    final tasksCompleted = _toInt(
      review['tasksCompleted'],
    );

    final goalsAchieved = _toInt(
      review['goalsAchieved'],
    );

    final productiveDay = review['mostProductiveDay'];

    final savings = totalIncome - totalSpent;
    final savingsPositive = savings >= 0;

    final bottomInset =
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                18,
                14,
                18,
                bottomInset + 32,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildTopBar(context),

                    const SizedBox(height: 18),

                    _buildHero(
                      context,
                      totalSpent,
                      totalIncome,
                      savings,
                      savingsPositive,
                      app.currency,
                    ),

                    const SizedBox(height: 18),

                    _buildMonthSelector(context),

                    const SizedBox(height: 26),

                    _buildSectionTitle(
                      context,
                      'Money snapshot',
                      Icons.account_balance_wallet_rounded,
                    ),

                    const SizedBox(height: 12),

                    _buildMoneyGrid(
                      context,
                      totalSpent,
                      totalIncome,
                      savings,
                      savingsPositive,
                      app.currency,
                    ),

                    const SizedBox(height: 28),

                    _buildSectionTitle(
                      context,
                      'Life at a glance',
                      Icons.auto_awesome_rounded,
                    ),

                    const SizedBox(height: 12),

                    _buildActivityCard(
                      context,
                      tasksCompleted,
                      goalsAchieved,
                      productiveDay,
                    ),

                    const SizedBox(height: 28),

                    _buildSectionTitle(
                      context,
                      'Mood of the month',
                      Icons.mood_rounded,
                    ),

                    const SizedBox(height: 12),

                    _buildMoodCard(
                      context,
                      topMood,
                      topMoodOption,
                      moodSummary,
                    ),

                    const SizedBox(height: 28),

                    _buildInsightCard(
                      context,
                      totalSpent,
                      totalIncome,
                      savings,
                      savingsPositive,
                      tasksCompleted,
                      goalsAchieved,
                      topMoodOption,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withValues(alpha: 0.16),
                colors.secondary.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.insights_rounded,
            color: colors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Review',
                style:
                    theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Your month, beautifully summarized',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HERO
  // ===========================================================================

  Widget _buildHero(
    BuildContext context,
    double spent,
    double income,
    double savings,
    bool savingsPositive,
    String currency,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(
              alpha: 0.22,
            ),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.16,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  formatMonthYear(_month),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            savingsPositive
                ? 'You finished the month in the green.'
                : 'Your spending was higher than your income.',
            style:
                theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.12,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            savingsPositive
                ? 'Great work keeping your finances under control.'
                : 'Review your expenses and find opportunities to save.',
            style:
                theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(
                alpha: 0.82,
              ),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Income',
                  value: formatMoney(
                    income,
                    currency,
                  ),
                ),
              ),
              _heroDivider(),
              Expanded(
                child: _HeroMetric(
                  label: 'Spent',
                  value: formatMoney(
                    spent,
                    currency,
                  ),
                ),
              ),
              _heroDivider(),
              Expanded(
                child: _HeroMetric(
                  label: savingsPositive
                      ? 'Saved'
                      : 'Deficit',
                  value: formatMoney(
                    savings.abs(),
                    currency,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 38,
      color: Colors.white.withValues(
        alpha: 0.20,
      ),
    );
  }

  // ===========================================================================
  // MONTH SELECTOR
  // ===========================================================================

  Widget _buildMonthSelector(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest
            .withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: _previousMonth,
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  formatMonthYear(_month),
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isCurrentMonth
                      ? 'Current month'
                      : 'Monthly overview',
                  style:
                      theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: _isCurrentMonth
                ? 'Current month'
                : 'Next month',
            onPressed:
                _isCurrentMonth ? null : _nextMonth,
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION TITLE
  // ===========================================================================

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primary.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 18,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style:
              theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MONEY GRID
  // ===========================================================================

  Widget _buildMoneyGrid(
    BuildContext context,
    double spent,
    double income,
    double savings,
    bool savingsPositive,
    String currency,
  ) {
    final balancePercentage =
        income == 0 ? null : (savings / income) * 100;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.27,
      children: [
        _MetricCard(
          icon: Icons.arrow_upward_rounded,
          title: 'Total Spent',
          value: formatMoney(
            spent,
            currency,
          ),
          description: 'Expenses this month',
          iconColor:
              const Color(0xFFE2574C),
        ),
        _MetricCard(
          icon: Icons.arrow_downward_rounded,
          title: 'Total Income',
          value: formatMoney(
            income,
            currency,
          ),
          description: 'Income this month',
          iconColor:
              const Color(0xFF2FB380),
        ),
        _MetricCard(
          icon: savingsPositive
              ? Icons.savings_rounded
              : Icons.warning_rounded,
          title: savingsPositive
              ? 'Saved'
              : 'Deficit',
          value: formatMoney(
            savings.abs(),
            currency,
          ),
          description: savingsPositive
              ? 'Money remaining'
              : 'Over income',
          iconColor: savingsPositive
              ? Colors.teal
              : Colors.red,
        ),
        _MetricCard(
          icon: Icons.percent_rounded,
          title: 'Balance',
          value: balancePercentage == null
              ? '—'
              : '${balancePercentage.clamp(-999.0, 999.0).toStringAsFixed(0)}%',
          description: 'Income retained',
          iconColor:
              Colors.deepPurple,
        ),
      ],
    );
  }

  // ===========================================================================
  // ACTIVITY
  // ===========================================================================

  Widget _buildActivityCard(
    BuildContext context,
    int tasksCompleted,
    int goalsAchieved,
    dynamic productiveDay,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return SectionCard(
      child: Column(
        children: [
          _ActivityRow(
            icon: Icons.check_circle_rounded,
            color: colors.primary,
            title: 'Tasks completed',
            value: '$tasksCompleted',
            subtitle: 'Finished this month',
          ),

          _activityDivider(context),

          _ActivityRow(
            icon: Icons.flag_rounded,
            color: Colors.deepPurple,
            title: 'Goals achieved',
            value: '$goalsAchieved',
            subtitle: 'Milestones reached',
          ),

          _activityDivider(context),

          _ActivityRow(
            icon: Icons.bolt_rounded,
            color: Colors.orange,
            title: 'Most productive day',
            value: productiveDay != null
                ? productiveDay.toString()
                : '—',
            subtitle: productiveDay != null
                ? '${_monthName(_month)} productivity'
                : 'No activity recorded',
          ),
        ],
      ),
    );
  }

  Widget _activityDivider(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Divider(
        height: 1,
        color: colors.outlineVariant
            .withValues(alpha: 0.35),
      ),
    );
  }

  // ===========================================================================
  // MOOD
  // ===========================================================================

  Widget _buildMoodCard(
    BuildContext context,
    MapEntry<String, int>? topMood,
    dynamic topMoodOption,
    Map<String, int> moodSummary,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (topMood == null ||
        topMoodOption == null) {
      return SectionCard(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 18,
          ),
          child: Row(
            children: [
              _MoodIcon(
                icon:
                    Icons.sentiment_neutral_rounded,
                color:
                    colors.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No mood data yet',
                      style: theme
                          .textTheme.titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log your mood throughout the month to see your emotional trend here.',
                      style: theme
                          .textTheme.bodySmall
                          ?.copyWith(
                        color:
                            colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalMoodEntries =
        moodSummary.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    final percentage =
        totalMoodEntries == 0
            ? 0
            : ((topMood.value /
                        totalMoodEntries) *
                    100)
                .round();

    final moodColor =
        topMoodOption.color as Color;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodColor.withValues(
              alpha: 0.13,
            ),
            colors.surface,
          ],
        ),
        borderRadius:
            BorderRadius.circular(25),
        border: Border.all(
          color: moodColor.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          _MoodIcon(
            icon: topMoodOption.icon,
            color: moodColor,
            large: true,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Your dominant mood',
                  style: theme
                      .textTheme.labelMedium
                      ?.copyWith(
                    color:
                        colors.onSurfaceVariant,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  topMoodOption.label
                      .toString(),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: theme
                      .textTheme.titleLarge
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${topMood.value} ${topMood.value == 1 ? 'entry' : 'entries'} • $percentage% of logged moods',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
                    color:
                        colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Icon(
            Icons.trending_up_rounded,
            color: moodColor,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INSIGHTS
  // ===========================================================================

  Widget _buildInsightCard(
    BuildContext context,
    double spent,
    double income,
    double savings,
    bool savingsPositive,
    int tasksCompleted,
    int goalsAchieved,
    dynamic topMoodOption,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    String title;
    String message;
    IconData icon;

    if (income == 0 && spent == 0) {
      title = 'Start your month';
      message =
          'Add expenses, income, tasks and moods to build a useful monthly picture.';
      icon =
          Icons.rocket_launch_rounded;
    } else if (!savingsPositive) {
      title = 'Watch your spending';
      message =
          'Your expenses are currently higher than your income. Review your biggest spending categories.';
      icon =
          Icons.trending_down_rounded;
    } else if (tasksCompleted > 0 &&
        goalsAchieved > 0) {
      title = 'Strong month';
      message =
          'You made financial progress while also completing tasks and achieving goals. Keep the momentum going.';
      icon =
          Icons.celebration_rounded;
    } else if (savings > 0) {
      title =
          'Good financial progress';
      message =
          'You finished with money left over. Consider moving part of it toward your savings goal.';
      icon =
          Icons.savings_rounded;
    } else {
      title = 'Keep building';
      message =
          'Small improvements across money, tasks, goals and mood tracking can make next month even better.';
      icon =
          Icons.auto_awesome_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: colors
            .surfaceContainerHighest
            .withValues(alpha: 0.48),
        borderRadius:
            BorderRadius.circular(25),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.secondary,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: colors.onPrimary,
              size: 22,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme
                      .textTheme.titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
                    color:
                        colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),

                if (topMoodOption != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        topMoodOption.icon,
                        size: 15,
                        color:
                            topMoodOption.color,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Mood trend: ${topMoodOption.label}',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: theme
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                            color:
                                topMoodOption.color,
                            fontWeight:
                                FontWeight.w800,
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
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Map<String, int> _parseMoodSummary(
    dynamic value,
  ) {
    if (value is! Map) {
      return <String, int>{};
    }

    final result = <String, int>{};

    value.forEach((key, rawValue) {
      final mood = key.toString();

      int count;

      if (rawValue is int) {
        count = rawValue;
      } else if (rawValue is num) {
        count = rawValue.toInt();
      } else {
        count =
            int.tryParse(
                  rawValue.toString(),
                ) ??
                0;
      }

      if (count > 0) {
        result[mood] = count;
      }
    });

    return result;
  }

  MapEntry<String, int>? _getTopMood(
    Map<String, int> moodSummary,
  ) {
    if (moodSummary.isEmpty) {
      return null;
    }

    return moodSummary.entries.reduce(
      (a, b) =>
          a.value >= b.value ? a : b,
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _monthName(DateTime date) {
    try {
      return formatMonthYear(date)
          .split(' ')
          .first;
    } catch (_) {
      return '${date.month}';
    }
  }
}

// =============================================================================
// HERO METRIC
// =============================================================================

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white
                  .withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// METRIC CARD
// =============================================================================

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Color iconColor;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),

          const Spacer(),

          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: theme
                .textTheme.labelMedium
                ?.copyWith(
              color:
                  colors.onSurfaceVariant,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: theme
                .textTheme.titleMedium
                ?.copyWith(
              fontWeight:
                  FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            description,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: theme
                .textTheme.labelSmall
                ?.copyWith(
              color:
                  colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACTIVITY ROW
// =============================================================================

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: theme
                    .textTheme.titleSmall
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: theme
                    .textTheme.labelSmall
                    ?.copyWith(
                  color:
                      colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: theme
                .textTheme.titleMedium
                ?.copyWith(
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// MOOD ICON
// =============================================================================

class _MoodIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool large;

  const _MoodIcon({
    required this.icon,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 58.0 : 48.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.13,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: large ? 30 : 24,
        color: color,
      ),
    );
  }
}
