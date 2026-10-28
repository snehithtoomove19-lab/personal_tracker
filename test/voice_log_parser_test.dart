import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/widgets/voice_log_button.dart';

void main() {
  test('extracts water, exercise, food expense, and anxious mood', () {
    final parsed = ParsedVoiceLog.parse(
      'Drank 2 glasses of water, went for a 20 min jog, '
      'spent \$14 on lunch, feeling slightly anxious.',
    );

    expect(parsed.waterMl, 500);
    expect(parsed.workoutMinutes, 20);
    expect(parsed.workoutType, 'jog');
    expect(parsed.expenseAmount, 14);
    expect(parsed.expenseCategory, 'Food');
    expect(parsed.moodKey, 'low');
    expect(parsed.hasEntries, isTrue);
  });

  test('supports millilitres, trailing workout duration, and other expenses',
      () {
    final parsed = ParsedVoiceLog.parse(
      'Had 600 ml water, jogged for 25 minutes, spent 9 dollars on a taxi.',
    );

    expect(parsed.waterMl, 600);
    expect(parsed.workoutMinutes, 25);
    expect(parsed.workoutType, 'jogged');
    expect(parsed.expenseAmount, 9);
    expect(parsed.expenseCategory, 'Transport');
  });

  test('parses thousands separators without truncating the amount', () {
    final parsed = ParsedVoiceLog.parse('Spent \$1,250.50 on shopping.');
    expect(parsed.expenseAmount, 1250.50);
    expect(parsed.expenseCategory, 'Shopping');
  });

  test('does not invent entries without a supported signal', () {
    expect(ParsedVoiceLog.parse('Had a nice day.').hasEntries, isFalse);
  });
}
