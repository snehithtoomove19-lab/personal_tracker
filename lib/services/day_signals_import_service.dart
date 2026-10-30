import 'dart:convert';

import '../models/day_signals.dart';

class DaySignalsImportService {
  static const _headers = {
    'dateKey',
    'date',
    'sleepQuality',
    'socialMinutesBefore10',
    'screenMinutes',
    'mealHour',
    'meetingHours',
    'focusScore',
    'deepWorkCompleted',
    'workoutMinutes',
    'highIntensityWorkout',
    'waterMl',
  };

  static List<DaySignals> parse(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      throw const FormatException('Paste a CSV or JSON data export first.');
    }
    final List<dynamic> rows;
    if (text.startsWith('{') || text.startsWith('[')) {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        rows = decoded;
      } else if (decoded is Map<String, dynamic> &&
          decoded['daySignals'] is List) {
        rows = decoded['daySignals'] as List;
      } else {
        throw const FormatException(
            'JSON must be a list of daily signals or a tracker backup with a daySignals list.');
      }
    } else {
      rows = _parseCsv(text);
    }
    if (rows.isEmpty) {
      throw const FormatException('The export contains no daily records.');
    }

    final results = <DaySignals>[];
    final seenDates = <String>{};
    for (var index = 0; index < rows.length; index++) {
      final Map<String, dynamic> row;
      try {
        row = Map<String, dynamic>.from(rows[index] as Map);
      } catch (_) {
        throw FormatException('Record ${index + 1} is not an object.');
      }
      final signal = _readSignal(row, index + 1);
      if (!seenDates.add(signal.dateKey)) {
        throw FormatException(
            'The export contains more than one record for ${signal.dateKey}.');
      }
      results.add(signal);
    }
    return results;
  }

  static DaySignals _readSignal(Map<String, dynamic> row, int recordNumber) {
    final rawDate = row['dateKey'] ?? row['date'];
    if (rawDate is! String || rawDate.trim().isEmpty) {
      throw FormatException('Record $recordNumber is missing dateKey.');
    }
    final parsedDate = DateTime.tryParse(rawDate.trim());
    if (parsedDate == null) {
      throw FormatException(
          'Record $recordNumber has an invalid date: ${rawDate.trim()}.');
    }
    final dateKey = daySignalsKey(parsedDate);

    int? integer(String name, {int? minimum, int? maximum}) {
      final value = row[name];
      if (value == null || value.toString().trim().isEmpty) return null;
      final parsed = value is num ? value.toInt() : int.tryParse('$value');
      if (parsed == null ||
          (value is num && value != parsed) ||
          (minimum != null && parsed < minimum) ||
          (maximum != null && parsed > maximum)) {
        throw FormatException(
            'Record $recordNumber has an invalid $name value.');
      }
      return parsed;
    }

    double? decimal(String name, {double? minimum}) {
      final value = row[name];
      if (value == null || value.toString().trim().isEmpty) return null;
      final parsed =
          value is num ? value.toDouble() : double.tryParse('$value');
      if (parsed == null ||
          !parsed.isFinite ||
          (minimum != null && parsed < minimum)) {
        throw FormatException(
            'Record $recordNumber has an invalid $name value.');
      }
      return parsed;
    }

    bool? boolean(String name) {
      final value = row[name];
      if (value == null || value.toString().trim().isEmpty) return null;
      if (value is bool) return value;
      switch ('$value'.toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
        default:
          throw FormatException(
              'Record $recordNumber has an invalid $name value.');
      }
    }

    final unknown = row.keys.where((key) => !_headers.contains(key));
    if (unknown.isNotEmpty) {
      throw FormatException(
          'Record $recordNumber has unsupported field “${unknown.first}”. Use the documented daily-signal fields.');
    }
    return DaySignals(
      dateKey: dateKey,
      sleepQuality: integer('sleepQuality', minimum: 1, maximum: 5),
      socialMinutesBefore10: integer('socialMinutesBefore10', minimum: 0),
      screenMinutes: integer('screenMinutes', minimum: 0),
      mealHour: integer('mealHour', minimum: 0, maximum: 23),
      meetingHours: decimal('meetingHours', minimum: 0),
      focusScore: integer('focusScore', minimum: 0, maximum: 10),
      deepWorkCompleted: boolean('deepWorkCompleted'),
      workoutMinutes: integer('workoutMinutes', minimum: 0),
      highIntensityWorkout: boolean('highIntensityWorkout'),
      waterMl: integer('waterMl', minimum: 0),
    );
  }

  static List<Map<String, dynamic>> _parseCsv(String text) {
    final records = <List<String>>[];
    final row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      if (quoted) {
        if (char == '"' && index + 1 < text.length && text[index + 1] == '"') {
          field.write('"');
          index++;
        } else if (char == '"') {
          quoted = false;
        } else {
          field.write(char);
        }
      } else if (char == '"' && field.toString().trim().isEmpty) {
        field.clear();
        quoted = true;
      } else if (char == ',') {
        row.add(field.toString().trim());
        field.clear();
      } else if (char == '\n') {
        row.add(field.toString().trim());
        field.clear();
        if (row.any((value) => value.isNotEmpty)) records.add(List.of(row));
        row.clear();
      } else if (char != '\r') {
        field.write(char);
      }
    }
    if (quoted) throw const FormatException('CSV contains an unclosed quote.');
    row.add(field.toString().trim());
    if (row.any((value) => value.isNotEmpty)) records.add(List.of(row));
    if (records.length < 2) {
      throw const FormatException(
          'CSV needs a header and at least one record.');
    }

    final headers = records.first;
    if (headers.toSet().length != headers.length) {
      throw const FormatException('CSV contains duplicate column names.');
    }
    if (!headers.contains('dateKey') && !headers.contains('date')) {
      throw const FormatException('CSV needs a dateKey or date column.');
    }
    for (final header in headers) {
      if (!_headers.contains(header)) {
        throw FormatException('Unsupported CSV column “$header”.');
      }
    }
    return [
      for (var index = 1; index < records.length; index++)
        if (records[index].length == headers.length)
          Map<String, dynamic>.fromIterables(headers, records[index])
        else
          throw FormatException(
              'CSV row $index has ${records[index].length} values; expected ${headers.length}.'),
    ];
  }
}
