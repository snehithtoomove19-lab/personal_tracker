import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
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
    final app = AppScope.of(context);

    var items = app.transactions.where((t) {
      final matchesQuery = _query.isEmpty ||
          t.category.toLowerCase().contains(_query.toLowerCase()) ||
          t.note.toLowerCase().contains(_query.toLowerCase());
      final matchesType = _typeFilter == null || t.type == _typeFilter;
      final matchesDate = _dateFilter == null ||
          (t.date.year == _dateFilter!.year && t.date.month == _dateFilter!.month && t.date.day == _dateFilter!.day);
      return matchesQuery && matchesType && matchesDate;
    }).toList();

    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen(type: TxType.expense))),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        children: [
          SectionCard(
            title: 'This Month',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatTile(label: 'Income', value: formatMoney(app.monthIncome, app.currency), color: const Color(0xFF2FB380)),
                StatTile(label: 'Expense', value: formatMoney(app.monthExpense, app.currency), color: const Color(0xFFE2574C)),
                StatTile(label: 'Net', value: formatMoney(app.monthIncome - app.monthExpense, app.currency)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(hintText: 'Search transactions...', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _typeFilter == null,
                onSelected: (_) => setState(() => _typeFilter = null),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Income'),
                selected: _typeFilter == TxType.income,
                onSelected: (_) => setState(() => _typeFilter = TxType.income),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Expense'),
                selected: _typeFilter == TxType.expense,
                onSelected: (_) => setState(() => _typeFilter = TxType.expense),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.filter_alt, color: _dateFilter != null ? Theme.of(context).colorScheme.primary : null),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateFilter ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _dateFilter = picked);
                },
              ),
              if (_dateFilter != null)
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _dateFilter = null)),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No transactions found', style: TextStyle(color: Colors.grey.shade600))),
            )
          else
            ...items.map((t) => _TransactionTile(transaction: t)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final AppTransaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isIncome = transaction.type == TxType.income;
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        final removed = transaction;
        app.deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${removed.category}" transaction'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => app.addTransaction(removed),
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (isIncome ? const Color(0xFF2FB380) : const Color(0xFFE2574C)).withValues(alpha: 0.15),
            child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? const Color(0xFF2FB380) : const Color(0xFFE2574C)),
          ),
          title: Text(transaction.category),
          subtitle: Text(
            transaction.note.isEmpty
                ? '${formatDate(transaction.date)} · ${transaction.paymentMethod}'
                : '${formatDate(transaction.date)} · ${transaction.paymentMethod} · ${transaction.note}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'}${formatMoney(transaction.amount, app.currency)}',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: isIncome ? const Color(0xFF2FB380) : const Color(0xFFE2574C)),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTransactionScreen(type: transaction.type, existing: transaction)),
          ),
        ),
      ),
    );
  }
}
