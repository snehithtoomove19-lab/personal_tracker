import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final spending = app.categorySpending();

    return Scaffold(
      appBar: AppBar(title: const Text('Category Budgets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Set a monthly limit per category. You\'ll see a warning if you go over.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...app.expenseCategories.map((cat) {
            final budget = app.categoryBudgets[cat];
            final spent = spending[cat] ?? 0;
            final over = budget != null && spent > budget;
            final pct = budget != null && budget > 0 ? (spent / budget).clamp(0, 1.5) : 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Text(
                          budget != null ? '${formatMoney(spent, app.currency)} / ${formatMoney(budget, app.currency)}' : 'No budget set',
                          style: TextStyle(color: over ? Colors.red : Colors.grey.shade700, fontWeight: over ? FontWeight.bold : null),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _editBudget(context, app, cat, budget),
                        ),
                      ],
                    ),
                    if (budget != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct.toDouble() > 1 ? 1 : pct.toDouble(),
                          minHeight: 8,
                          color: over ? Colors.red : Theme.of(context).colorScheme.primary,
                          backgroundColor: (over ? Colors.red : Theme.of(context).colorScheme.primary).withValues(alpha: 0.12),
                        ),
                      ),
                      if (over)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Over budget by ${formatMoney(spent - budget, app.currency)}',
                              style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _editBudget(BuildContext context, app, String category, double? current) {
    final ctrl = TextEditingController(text: current != null ? current.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Budget for $category'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(prefixText: app.currency, hintText: 'e.g. 5000 (leave blank to remove)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text) ?? 0;
              app.setCategoryBudget(category, v);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
