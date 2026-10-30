import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/services/day_signals_import_service.dart';

void main() {
  test('parses normalized daily-signal JSON', () {
    final signals = DaySignalsImportService.parse(
      '[{"dateKey":"2026-10-30","sleepQuality":4,'
      '"workoutMinutes":20,"waterMl":500}]',
    );

    expect(signals, hasLength(1));
    expect(signals.single.dateKey, '2026-10-30');
    expect(signals.single.sleepQuality, 4);
    expect(signals.single.workoutMinutes, 20);
    expect(signals.single.waterMl, 500);
  });

  test('parses CSV with optional values and true/false fields', () {
    final signals = DaySignalsImportService.parse(
      'dateKey,sleepQuality,deepWorkCompleted,workoutMinutes\n'
      '2026-10-29,3,true,25\n'
      '2026-10-30,,false,0',
    );

    expect(signals, hasLength(2));
    expect(signals.first.deepWorkCompleted, isTrue);
    expect(signals.first.workoutMinutes, 25);
    expect(signals.last.sleepQuality, isNull);
    expect(signals.last.deepWorkCompleted, isFalse);
  });

  test('parses signals from a full tracker backup', () {
    final signals = DaySignalsImportService.parse(
      '{"version":1,"daySignals":[{"dateKey":"2026-10-30","waterMl":300}]}',
    );

    expect(signals.single.waterMl, 300);
  });

  test('rejects invalid values and duplicate dates instead of guessing', () {
    expect(
      () => DaySignalsImportService.parse(
        '[{"dateKey":"2026-10-30","sleepQuality":6}]',
      ),
      throwsFormatException,
    );
    expect(
      () => DaySignalsImportService.parse(
        '[{"dateKey":"2026-10-30","meetingHours":"NaN"}]',
      ),
      throwsFormatException,
    );
    expect(
      () => DaySignalsImportService.parse(
        '[{"dateKey":"2026-10-30"},{"dateKey":"2026-10-30"}]',
      ),
      throwsFormatException,
    );
  });
}
