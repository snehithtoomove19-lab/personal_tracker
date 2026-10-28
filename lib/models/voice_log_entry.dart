class VoiceLogEntry {
  final String id;
  final DateTime createdAt;
  final int waterMl;
  final int workoutMinutes;
  final String workoutType;
  final double? expenseAmount;
  final String? expenseCategory;
  final String? mood;

  const VoiceLogEntry({
    required this.id,
    required this.createdAt,
    this.waterMl = 0,
    this.workoutMinutes = 0,
    this.workoutType = '',
    this.expenseAmount,
    this.expenseCategory,
    this.mood,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'waterMl': waterMl,
        'workoutMinutes': workoutMinutes,
        'workoutType': workoutType,
        'expenseAmount': expenseAmount,
        'expenseCategory': expenseCategory,
        'mood': mood,
      };

  factory VoiceLogEntry.fromJson(Map<String, dynamic> json) => VoiceLogEntry(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        waterMl: (json['waterMl'] as num?)?.toInt() ?? 0,
        workoutMinutes: (json['workoutMinutes'] as num?)?.toInt() ?? 0,
        workoutType: json['workoutType'] as String? ?? '',
        expenseAmount: (json['expenseAmount'] as num?)?.toDouble(),
        expenseCategory: json['expenseCategory'] as String?,
        mood: json['mood'] as String?,
      );
}
