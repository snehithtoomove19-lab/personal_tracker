enum TxType { income, expense }
enum TxRepeat { none, weekly, monthly }

const List<String> kPaymentMethods = ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Other'];

class AppTransaction {
  String id;
  TxType type;
  double amount;
  String category;
  String note;
  DateTime date;
  String paymentMethod;
  TxRepeat repeat;

  AppTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
    this.paymentMethod = 'Cash',
    this.repeat = TxRepeat.none,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
        'repeat': repeat.name,
      };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
        id: json['id'],
        type: TxType.values.firstWhere((e) => e.name == json['type']),
        amount: (json['amount'] as num).toDouble(),
        category: json['category'],
        note: json['note'] ?? '',
        date: DateTime.parse(json['date']),
        paymentMethod: json['paymentMethod'] ?? 'Cash',
        repeat: TxRepeat.values.firstWhere(
          (e) => e.name == (json['repeat'] ?? 'none'),
          orElse: () => TxRepeat.none,
        ),
      );
}
