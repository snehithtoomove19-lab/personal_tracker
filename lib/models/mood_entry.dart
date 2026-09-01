import 'package:flutter/material.dart';

/// Mood is stored as a short key (e.g. "great") rather than an emoji, and
/// mapped to a Material icon + color for display. This keeps the data
/// portable (works fine in CSV/JSON exports and any locale) and keeps the
/// UI free of emoji characters.
class MoodEntry {
  String id;
  DateTime date; // date-only (time zeroed)
  String mood; // one of kMoodOptions' key
  String note;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'mood': mood,
        'note': note,
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'],
        date: DateTime.parse(json['date']),
        // Backward-compatible: older backups may still have raw emoji;
        // fall back to "okay" if the value isn't a recognised key.
        mood: kMoodOptions.any((m) => m.key == json['mood'])
            ? json['mood']
            : 'okay',
        note: json['note'] ?? '',
      );

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class MoodOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const MoodOption(
      {required this.key,
      required this.label,
      required this.icon,
      required this.color});
}

/// Standard mood options used across the app.
const List<MoodOption> kMoodOptions = [
  MoodOption(
      key: 'great',
      label: 'Great',
      icon: Icons.sentiment_very_satisfied,
      color: Color(0xFF2FB380)),
  MoodOption(
      key: 'good',
      label: 'Good',
      icon: Icons.sentiment_satisfied,
      color: Color(0xFF7CB342)),
  MoodOption(
      key: 'okay',
      label: 'Okay',
      icon: Icons.sentiment_neutral,
      color: Color(0xFFFFA726)),
  MoodOption(
      key: 'low',
      label: 'Low',
      icon: Icons.sentiment_dissatisfied,
      color: Color(0xFFEF6C00)),
  MoodOption(
      key: 'bad',
      label: 'Bad',
      icon: Icons.sentiment_very_dissatisfied,
      color: Color(0xFFE2574C)),
];

MoodOption moodOptionFor(String key) =>
    kMoodOptions.firstWhere((m) => m.key == key, orElse: () => kMoodOptions[2]);
