class BirthdayContact {
  final String id;
  final String name;
  final String relation;
  final DateTime date;

  BirthdayContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.date,
  });

  String get initials {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return name.isEmpty ? '?' : name[0].toUpperCase();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  DateTime nextOccurrence(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final thisYear = DateTime(now.year, date.month, date.day);
    if (!thisYear.isBefore(today)) return thisYear;
    return DateTime(now.year + 1, date.month, date.day);
  }

  int daysUntil(DateTime now) {
    final next = nextOccurrence(now);
    final target = DateTime(now.year, now.month, now.day);
    return next.difference(target).inDays;
  }

  int ageOn(DateTime referenceDate) {
    final birthdayThisYear = DateTime(referenceDate.year, date.month, date.day);
    var age = referenceDate.year - date.year;
    if (referenceDate.isBefore(birthdayThisYear)) age--;
    return age;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation,
        'date': date.toIso8601String(),
      };

  factory BirthdayContact.fromJson(Map<String, dynamic> json) {
    return BirthdayContact(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? '',
      relation: json['relation'] as String? ?? 'Friend',
      date: DateTime.parse(json['date'] as String),
    );
  }
}
