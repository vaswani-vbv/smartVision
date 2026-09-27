class MedicalProfileModel {
  final String? id;
  final String diabetesType;
  final int age;
  final double weightKg;
  final double heightCm;
  final String activityLevel;
  final String? medications;

  MedicalProfileModel({
    this.id,
    required this.diabetesType,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevel,
    this.medications,
  });

  factory MedicalProfileModel.fromJson(Map<String, dynamic> json) {
    return MedicalProfileModel(
      id: json['id']?.toString(),
      diabetesType: json['diabetes_type']?.toString() ?? 'Type 2',
      age: (json['age'] as num?)?.toInt() ?? 30,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 70.0,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 170.0,
      activityLevel: json['activity_level']?.toString() ?? 'Moderate',
      medications: json['medications']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diabetes_type': diabetesType,
      'age': age,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'activity_level': activityLevel,
      'medications': medications,
    };
  }
}
