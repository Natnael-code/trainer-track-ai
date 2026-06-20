// 1. Group Session Model Blueprint
class GroupModel {
  final String id;
  final String groupName;
  final DateTime createdDate;
  final String status; // active, completed

  GroupModel({
    required this.id,
    required this.groupName,
    required this.createdDate,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupName': groupName,
      'createdDate': createdDate.toIso8601String(),
      'status': status,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String,
      groupName: map['groupName'] as String,
      createdDate: DateTime.parse(map['createdDate'] as String),
      status: map['status'] as String,
    );
  }
}

// 2. 30-Day Calendar Management Model
class ScheduleDayModel {
  final String id;
  final String? clientId; // Nullable if assigned to a Group
  final String? groupId; // Nullable if assigned to an Individual
  final int dayNumber; // Day 1 to Day 30
  final bool isWorkDay; // true = Workout, false = Rest Day
  final String monthConfigId; // e.g., "June_2026"

  ScheduleDayModel({
    required this.id,
    this.clientId,
    this.groupId,
    required this.dayNumber,
    required this.isWorkDay,
    required this.monthConfigId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'groupId': groupId,
      'dayNumber': dayNumber,
      'isWorkDay': isWorkDay ? 1 : 0, // SQLite uses 1/0 for booleans
      'monthConfigId': monthConfigId,
    };
  }

  factory ScheduleDayModel.fromMap(Map<String, dynamic> map) {
    return ScheduleDayModel(
      id: map['id'] as String,
      clientId: map['clientId'] as String?,
      groupId: map['groupId'] as String?,
      dayNumber: map['dayNumber'] as int,
      isWorkDay: map['isWorkDay'] == 1,
      monthConfigId: map['monthConfigId'] as String,
    );
  }
}

// 3. Daily Workout Routine Model
class WorkoutPlanModel {
  final String id;
  final String dayScheduleId; // Links directly to a ScheduleDayModel
  final String routineName; // e.g., "Push Day Upper Body"
  final String
  exercisesJson; // Structured workout details stored cleanly as a raw string text

  WorkoutPlanModel({
    required this.id,
    required this.dayScheduleId,
    required this.routineName,
    required this.exercisesJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayScheduleId': dayScheduleId,
      'routineName': routineName,
      'exercisesJson': exercisesJson,
    };
  }

  factory WorkoutPlanModel.fromMap(Map<String, dynamic> map) {
    return WorkoutPlanModel(
      id: map['id'] as String,
      dayScheduleId: map['dayScheduleId'] as String,
      routineName: map['routineName'] as String,
      exercisesJson: map['exercisesJson'] as String,
    );
  }
}
