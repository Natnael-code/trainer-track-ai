class ClientModel {
  final String id;
  final String name;
  final String phoneNumber;
  final int age;
  final String gender;

  // Physical Baselines
  final double startingWeight;
  final double height;
  final double? startingBodyFat; // Optional field
  final String? localProfileImagePath; // Path to local storage folder

  // Medical Screening (The Red Flags)
  final String injuries;
  final String medicalConditions;

  // Lifestyle Vectors
  final String experienceLevel; // Beginner, Intermediate, Advanced
  final String lifestyleType; // Sedentary, Active

  final DateTime joinedDate;
  final String status; // active, inactive

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
  });

  // Calculate Body Mass Index (BMI) dynamically
  double get bmi {
    if (height <= 0) return 0.0;
    // Formula: weight (kg) / [height (m)]²
    final heightInMeters = height / 100;
    return startingWeight / (heightInMeters * heightInMeters);
  }
}
