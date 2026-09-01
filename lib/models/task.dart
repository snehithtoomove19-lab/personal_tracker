enum TaskPriority { low, medium, high }

enum TaskRepeat { none, daily, weekly, monthly }

const List<String> kTaskCategories = [
  'Personal',
  'Work',
  'Health',
  'Study',
  'Shopping',
  'Home',
  'Other'
];

/// A small checklist item within a task (e.g. "Buy flour" inside a
/// "Bake a cake" task).
class SubTask {
  String id;
  String title;
  bool completed;

  SubTask({required this.id, required this.title, this.completed = false});

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'completed': completed};

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'],
        title: json['title'],
        completed: json['completed'] ?? false,
      );
}

class AppTask {
  String id;
  String title;
  String description;
  DateTime? dueDate;
  int? dueTimeMinutes; // minutes since midnight, e.g. 9:30 AM = 570
  bool completed;
  DateTime createdAt;
  bool pinned;
  TaskPriority priority;
  String category;
  TaskRepeat repeat;
  bool reminderEnabled;
  List<SubTask> subtasks;

  AppTask({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.dueTimeMinutes,
    this.completed = false,
    required this.createdAt,
    this.pinned = false,
    this.priority = TaskPriority.medium,
    this.category = 'Personal',
    this.repeat = TaskRepeat.none,
    this.reminderEnabled = false,
    List<SubTask>? subtasks,
  }) : subtasks = subtasks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'dueTimeMinutes': dueTimeMinutes,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
        'pinned': pinned,
        'priority': priority.name,
        'category': category,
        'repeat': repeat.name,
        'reminderEnabled': reminderEnabled,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory AppTask.fromJson(Map<String, dynamic> json) => AppTask(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        dueTimeMinutes: json['dueTimeMinutes'],
        completed: json['completed'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        pinned: json['pinned'] ?? false,
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == (json['priority'] ?? 'medium'),
          orElse: () => TaskPriority.medium,
        ),
        category: json['category'] ?? 'Personal',
        repeat: TaskRepeat.values.firstWhere(
          (e) => e.name == (json['repeat'] ?? 'none'),
          orElse: () => TaskRepeat.none,
        ),
        reminderEnabled: json['reminderEnabled'] ?? false,
        subtasks: (json['subtasks'] as List? ?? [])
            .map((s) => SubTask.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
