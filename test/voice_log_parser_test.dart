import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/widgets/voice_log_button.dart';

void main() {
  test('extracts water, exercise, and anxious mood', () {
    final parsed = ParsedVoiceLog.parse(
      'Drank 2 glasses of water, went for a 20 min jog, '
      'feeling slightly anxious.',
    );

    expect(parsed.waterMl, 500);
    expect(parsed.workoutMinutes, 20);
    expect(parsed.workoutType, 'jog');
    expect(parsed.moodKey, 'low');
    expect(parsed.hasEntries, isTrue);
  });

  test('supports millilitres and trailing workout duration', () {
    final parsed = ParsedVoiceLog.parse(
      'Had 600 ml water and jogged for 25 minutes.',
    );

    expect(parsed.waterMl, 600);
    expect(parsed.workoutMinutes, 25);
    expect(parsed.workoutType, 'jogged');
  });

  test('does not invent entries without a supported signal', () {
    expect(ParsedVoiceLog.parse('Had a nice day.').hasEntries, isFalse);
  });
}
