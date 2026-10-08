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

// 2. Rolling Monthly Fitness Schedule Track Node
class ScheduleDayModel {
  final String id;
  final String? clientId;
  final String? groupId;
  final int dayNumber; // Day 1 to Day N (28-31)
  final bool isWorkDay; // true = Active Workout, false = Dedicated Rest Day
  final DateTime absoluteDate; // Calculated calendar milestone matching Day X
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

// 5. Personal Client Progress Track Entry
class ClientProgressModel {
  final String id;
  final String clientId;
  final double weight; // in kg
  final double height; // in cm
  final double bmi;
  final String? imagePath;
  final DateTime date;
  final String? notes;

  ClientProgressModel({
    required this.id,
    required this.clientId,
    required this.weight,
    required this.height,
    required this.bmi,
    this.imagePath,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory ClientProgressModel.fromMap(Map<String, dynamic> map) {
    return ClientProgressModel(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      weight: (map['weight'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      imagePath: map['imagePath'] as String?,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}

// 6. AI Advisor Persistent Chat Message Node
class AiChatMessageModel {
  final String id;
  final String clientId;
  final String sender; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;

  AiChatMessageModel({
    required this.id,
    required this.clientId,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AiChatMessageModel.fromMap(Map<String, dynamic> map) {
    return AiChatMessageModel(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      sender: map['sender'] as String,
      text: map['text'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
