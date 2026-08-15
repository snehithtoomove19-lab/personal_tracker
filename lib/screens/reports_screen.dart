import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
import '../widgets/bar_trend_chart.dart';
import 'budgets_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final catSpend = app.categorySpending(month: _month);
    final total = catSpend.values.fold(0.0, (p, e) => p + e);
    final sortedCats = catSpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final monthIncome = app.transactions
        .where((t) => t.type.name == 'income' && t.date.year == _month.year && t.date.month == _month.month)
        .fold(0.0, (p, e) => p + e.amount);
    final monthExpense = total;

    final colors = [
      Colors.indigo, Colors.teal, Colors.orange, Colors.pink,
      Colors.purple, Colors.brown, Colors.cyan, Colors.green,
    ];

    final bottomPadding = MediaQuery.of(context).padding.bottom + 20;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              ),
              Text(formatMonthYear(_month), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (app.monthOverMonthChangePercent != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                child: Row(
                  children: [
                    Icon(
                      app.monthOverMonthChangePercent! > 0 ? Icons.trending_up : Icons.trending_down,
                      color: app.monthOverMonthChangePercent! > 0 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "You've spent ${app.monthOverMonthChangePercent!.abs().toStringAsFixed(0)}% "
                        "${app.monthOverMonthChangePercent! > 0 ? 'more' : 'less'} than last month",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (app.overBudgetCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: Colors.red.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.red),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Over budget this month', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen())),
                            child: const Text('Manage'),
                          ),
                        ],
                      ),
                      ...app.overBudgetCategories.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${e.key}: ${formatMoney(e.value[0], app.currency)} of ${formatMoney(e.value[1], app.currency)} budget',
                              style: const TextStyle(fontSize: 13),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          SectionCard(
            title: 'Income vs Expense',
            child: Builder(builder: (context) {
              final barMax = [monthIncome, monthExpense, 1.0].reduce((a, b) => a > b ? a : b);
              return Column(
                children: [
                  _BarRow(label: 'Income', value: monthIncome, max: barMax, color: const Color(0xFF2FB380), currency: app.currency),
                  const SizedBox(height: 10),
                  _BarRow(label: 'Expense', value: monthExpense, max: barMax, color: const Color(0xFFE2574C), currency: app.currency),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Highest Spending Category',
            child: sortedCats.isEmpty
                ? Text('No expenses recorded this month.', style: TextStyle(color: Colors.grey.shade600))
                : Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(sortedCats.first.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Text(formatMoney(sortedCats.first.value, app.currency)),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Category-wise Spending',
            trailing: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen())),
              child: const Text('Budgets'),
            ),
            child: sortedCats.isEmpty
                ? Text('Nothing to show yet.', style: TextStyle(color: Colors.grey.shade600))
                : Column(
                    children: List.generate(sortedCats.length, (i) {
                      final e = sortedCats[i];
                      final pct = total == 0 ? 0.0 : e.value / total;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            SizedBox(width: 90, child: Text(e.key, overflow: TextOverflow.ellipsis)),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 10,
                                  color: colors[i % colors.length],
                                  backgroundColor: colors[i % colors.length].withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(formatMoney(e.value, app.currency), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Last 7 Days',
            child: Builder(builder: (context) {
              final trend = app.dailyExpenseTrend(days: 7);
              final now = DateTime.now();
              final labels = List.generate(7, (i) {
                final d = now.subtract(Duration(days: 6 - i));
                return ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7];
              });
              return BarTrendChart(
                values: trend,
                labels: labels,
                color: const Color(0xFFE2574C),
                valueFormatter: (v) => formatMoney(v, app.currency),
              );
            }),
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final methodSpend = app.paymentMethodSpending(month: _month);
            final methodTotal = methodSpend.values.fold(0.0, (p, e) => p + e);
            if (methodSpend.isEmpty) return const SizedBox.shrink();
            final sortedMethods = methodSpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                title: 'By Payment Method',
                child: Column(
                  children: sortedMethods.map((e) {
                    final pct = methodTotal == 0 ? 0.0 : e.value / methodTotal;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(width: 100, child: Text(e.key, overflow: TextOverflow.ellipsis)),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(value: pct, minHeight: 10, color: Colors.indigo, backgroundColor: Colors.indigo.withValues(alpha: 0.12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(formatMoney(e.value, app.currency), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          SectionCard(
            title: 'This Week',
            child: StatTile(label: 'Weekly Spending', value: formatMoney(app.weekExpense, app.currency), color: const Color(0xFFE2574C)),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String currency;
  const _BarRow({required this.label, required this.value, required this.max, required this.color, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: max == 0 ? 0 : value / max, minHeight: 14, color: color, backgroundColor: color.withValues(alpha: 0.12)),
          ),
        ),
        const SizedBox(width: 8),
        Text(formatMoney(value, currency), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
