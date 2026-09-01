class AppGoal {
  String id;
  String title;
  DateTime? targetDate;
  int progress; // 0-100
  bool completed;
  DateTime createdAt;

  AppGoal({
    required this.id,
    required this.title,
    this.targetDate,
    this.progress = 0,
    this.completed = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetDate': targetDate?.toIso8601String(),
        'progress': progress,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppGoal.fromJson(Map<String, dynamic> json) => AppGoal(
        id: json['id'],
        title: json['title'],
        targetDate: json['targetDate'] != null
            ? DateTime.parse(json['targetDate'])
            : null,
        progress: json['progress'] ?? 0,
        completed: json['completed'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
