import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';

/// A best-effort transaction candidate extracted from pasted SMS text.
class _SmsCandidate {
  final String rawBody;
  final double amount;
  final TxType type;
  String category;
  bool imported;

  _SmsCandidate({
    required this.rawBody,
    required this.amount,
    required this.type,
    this.category = 'Other',
  }) : imported = false;
}

/// Paste one or more bank / UPI SMS messages and detect transactions.
///
/// This screen intentionally does not read the SMS inbox directly.
/// It uses paste-based detection, which requires no SMS permissions and
/// avoids platform-specific native dependencies.
class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final TextEditingController _pasteController = TextEditingController();

  List<_SmsCandidate> _candidates = [];

  bool _isParsing = false;

  static final RegExp _amountPattern = RegExp(
    r'(?:rs\.?|inr|Ã¢â€šÂ¹|\$|usd)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static const List<String> _debitKeywords = [
    'debited',
    'debit',
    'spent',
    'paid',
    'withdrawn',
    'purchase',
    'payment',
    'sent',
  ];

  static const List<String> _creditKeywords = [
    'credited',
    'credit',
    'received',
    'deposited',
    'refund',
    'cashback',
  ];

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // PARSER
  // ==========================================================================

  Future<void> _parseSms() async {
    final text = _pasteController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _candidates = [];
      });

      _showMessage(
        'Paste at least one bank or UPI SMS first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isParsing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 250));

    final blocks = text
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList();

    final chunks = blocks.length > 1 ? blocks : [text];

    final found = <_SmsCandidate>[];

    for (final chunk in chunks) {
      final lower = chunk.toLowerCase();

      final amountMatch = _amountPattern.firstMatch(chunk);

      if (amountMatch == null) {
        continue;
      }

      final amountText = amountMatch.group(1);

      if (amountText == null) {
        continue;
      }

      final amount = double.tryParse(
        amountText.replaceAll(',', '').trim(),
      );

      if (amount == null || amount <= 0) {
        continue;
      }

      final isDebit = _debitKeywords.any(
        (keyword) => lower.contains(keyword),
      );

      final isCredit = _creditKeywords.any(
        (keyword) => lower.contains(keyword),
      );

      if (!isDebit && !isCredit) {
        continue;
      }

      final type = isCredit && !isDebit ? TxType.income : TxType.expense;

      found.add(
        _SmsCandidate(
          rawBody: chunk,
          amount: amount,
          type: type,
          category: _detectCategory(lower),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _candidates = found;
      _isParsing = false;
    });

    if (found.isEmpty) {
      _showMessage(
        'No transactions were detected. Try pasting a complete bank/UPI SMS.',
        isError: true,
      );
    } else {
      _showMessage(
        '${found.length} transaction${found.length == 1 ? '' : 's'} detected.',
      );
    }
  }

  String _detectCategory(String text) {
    if (text.contains('bill') ||
        text.contains('electricity') ||
        text.contains('recharge') ||
        text.contains('utility')) {
      return 'Bills';
    }

    if (text.contains('food') ||
        text.contains('restaurant') ||
        text.contains('swiggy') ||
        text.contains('zomato') ||
        text.contains('cafe')) {
      return 'Food';
    }

    if (text.contains('fuel') ||
        text.contains('petrol') ||
        text.contains('diesel')) {
      return 'Transport';
    }

    if (text.contains('amazon') ||
        text.contains('flipkart') ||
        text.contains('shopping') ||
        text.contains('store')) {
      return 'Shopping';
    }

    if (text.contains('salary') ||
        text.contains('payroll') ||
        text.contains('salary credit')) {
      return 'Salary';
    }

    if (text.contains('upi')) {
      return 'UPI';
    }

    return 'Other';
  }

  // ==========================================================================
  // IMPORT
  // ==========================================================================

  void _importCandidate(_SmsCandidate candidate) {
    final app = AppScope.of(context);

    if (candidate.imported) {
      return;
    }

    app.addTransaction(
      AppTransaction(
        id: app.newId(),
        type: candidate.type,
        amount: candidate.amount,
        category: candidate.category,
        note: 'Added from SMS',
        date: DateTime.now(),
      ),
    );

    setState(() {
      candidate.imported = true;
    });

    _showMessage('Transaction added successfully.');
  }

  void _importAll() {
    final app = AppScope.of(context);

    final pending = _candidates.where((candidate) {
      return !candidate.imported;
    }).toList();

    if (pending.isEmpty) {
      _showMessage('All detected transactions are already added.');
      return;
    }

    for (final candidate in pending) {
      app.addTransaction(
        AppTransaction(
          id: app.newId(),
          type: candidate.type,
          amount: candidate.amount,
          category: candidate.category,
          note: 'Added from SMS',
          date: DateTime.now(),
        ),
      );

      candidate.imported = true;
    }

    setState(() {});

    _showMessage(
      '${pending.length} transaction${pending.length == 1 ? '' : 's'} added.',
    );
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();

    setState(() {
      _pasteController.clear();
      _candidates = [];
    });
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final pendingCount = _candidates
        .where(
          (candidate) => !candidate.imported,
        )
        .length;

    final importedCount = _candidates
        .where(
          (candidate) => candidate.imported,
        )
        .length;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.sms_rounded,
                color: colors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            const Text(
              'SMS Import',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          if (_candidates.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 18),
            _buildHowItWorks(context),
            const SizedBox(height: 18),
            _buildPasteSection(context),
            if (_candidates.isNotEmpty) ...[
              const SizedBox(height: 22),
              _buildResultsHeader(
                context,
                pendingCount,
                importedCount,
              ),
              const SizedBox(height: 11),
              ...List.generate(
                _candidates.length,
                (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _buildTransactionCard(
                      context,
                      _candidates[index],
                    ),
                  );
                },
              ),
            ],
            if (_candidates.isEmpty) ...[
              const SizedBox(height: 20),
              _buildEmptyState(context),
            ],
            const SizedBox(height: 12),
            _buildSafetyNote(context),
          ],
        ),
      ),
      bottomNavigationBar: pendingCount > 0
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _importAll,
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: Text(
                    'Add All $pendingCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ==========================================================================
  // HERO
  // ==========================================================================

  Widget _buildHeroCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.primary.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.20),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart SMS Import',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Turn bank alerts into transactions in seconds.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // HOW IT WORKS
  // ==========================================================================

  Widget _buildHowItWorks(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          _stepIcon(
            context,
            number: '1',
            icon: Icons.content_copy_rounded,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _stepText(
              'Copy',
              'Bank SMS',
            ),
          ),
          _connector(context),
          const SizedBox(width: 9),
          _stepIcon(
            context,
            number: '2',
            icon: Icons.paste_rounded,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _stepText(
              'Paste',
              'Message',
            ),
          ),
          _connector(context),
          const SizedBox(width: 9),
          _stepIcon(
            context,
            number: '3',
            icon: Icons.auto_graph_rounded,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _stepText(
              'Review',
              'Transaction',
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIcon(
    BuildContext context, {
    required String number,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              size: 18,
              color: colors.primary,
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepText(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _connector(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Icon(
      Icons.chevron_right_rounded,
      size: 17,
      color: colors.onSurfaceVariant.withValues(alpha: 0.35),
    );
  }

  // ==========================================================================
  // PASTE SECTION
  // ==========================================================================

  Widget _buildPasteSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: colors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paste your SMS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'One or multiple messages',
                      style: TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pasteController.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear text',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _pasteController.clear();
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.onSurfaceVariant,
                    size: 19,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _pasteController,
            minLines: 6,
            maxLines: 9,
            textInputAction: TextInputAction.newline,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Example:\n'
                  'Rs.450 debited from your account for UPI purchase\n\n'
                  'Paste your bank SMS here...',
              hintStyle: TextStyle(
                color: colors.onSurfaceVariant.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.45,
              ),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.35),
              contentPadding: const EdgeInsets.all(15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 51,
            child: FilledButton.icon(
              onPressed: _isParsing ? null : _parseSms,
              icon: _isParsing
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _isParsing ? 'Detecting...' : 'Detect Transactions',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // RESULTS HEADER
  // ==========================================================================

  Widget _buildResultsHeader(
    BuildContext context,
    int pendingCount,
    int importedCount,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detected Transactions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$pendingCount pending Ã¢â‚¬Â¢ $importedCount added',
                style: TextStyle(
                  fontSize: 10.5,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_candidates.length}',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TRANSACTION CARD
  // ==========================================================================

  Widget _buildTransactionCard(
    BuildContext context,
    _SmsCandidate candidate,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isIncome = candidate.type == TxType.income;

    final transactionColor =
        isIncome ? const Color(0xFF2FB380) : const Color(0xFFE2574C);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: candidate.imported ? 0.68 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: candidate.imported
                ? Colors.green.withValues(alpha: 0.20)
                : colors.outlineVariant.withValues(alpha: 0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                    color: transactionColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: transactionColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncome ? 'Income detected' : 'Expense detected',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatMoney(
                          candidate.amount,
                          AppScope.of(context).currency,
                        ),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: transactionColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (candidate.imported)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Added',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Add transaction',
                    onPressed: () {
                      _importCandidate(candidate);
                    },
                    icon: Icon(
                      Icons.add_circle_rounded,
                      color: colors.primary,
                      size: 27,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _categoryChip(
                  context,
                  Icons.label_outline_rounded,
                  candidate.category,
                ),
                const SizedBox(width: 7),
                _categoryChip(
                  context,
                  isIncome
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  isIncome ? 'Income' : 'Expense',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                candidate.rawBody,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: colors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // EMPTY STATE
  // ==========================================================================

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Ready to import',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Paste a bank or UPI notification above and we will look for amounts, income/expense keywords and common categories.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SAFETY NOTE
  // ==========================================================================

  Widget _buildSafetyNote(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Colors.amber.shade800,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'This is a best-effort parser. Always verify the amount and category before adding a transaction.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
