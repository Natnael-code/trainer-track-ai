// 1. Group Model Cluster Blueprint
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
      status: map['status'] as String? ?? 'active',
    );
  }
}

// 2. Rolling 30-Day Fitness Schedule Track Node
class ScheduleDayModel {
  final String id;
  final String? clientId;
  final String? groupId;
  final int dayNumber; // Strictly Day 1 to Day 30
  final bool isWorkDay; // true = Active Workout, false = Dedicated Rest Day
  final DateTime
  absoluteDate; // Calculated rolling calendar milestone matching Day X
  final String status; // 'Pending', 'Completed', 'Missed'

  ScheduleDayModel({
    required this.id,
    this.clientId,
    this.groupId,
    required this.dayNumber,
    required this.isWorkDay,
    required this.absoluteDate,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'groupId': groupId,
      'dayNumber': dayNumber,
      'isWorkDay': isWorkDay ? 1 : 0,
      'absoluteDate': absoluteDate.toIso8601String(),
      'status': status,
    };
  }

  factory ScheduleDayModel.fromMap(Map<String, dynamic> map) {
    return ScheduleDayModel(
      id: map['id'] as String,
      clientId: map['clientId'] as String?,
      groupId: map['groupId'] as String?,
      dayNumber: map['dayNumber'] as int,
      isWorkDay: map['isWorkDay'] == 1 || map['isWorkDay'] == true,
      absoluteDate: DateTime.parse(map['absoluteDate'] as String),
      status: map['status'] as String? ?? 'Pending',
    );
  }
}

// 3. Isolated Single-Day Custom Target Workout Plan
class WorkoutPlanModel {
  final String id;
  final String dayScheduleId;
  final String routineName; // e.g., "Leg Day Quads Focus"
  final String exercisesJson; // Custom exercise text or bullets for this day

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

// 4. Group Attendance Tracker Node
class GroupAttendanceModel {
  final String id;
  final String groupId;
  final String dayScheduleId;
  final String clientId;
  final String status; // 'Present', 'Absent'
  final DateTime date;

  GroupAttendanceModel({
    required this.id,
    required this.groupId,
    required this.dayScheduleId,
    required this.clientId,
    required this.status,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'dayScheduleId': dayScheduleId,
      'clientId': clientId,
      'status': status,
      'date': date.toIso8601String(),
    };
  }

  factory GroupAttendanceModel.fromMap(Map<String, dynamic> map) {
    return GroupAttendanceModel(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      dayScheduleId: map['dayScheduleId'] as String,
      clientId: map['clientId'] as String,
      status: map['status'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }
}
