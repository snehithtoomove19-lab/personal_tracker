import '../models/transaction.dart';

class SmsTransactionCandidate {
  final String sourceId;
  final String address;
  final String body;
  final DateTime date;
  final double amount;
  final TxType type;
  final String category;
  final String paymentMethod;
  final String? merchant;
  final String detectedLabel;
  final String sourceHash;

  const SmsTransactionCandidate({
    required this.sourceId,
    required this.address,
    required this.body,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.merchant,
    required this.detectedLabel,
    required this.sourceHash,
  });
}

class SmsTransactionParser {
  static final RegExp _amountPattern = RegExp(
    r'(?:rs\.?|inr|\u20B9|\$|usd)\s*([\d,]+(?:\.\d{1,2})?)|([\d,]+(?:\.\d{1,2})?)\s*(?:rs\.?|inr|\u20B9|usd)',
    caseSensitive: false,
  );

  static final RegExp _merchantPattern = RegExp(
    r'\b(?:to|at|from|merchant)\s+([A-Za-z][A-Za-z0-9 &._-]{1,40})',
    caseSensitive: false,
  );

  static SmsTransactionCandidate? parse({
    required String sourceId,
    required String address,
    required String body,
    required DateTime date,
  }) {
    final text = body.trim();
    final lower = text.toLowerCase();
    final amountMatch = _amountPattern.firstMatch(text);
    if (amountMatch == null) return null;

    final rawAmount = amountMatch.group(1) ?? amountMatch.group(2);
    final amount = double.tryParse(rawAmount?.replaceAll(',', '') ?? '');
    if (amount == null || amount <= 0 || amount > 100000000) return null;

    final isCredit = _containsAny(lower, [
      'credited',
      'credit',
      'received',
      'deposited',
      'refund',
      'cashback',
      'cash back',
      'reversal',
    ]);
    final isDebit = _containsAny(lower, [
      'debited',
      'debit',
      'spent',
      'paid',
      'withdrawn',
      'purchase',
      'payment',
      'sent',
      'transferred',
      'emi',
      'recharge',
    ]);
    if (!isCredit && !isDebit) return null;

    final type = isCredit && !isDebit ? TxType.income : TxType.expense;
    final category = _category(lower, type);
    final paymentMethod = _paymentMethod(lower);
    final merchant = _merchant(text);
    final label = _label(lower, category, paymentMethod, type);
    final sourceHash =
        _hash('$sourceId|$address|${date.millisecondsSinceEpoch}|$text');

    return SmsTransactionCandidate(
      sourceId: sourceId,
      address: address,
      body: text,
      date: date,
      amount: amount,
      type: type,
      category: category,
      paymentMethod: paymentMethod,
      merchant: merchant,
      detectedLabel: label,
      sourceHash: sourceHash,
    );
  }

  static bool _containsAny(String text, List<String> values) =>
      values.any(text.contains);

  static String _paymentMethod(String text) {
    if (_containsAny(text, ['upi', 'phonepe', 'gpay', 'google pay', 'paytm'])) {
      return 'UPI';
    }
    if (text.contains('atm') || text.contains('cash withdrawal')) {
      return 'Cash';
    }
    if (text.contains('credit card')) return 'Card';
    if (text.contains('debit card') || text.contains('card')) return 'Card';
    if (_containsAny(text, ['bank transfer', 'neft', 'imps', 'rtgs'])) {
      return 'Bank Transfer';
    }
    return 'Other';
  }

  static String _category(String text, TxType type) {
    if (text.contains('refund') || text.contains('reversal')) return 'Refund';
    if (text.contains('cashback') || text.contains('cash back')) {
      return 'Cashback';
    }
    if (text.contains('salary') || text.contains('payroll')) return 'Salary';
    if (text.contains('emi')) return 'EMI';
    if (text.contains('recharge')) return 'Recharge';
    if (text.contains('atm') || text.contains('withdraw')) return 'ATM';
    if (text.contains('fuel') ||
        text.contains('petrol') ||
        text.contains('diesel')) {
      return 'Fuel';
    }
    if (_containsAny(
        text, ['food', 'restaurant', 'swiggy', 'zomato', 'cafe'])) {
      return 'Food';
    }
    if (_containsAny(text, ['medical', 'pharmacy', 'hospital', 'medicine'])) {
      return 'Medical';
    }
    if (_containsAny(text, ['travel', 'flight', 'hotel', 'uber', 'ola'])) {
      return 'Travel';
    }
    if (_containsAny(text, ['bill', 'electricity', 'utility'])) return 'Bills';
    if (_containsAny(text, ['amazon', 'flipkart', 'shopping', 'store'])) {
      return 'Shopping';
    }
    if (text.contains('upi')) return 'UPI';
    if (_containsAny(text, ['bank transfer', 'neft', 'imps', 'rtgs'])) {
      return 'Bank Transfer';
    }
    return type == TxType.income ? 'Other' : 'Other';
  }

  static String _label(
      String text, String category, String method, TxType type) {
    if (text.contains('refund')) return 'Refund';
    if (text.contains('cashback') || text.contains('cash back')) {
      return 'Cashback';
    }
    if (text.contains('emi')) return 'EMI';
    if (text.contains('recharge')) return 'Recharge';
    if (text.contains('atm') || text.contains('withdraw')) {
      return 'ATM withdrawal';
    }
    if (method == 'UPI') return 'UPI Payment';
    if (method == 'Card') return 'Card transaction';
    if (method == 'Bank Transfer') return 'Bank transfer';
    return type == TxType.income ? 'Income detected' : '$category expense';
  }

  static String? _merchant(String text) {
    final match = _merchantPattern.firstMatch(text);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return value
        .split(
            RegExp(r'\s+(?:on|via|using|ref|txn|utr)\b', caseSensitive: false))
        .first
        .trim();
  }

  static String _hash(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
