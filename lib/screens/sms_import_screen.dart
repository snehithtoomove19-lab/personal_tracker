import 'package:flutter/material.dart';

import '../services/app_scope.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

/// A best-effort parsed transaction candidate extracted from pasted SMS text.
class _SmsCandidate {
  final String rawBody;
  final double amount;
  final TxType type;
  String category;
  bool imported = false;

  _SmsCandidate({
    required this.rawBody,
    required this.amount,
    required this.type,
    this.category = 'Other',
  });
}

final RegExp _amountPattern = RegExp(
  r'(?:rs\.?|inr|â‚¹|\$|usd)\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

const List<String> _debitKeywords = [
  'debited',
  'spent',
  'paid',
  'withdrawn',
  'purchase',
  'debit'
];
const List<String> _creditKeywords = [
  'credited',
  'received',
  'deposited',
  'credit'
];

/// Lets the person paste one or more bank/UPI SMS messages (copied from
/// their phone's messaging app) and detects transaction amounts from them.
///
/// This deliberately avoids reading the SMS inbox directly â€” that requires
/// a native Android permission and platform-specific plugin, which is a
/// common source of build/permission issues across different devices and
/// Flutter/Gradle versions. Paste-based detection gets the same practical
/// benefit (fast entry of bank alerts) with zero permissions and zero native
/// code, so it can never fail to build or get denied by the OS.
class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});
  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final _pasteCtrl = TextEditingController();
  List<_SmsCandidate> _candidates = [];

  void _parse() {
    final text = _pasteCtrl.text;
    if (text.trim().isEmpty) {
      setState(() => _candidates = []);
      return;
    }

    // Treat blank-line-separated blocks as separate messages; if the person
    // pasted just one message, the whole text is a single block.
    final blocks = text
        .split(RegExp(r'\n\s*\n'))
        .where((b) => b.trim().isNotEmpty)
        .toList();
    final chunks = blocks.length > 1 ? blocks : [text];

    final found = <_SmsCandidate>[];
    for (final chunk in chunks) {
      final lower = chunk.toLowerCase();
      final amountMatch = _amountPattern.firstMatch(lower);
      if (amountMatch == null) continue;

      final isDebit = _debitKeywords.any((k) => lower.contains(k));
      final isCredit = _creditKeywords.any((k) => lower.contains(k));
      if (!isDebit && !isCredit) continue;

      final amountStr = amountMatch.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(amountStr);
      if (amount == null || amount <= 0) continue;

      found.add(_SmsCandidate(
        rawBody: chunk.trim(),
        amount: amount,
        type: isDebit ? TxType.expense : TxType.income,
        category: lower.contains('bill') ? 'Bills' : 'Other',
      ));
    }

    setState(() => _candidates = found);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add from SMS'),
        actions: [
          if (_candidates.any((c) => !c.imported))
            TextButton(
              onPressed: () {
                for (final c in _candidates.where((c) => !c.imported)) {
                  app.addTransaction(AppTransaction(
                    id: app.newId(),
                    type: c.type,
                    amount: c.amount,
                    category: c.category,
                    note: 'Added from SMS',
                    date: DateTime.now(),
                  ));
                  c.imported = true;
                }
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All detected transactions added')),
                );
              },
              child: const Text('Add All'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copy a bank/UPI SMS (long-press it in your messages app, then Copy) and paste it below. '
              'You can paste several messages at once â€” separate them with a blank line.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pasteCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Paste SMS text here...\ne.g. "Rs.450 debited from your account for UPI purchase"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _parse,
                icon: const Icon(Icons.search),
                label: const Text('Detect Transactions'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _candidates.isEmpty
                  ? Center(
                      child: Text(
                        'Detected transactions will appear here. Always double-check amounts and\ncategories before adding â€” this is a best-effort text parser.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _candidates.length,
                      itemBuilder: (context, i) {
                        final c = _candidates[i];
                        final isIncome = c.type == TxType.income;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (isIncome
                                      ? const Color(0xFF2FB380)
                                      : const Color(0xFFE2574C))
                                  .withOpacity(0.15),
                              child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isIncome
                                      ? const Color(0xFF2FB380)
                                      : const Color(0xFFE2574C)),
                            ),
                            title: Text(
                                '${formatMoney(c.amount, app.currency)} Â· ${c.category}'),
                            subtitle: Text(c.rawBody,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            isThreeLine: true,
                            trailing: c.imported
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      app.addTransaction(AppTransaction(
                                        id: app.newId(),
                                        type: c.type,
                                        amount: c.amount,
                                        category: c.category,
                                        note: 'Added from SMS',
                                        date: DateTime.now(),
                                      ));
                                      setState(() => c.imported = true);
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
