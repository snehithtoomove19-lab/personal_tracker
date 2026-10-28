class DaySignals {
  final String dateKey;
  final int sleepQuality;
  final int socialMinutesBefore10;
  final int screenMinutes;
  final int mealHour;
  final double meetingHours;
  final int focusScore;
  final bool deepWorkCompleted;
  final int workoutMinutes;
  final bool highIntensityWorkout;
  final int waterMl;

  const DaySignals({
    required this.dateKey,
    required this.sleepQuality,
    required this.socialMinutesBefore10,
    required this.screenMinutes,
    required this.mealHour,
    required this.meetingHours,
    required this.focusScore,
    required this.deepWorkCompleted,
    required this.workoutMinutes,
    required this.highIntensityWorkout,
    this.waterMl = 0,
  });

  DaySignals copyWith({int? waterMl, int? workoutMinutes}) => DaySignals(
        dateKey: dateKey,
        sleepQuality: sleepQuality,
        socialMinutesBefore10: socialMinutesBefore10,
        screenMinutes: screenMinutes,
        mealHour: mealHour,
        meetingHours: meetingHours,
        focusScore: focusScore,
        deepWorkCompleted: deepWorkCompleted,
        workoutMinutes: workoutMinutes ?? this.workoutMinutes,
        highIntensityWorkout: highIntensityWorkout,
        waterMl: waterMl ?? this.waterMl,
      );

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'sleepQuality': sleepQuality,
        'socialMinutesBefore10': socialMinutesBefore10,
        'screenMinutes': screenMinutes,
        'mealHour': mealHour,
        'meetingHours': meetingHours,
        'focusScore': focusScore,
        'deepWorkCompleted': deepWorkCompleted,
        'workoutMinutes': workoutMinutes,
        'highIntensityWorkout': highIntensityWorkout,
        'waterMl': waterMl,
      };

  factory DaySignals.fromJson(Map<String, dynamic> json) => DaySignals(
        dateKey: json['dateKey'] as String,
        sleepQuality: (json['sleepQuality'] as num).toInt(),
        socialMinutesBefore10: (json['socialMinutesBefore10'] as num).toInt(),
        screenMinutes: (json['screenMinutes'] as num).toInt(),
        mealHour: (json['mealHour'] as num).toInt(),
        meetingHours: (json['meetingHours'] as num).toDouble(),
        focusScore: (json['focusScore'] as num).toInt(),
        deepWorkCompleted: json['deepWorkCompleted'] as bool,
        workoutMinutes: (json['workoutMinutes'] as num).toInt(),
        highIntensityWorkout: json['highIntensityWorkout'] as bool,
        waterMl: (json['waterMl'] as num?)?.toInt() ?? 0,
      );
}

String daySignalsKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
