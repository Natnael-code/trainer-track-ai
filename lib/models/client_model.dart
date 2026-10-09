class ClientModel {
  final String id;
  final String name;
  final String phoneNumber;
  final int age;
  final String gender;
  final double startingWeight;
  final double height;
  final String? startingBodyFat;
  final String? localProfileImagePath;
  final String injuries;
  final String medicalConditions;
  final String experienceLevel;
  final String lifestyleType;
  final DateTime joinedDate;
  final String status;
  final String? groupId;

  final int availableDaysPerWeek;
  final int workoutSessionsPerDay;
  final String fitnessGoal;

  ClientModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.age = 25,
    this.gender = 'Male',
    required this.startingWeight,
    this.height = 175.0,
    this.startingBodyFat,
    this.localProfileImagePath,
    this.injuries = 'None',
    this.medicalConditions = 'None',
    this.experienceLevel = 'Beginner',
    this.lifestyleType = 'Active',
    required this.joinedDate,
    this.status = 'active',
    this.groupId,
    this.availableDaysPerWeek = 5,
    this.workoutSessionsPerDay = 1,
    this.fitnessGoal = 'Lose Weight',
  });

  double get bmi {
    if (height <= 0) return 0.0;
    double heightInMeters = height / 100.0;
    return startingWeight / (heightInMeters * heightInMeters);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'age': age,
      'gender': gender,
      'startingWeight': startingWeight,
      'height': height,
      'startingBodyFat': startingBodyFat,
      'localProfileImagePath': localProfileImagePath,
      'injuries': injuries,
      'medicalConditions': medicalConditions,
      'experienceLevel': experienceLevel,
      'lifestyleType': lifestyleType,
      'joinedDate': joinedDate.toIso8601String(),
      'status': status,
      'groupId': groupId,
      'availableDaysPerWeek': availableDaysPerWeek,
      'workoutSessionsPerDay': workoutSessionsPerDay,
      'fitnessGoal': fitnessGoal,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      age: (map['age'] as num?)?.toInt() ?? 25,
      gender: map['gender'] as String? ?? 'Male',
      startingWeight: (map['startingWeight'] as num).toDouble(),
      height: (map['height'] as num?)?.toDouble() ?? 175.0,
      startingBodyFat: map['startingBodyFat']?.toString(),
      localProfileImagePath: map['localProfileImagePath'] as String?,
      injuries: map['injuries'] as String? ?? 'None',
      medicalConditions: map['medicalConditions'] as String? ?? 'None',
      experienceLevel: map['experienceLevel'] as String? ?? 'Beginner',
      lifestyleType: map['lifestyleType'] as String? ?? 'Active',
      joinedDate: DateTime.parse(map['joinedDate'] as String),
      status: map['status'] as String? ?? 'active',
      groupId: map['groupId'] as String?,
      availableDaysPerWeek: (map['availableDaysPerWeek'] as num?)?.toInt() ?? 5,
      workoutSessionsPerDay:
          (map['workoutSessionsPerDay'] as num?)?.toInt() ?? 1,
      fitnessGoal: map['fitnessGoal'] as String? ?? 'Lose Weight',
    );
  }
}
