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
    final thisYear = _birthdayInYear(now.year);
    if (!thisYear.isBefore(today)) return thisYear;
    return _birthdayInYear(now.year + 1);
  }

  int daysUntil(DateTime now) {
    final next = nextOccurrence(now);
    final target = DateTime(now.year, now.month, now.day);
    return next.difference(target).inDays;
  }

  int ageOn(DateTime referenceDate) {
    final birthdayThisYear = _birthdayInYear(referenceDate.year);
    var age = referenceDate.year - date.year;
    if (referenceDate.isBefore(birthdayThisYear)) age--;
    return age;
  }

  DateTime _birthdayInYear(int year) {
    // Keep Feb 29 birthdays on Feb 28 in non-leap years.
    if (date.month == DateTime.february && date.day == 29) {
      final isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
      return DateTime(year, DateTime.february, isLeapYear ? 29 : 28);
    }
    return DateTime(year, date.month, date.day);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation,
        'date': date.toIso8601String(),
      };

  factory BirthdayContact.fromJson(Map<String, dynamic> json) {
    return BirthdayContact(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? '',
      relation: json['relation'] as String? ?? 'Friend',
      date: DateTime.parse(json['date'] as String),
    );
  }
}
