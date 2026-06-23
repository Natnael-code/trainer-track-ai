class ClientModel {
  final String id;
  final String name;
  final String phoneNumber;
  final int age;
  final String gender;
  final double startingWeight; // in kg
  final double height; // in cm
  final String? startingBodyFat;
  final String? localProfileImagePath;
  final String injuries;
  final String medicalConditions;
  final String experienceLevel;
  final String lifestyleType;
  final DateTime joinedDate;
  final String status; // 'active' or 'inactive'
  final String? groupId;

  ClientModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.age,
    required this.gender,
    required this.startingWeight,
    required this.height,
    this.startingBodyFat,
    this.localProfileImagePath,
    required this.injuries,
    required this.medicalConditions,
    required this.experienceLevel,
    required this.lifestyleType,
    required this.joinedDate,
    this.status = 'active',
    this.groupId,
  });

  // Safe calculated getter for UI layout matrices
  double get bmi {
    if (height <= 0) return 0.0;
    double heightInMeters = height / 100.0;
    return startingWeight / (heightInMeters * heightInMeters);
  }
}
