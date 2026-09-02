import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../utils/formatters.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final spending = app.categorySpending();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final categories = app.expenseCategories;

    double totalBudget = 0;
    double totalSpent = 0;
    int configuredBudgets = 0;
    int overBudgetCount = 0;

    for (final category in categories) {
      final budget = app.categoryBudgets[category];
      final spent = spending[category] ?? 0;

      totalSpent += spent;

      if (budget != null && budget > 0) {
        totalBudget += budget;
        configuredBudgets++;

        if (spent > budget) {
          overBudgetCount++;
        }
      }
    }

    final overallProgress = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Category Budgets',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          // ============================================================
          // HERO
          // ============================================================

          _buildHeroCard(
            context,
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            progress: overallProgress,
            configuredBudgets: configuredBudgets,
            overBudgetCount: overBudgetCount,
          ),

          const SizedBox(height: 18),

          // ============================================================
          // INFO
          // ============================================================

          Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Set a monthly limit for each category and stay in control of your spending.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ============================================================
          // SECTION TITLE
          // ============================================================

          Row(
            children: [
              Expanded(
                child: Text(
                  'Your categories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (categories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${categories.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ============================================================
          // CATEGORY CARDS
          // ============================================================

          if (categories.isEmpty)
            _buildEmptyState(context)
          else
            ...categories.map(
              (category) {
                final budget = app.categoryBudgets[category];
                final spent = spending[category] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildBudgetCard(
                    context,
                    app,
                    category,
                    spent,
                    budget,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ====================================================================
  // HERO CARD
  // ====================================================================

  Widget _buildHeroCard(
    BuildContext context, {
    required double totalBudget,
    required double totalSpent,
    required double progress,
    required int configuredBudgets,
    required int overBudgetCount,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final remaining = totalBudget - totalSpent;
    final hasBudget = totalBudget > 0;
    final overAll = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasBudget
                          ? 'Keep your spending on track'
                          : 'Start by setting your first budget',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (hasBudget) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spent',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatMoney(
                          totalSpent,
                          AppScope.of(context).currency,
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Budget',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(
                        totalBudget,
                        AppScope.of(context).currency,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor:
                    Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    overAll
                        ? 'Over overall budget'
                        : '${(progress * 100).round()}% of budget used',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  overAll
                      ? formatMoney(
                          remaining.abs(),
                          AppScope.of(context).currency,
                        )
                      : formatMoney(
                          remaining,
                          AppScope.of(context).currency,
                        ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No monthly budgets yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the edit button on any category below to create a spending limit.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 18),

          Row(
            children: [
              _heroStat(
                context,
                value: '$configuredBudgets',
                label: 'Budgets set',
              ),
              const SizedBox(width: 8),
              _heroStat(
                context,
                value: '$overBudgetCount',
                label: 'Over limit',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // BUDGET CARD
  // ====================================================================

  Widget _buildBudgetCard(
    BuildContext context,
    dynamic app,
    String category,
    double spent,
    double? budget,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final hasBudget = budget != null && budget > 0;
    final over = hasBudget && spent > budget!;
    final percentage = hasBudget
        ? (spent / budget!).clamp(0.0, 1.0)
        : 0.0;

    final remaining =
        hasBudget ? budget! - spent : 0.0;

    final progressColor = over
        ? const Color(0xFFE2574C)
        : percentage >= 0.8
            ? const Color(0xFFE0A52B)
            : colors.primary;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: over
              ? const Color(0xFFE2574C).withValues(alpha: 0.35)
              : colors.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _categoryIcon(category),
                    color: progressColor,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasBudget
                            ? '${formatMoney(spent, app.currency)} spent'
                            : 'No budget set',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                if (hasBudget)
                  _statusBadge(
                    context,
                    over: over,
                    percentage: percentage,
                  ),

                const SizedBox(width: 4),

                IconButton(
                  tooltip: 'Edit budget',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 19,
                  ),
                  onPressed: () => _editBudget(
                    context,
                    app,
                    category,
                    budget,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (hasBudget) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatMoney(
                        spent,
                        app.currency,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(
                      budget!,
                      app.currency,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 9,
                  color: progressColor,
                  backgroundColor:
                      progressColor.withValues(alpha: 0.10),
                ),
              ),

              const SizedBox(height: 9),

              Row(
                children: [
                  Icon(
                    over
                        ? Icons.warning_amber_rounded
                        : percentage >= 0.8
                            ? Icons.info_outline_rounded
                            : Icons.check_circle_outline_rounded,
                    size: 15,
                    color: progressColor,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      over
                          ? 'Over budget by ${formatMoney(spent - budget, app.currency)}'
                          : '${formatMoney(remaining, app.currency)} remaining',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${(percentage * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set a monthly limit for $category',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // STATUS BADGE
  // ====================================================================

  Widget _statusBadge(
    BuildContext context, {
    required bool over,
    required double percentage,
  }) {
    final colors = Theme.of(context).colorScheme;

    final color = over
        ? const Color(0xFFE2574C)
        : percentage >= 0.8
            ? const Color(0xFFE0A52B)
            : colors.primary;

    final label = over
        ? 'Over'
        : percentage >= 0.8
            ? 'Near limit'
            : 'On track';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ====================================================================
  // CATEGORY ICONS
  // ====================================================================

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('food') ||
        value.contains('grocery') ||
        value.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }

    if (value.contains('travel') ||
        value.contains('transport') ||
        value.contains('fuel')) {
      return Icons.directions_car_rounded;
    }

    if (value.contains('shop') ||
        value.contains('clothes')) {
      return Icons.shopping_bag_rounded;
    }

    if (value.contains('bill') ||
        value.contains('utility')) {
      return Icons.receipt_long_rounded;
    }

    if (value.contains('health') ||
        value.contains('medical')) {
      return Icons.favorite_rounded;
    }

    if (value.contains('entertain')) {
      return Icons.movie_rounded;
    }

    if (value.contains('education') ||
        value.contains('school')) {
      return Icons.school_rounded;
    }

    if (value.contains('home') ||
        value.contains('rent')) {
      return Icons.home_rounded;
    }

    if (value.contains('personal')) {
      return Icons.person_rounded;
    }

    return Icons.category_rounded;
  }

  // ====================================================================
  // EMPTY STATE
  // ====================================================================

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 42,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No expense categories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your expense categories will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // EDIT BUDGET
  // ====================================================================

  void _editBudget(
    BuildContext context,
    dynamic app,
    String category,
    double? current,
  ) {
    final ctrl = TextEditingController(
      text: current != null ? current.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;

        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Budget for $category',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              prefixText: '${app.currency} ',
              labelText: 'Monthly limit',
              hintText: 'e.g. 5000',
              helperText: 'Leave blank to remove the budget',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final text = ctrl.text.trim();

                if (text.isEmpty) {
                  app.setCategoryBudget(category, 0);
                  Navigator.pop(ctx);
                  return;
                }

                final value = double.tryParse(text);

                if (value == null || value < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid budget amount.',
                      ),
                    ),
                  );
                  return;
                }

                app.setCategoryBudget(category, value);
                Navigator.pop(ctx);
              },
              icon: const Icon(
                Icons.check_rounded,
                size: 18,
              ),
              label: const Text('Save'),
            ),
          ],
        );
      },
    ).whenComplete(ctrl.dispose);
  }
}