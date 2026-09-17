import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/transaction.dart';
import 'package:personal_tracker/services/sms_transaction_parser.dart';

void main() {
  test('parses a UPI debit as an expense', () {
    final result = SmsTransactionParser.parse(
      sourceId: '1',
      address: 'BANK-ALERT',
      body: 'Your A/c XXXX debited by Rs. 500.00 through UPI to Cafe Coffee.',
      date: DateTime(2026, 9, 12, 20, 42),
    );

    expect(result, isNotNull);
    expect(result!.amount, 500);
    expect(result.type, TxType.expense);
    expect(result.category, 'Food');
    expect(result.paymentMethod, 'UPI');
    expect(result.detectedLabel, 'UPI Payment');
  });

  test('parses salary credit as income', () {
    final result = SmsTransactionParser.parse(
      sourceId: '2',
      address: 'BANK-ALERT',
      body: 'INR 45,000 credited to your account as salary credit.',
      date: DateTime(2026, 9, 1),
    );

    expect(result, isNotNull);
    expect(result!.amount, 45000);
    expect(result.type, TxType.income);
    expect(result.category, 'Salary');
  });

  test('ignores ordinary messages without financial language', () {
    final result = SmsTransactionParser.parse(
      sourceId: '3',
      address: 'FRIEND',
      body: 'Meet me at 5 pm for Rs. 500 snacks.',
      date: DateTime(2026, 9, 12),
    );

    expect(result, isNull);
  });
}
