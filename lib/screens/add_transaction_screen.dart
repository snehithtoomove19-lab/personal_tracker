import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class AddTransactionScreen extends StatefulWidget {
  final TxType type;
  final AppTransaction? existing;
  const AddTransactionScreen({super.key, required this.type, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _newCategoryCtrl = TextEditingController();
  String? _category;
  late TxType _type;
  DateTime _date = DateTime.now();
  String _paymentMethod = kPaymentMethods.first;
  TxRepeat _repeat = TxRepeat.none;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    if (widget.existing != null) {
      _amountCtrl.text = widget.existing!.amount.toString();
      _noteCtrl.text = widget.existing!.note;
      _category = widget.existing!.category;
      _date = widget.existing!.date;
      _paymentMethod = widget.existing!.paymentMethod;
      _repeat = widget.existing!.repeat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final categories = _type == TxType.expense ? app.expenseCategories : app.incomeCategories;
    _category ??= categories.first;
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : (_type == TxType.expense ? 'Add Expense' : 'Add Income')),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                app.deleteTransaction(widget.existing!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!isEditing)
                SegmentedButton<TxType>(
                  segments: const [
                    ButtonSegment(value: TxType.expense, label: Text('Expense'), icon: Icon(Icons.remove)),
                    ButtonSegment(value: TxType.income, label: Text('Income'), icon: Icon(Icons.add)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() {
                    _type = s.first;
                    _category = null;
                  }),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount', prefixText: app.currency),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter an amount';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCategoryCtrl,
                      decoration: const InputDecoration(hintText: 'Add custom category'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      final name = _newCategoryCtrl.text.trim();
                      if (name.isNotEmpty) {
                        app.addCustomCategory(name, isExpense: _type == TxType.expense);
                        setState(() {
                          _category = name;
                          _newCategoryCtrl.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(formatDate(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: kPaymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _paymentMethod = v);
                },
              ),
              const SizedBox(height: 16),
              const Text('Repeat', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<TxRepeat>(
                segments: const [
                  ButtonSegment(value: TxRepeat.none, label: Text('None')),
                  ButtonSegment(value: TxRepeat.weekly, label: Text('Weekly')),
                  ButtonSegment(value: TxRepeat.monthly, label: Text('Monthly')),
                ],
                selected: {_repeat},
                onSelectionChanged: (s) => setState(() => _repeat = s.first),
                showSelectedIcon: false,
              ),
              if (_repeat != TxRepeat.none)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'A new entry like this will be added automatically each time it\'s due (e.g. rent, subscriptions).',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(isEditing ? 'Save Changes' : 'Add ${_type == TxType.expense ? 'Expense' : 'Income'}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final app = AppScope.of(context);
    final amount = double.parse(_amountCtrl.text);

    if (widget.existing != null) {
      final updated = widget.existing!
        ..amount = amount
        ..category = _category!
        ..note = _noteCtrl.text.trim()
        ..date = _date
        ..type = _type
        ..paymentMethod = _paymentMethod
        ..repeat = _repeat;
      app.updateTransaction(updated);
    } else {
      app.addTransaction(AppTransaction(
        id: app.newId(),
        type: _type,
        amount: amount,
        category: _category!,
        note: _noteCtrl.text.trim(),
        date: _date,
        paymentMethod: _paymentMethod,
        repeat: _repeat,
      ));
    }
    Navigator.pop(context);
  }
}
