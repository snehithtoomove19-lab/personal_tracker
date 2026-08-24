import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'add_transaction_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _query = '';
  TxType? _typeFilter;
  DateTime? _dateFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);

    final now = DateTime.now();

    var items = app.transactions.where((transaction) {
      final query = _query.trim().toLowerCase();

      final matchesQuery = query.isEmpty ||
          transaction.category.toLowerCase().contains(query) ||
          transaction.note.toLowerCase().contains(query) ||
          transaction.paymentMethod.toLowerCase().contains(query);

      final matchesType =
          _typeFilter == null || transaction.type == _typeFilter;

      final matchesDate = _dateFilter == null ||
          (transaction.date.year == _dateFilter!.year &&
              transaction.date.month == _dateFilter!.month &&
              transaction.date.day == _dateFilter!.day);

      return matchesQuery && matchesType && matchesDate;
    }).toList();

    // Newest transactions first.
    items.sort((a, b) => b.date.compareTo(a.date));

    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

    final monthNet = app.monthIncome - app.monthExpense;

    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddTransactionScreen(type: TxType.expense),
            ),
          );
        },
        elevation: 5,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Expense',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          bottomPadding,
        ),
        children: [
          // =========================================================
          // HEADER
          // =========================================================

          _buildHeader(
            context,
            items.length,
          ),

          const SizedBox(height: 18),

          // =========================================================
          // MONTH SUMMARY
          // =========================================================

          _buildSummaryCard(
            context,
            app,
            monthNet,
          ),

          const SizedBox(height: 16),

          // =========================================================
          // SEARCH
          // =========================================================

          _buildSearchField(
            context,
          ),

          const SizedBox(height: 12),

          // =========================================================
          // FILTERS
          // =========================================================

          _buildFilters(
            context,
          ),

          const SizedBox(height: 18),

          // =========================================================
          // TRANSACTION HEADER
          // =========================================================

          Row(
            children: [
              Expanded(
                child: Text(
                  _dateFilter != null
                      ? 'Filtered Transactions'
                      : 'Transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (items.isNotEmpty)
                Text(
                  '${items.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // =========================================================
          // TRANSACTIONS
          // =========================================================

          if (items.isEmpty)
            _buildEmptyState(
              context,
            )
          else
            ...items.map(
              (transaction) => _TransactionTile(
                transaction: transaction,
              ),
            ),
        ],
      ),
    );
  }

  // ===============================================================
  // HEADER
  // ===============================================================

  Widget _buildHeader(
    BuildContext context,
    int resultCount,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kExpenseColorLocal.withValues(alpha: 0.16),
                kExpenseColorLocal.withValues(alpha: 0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: kExpenseColorLocal,
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expenses',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Track where your money goes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (resultCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$resultCount',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  // ===============================================================
  // SUMMARY CARD
  // ===============================================================

  Widget _buildSummaryCard(
    BuildContext context,
    dynamic app,
    double monthNet,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isPositive = monthNet >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.11),
            colors.secondary.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.11),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 19,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'This Month',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Income',
                  value: formatMoney(
                    app.monthIncome,
                    app.currency,
                  ),
                  color: kIncomeColorLocal,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              _buildVerticalDivider(context),
              Expanded(
                child: _SummaryItem(
                  label: 'Expense',
                  value: formatMoney(
                    app.monthExpense,
                    app.currency,
                  ),
                  color: kExpenseColorLocal,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              _buildVerticalDivider(context),
              Expanded(
                child: _SummaryItem(
                  label: 'Net',
                  value: formatMoney(
                    monthNet,
                    app.currency,
                  ),
                  color: isPositive
                      ? kIncomeColorLocal
                      : kExpenseColorLocal,
                  icon: isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 1,
      height: 48,
      color: colors.outlineVariant.withValues(alpha: 0.55),
    );
  }

  // ===============================================================
  // SEARCH
  // ===============================================================

  Widget _buildSearchField(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextField(
      onChanged: (value) {
        setState(() {
          _query = value;
        });
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search transactions...',
        hintStyle: TextStyle(
          color: colors.onSurfaceVariant,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
        ),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(
                  Icons.close_rounded,
                ),
                onPressed: () {
                  setState(() {
                    _query = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(
              alpha: 0.45,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.3,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
      ),
    );
  }

  // ===============================================================
  // FILTERS
  // ===============================================================

  Widget _buildFilters(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All',
                  selected: _typeFilter == null,
                  icon: Icons.apps_rounded,
                  onTap: () {
                    setState(() {
                      _typeFilter = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Income',
                  selected: _typeFilter == TxType.income,
                  icon: Icons.arrow_downward_rounded,
                  color: kIncomeColorLocal,
                  onTap: () {
                    setState(() {
                      _typeFilter = TxType.income;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Expense',
                  selected: _typeFilter == TxType.expense,
                  icon: Icons.arrow_upward_rounded,
                  color: kExpenseColorLocal,
                  onTap: () {
                    setState(() {
                      _typeFilter = TxType.expense;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildDateButton(context),
        if (_dateFilter != null) ...[
          const SizedBox(width: 5),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Clear date filter',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 19,
              ),
              onPressed: () {
                setState(() {
                  _dateFilter = null;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final colors = Theme.of(context).colorScheme;

    final accent = color ?? colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : colors.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.24)
                  : colors.outlineVariant.withValues(
                      alpha: 0.45,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? accent
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? accent
                          : colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    final selected = _dateFilter != null;

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? colors.primary.withValues(alpha: 0.11)
            : colors.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? colors.primary.withValues(alpha: 0.23)
              : colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: IconButton(
        tooltip: 'Filter by date',
        visualDensity: VisualDensity.compact,
        icon: Icon(
          Icons.calendar_today_rounded,
          size: 18,
          color: selected
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _dateFilter ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );

          if (!mounted || picked == null) return;

          setState(() {
            _dateFilter = picked;
          });
        },
      ),
    );
  }

  // ===============================================================
  // EMPTY STATE
  // ===============================================================

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final hasFilters =
        _query.trim().isNotEmpty ||
        _typeFilter != null ||
        _dateFilter != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_rounded,
              size: 34,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters
                ? 'No transactions found'
                : 'No transactions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hasFilters
                ? 'Try changing your search or filters.'
                : 'Your expenses and income will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _query = '';
                  _typeFilter = null;
                  _dateFilter = null;
                });
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

// ===================================================================
// SUMMARY ITEM
// ===================================================================

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// TRANSACTION TILE
// ===================================================================

class _TransactionTile extends StatelessWidget {
  final AppTransaction transaction;

  const _TransactionTile({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = AppScope.of(context);

    final isIncome = transaction.type == TxType.income;

    final accent =
        isIncome ? kIncomeColorLocal : kExpenseColorLocal;

    final icon = isIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      movementDuration: const Duration(milliseconds: 250),
      resizeDuration: const Duration(milliseconds: 250),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE2574C),
              Color(0xFFD94338),
            ],
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        alignment: Alignment.centerRight,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 3),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(
          context,
          transaction,
        );
      },
      onDismissed: (_) {
        final removed = transaction;

        app.deleteTransaction(
          transaction.id,
        );

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              90,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Deleted "${removed.category}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                app.addTransaction(removed);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: colors.outlineVariant.withValues(
              alpha: 0.55,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(
                    type: transaction.type,
                    existing: transaction,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // -------------------------------------------------
                  // ICON
                  // -------------------------------------------------

                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // -------------------------------------------------
                  // DETAILS
                  // -------------------------------------------------

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                formatDate(
                                  transaction.date,
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: theme
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color:
                                    colors.onSurfaceVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                transaction.paymentMethod,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: theme
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (transaction.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            transaction.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // -------------------------------------------------
                  // AMOUNT
                  // -------------------------------------------------

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'}${formatMoney(
                          transaction.amount,
                          app.currency,
                        )}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // DELETE CONFIRMATION
  // ===============================================================

  Future<bool> _confirmDelete(
    BuildContext context,
    AppTransaction transaction,
  ) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: kExpenseColorLocal.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: kExpenseColorLocal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Delete transaction?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This will remove "${transaction.category}" from your transactions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kExpenseColorLocal,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}

// ===================================================================
// LOCAL COLORS
// ===================================================================

const kIncomeColorLocal = Color(0xFF2FB380);
const kExpenseColorLocal = Color(0xFFE2574C);