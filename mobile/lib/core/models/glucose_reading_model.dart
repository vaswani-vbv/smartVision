class GlucoseReadingModel {
  final String? id;
  final double valueMgdl;
  final String readingType; // fasting, post_meal, pre_meal, random
  final String? notes;
  final DateTime measuredAt;

  GlucoseReadingModel({
    this.id,
    required this.valueMgdl,
    required this.readingType,
    this.notes,
    required this.measuredAt,
  });

  factory GlucoseReadingModel.fromJson(Map<String, dynamic> json) {
    return GlucoseReadingModel(
      id: json['id']?.toString(),
      valueMgdl: (json['value_mgdl'] as num?)?.toDouble() ?? 0.0,
      readingType: json['reading_type']?.toString() ?? 'random',
      notes: json['notes']?.toString(),
      measuredAt: json['measured_at'] != null 
          ? (() {
              var s = json['measured_at'].toString();
              if (!s.endsWith('Z') && !s.contains('+')) s += 'Z';
              return DateTime.parse(s).toLocal();
            })()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value_mgdl': valueMgdl,
      'reading_type': readingType,
      'notes': notes,
      'measured_at': measuredAt.toIso8601String(),
    };
  }

  // Glucose Category Indicator helper
  String get statusCategory {
    if (valueMgdl < 70) return 'Low';
    if (valueMgdl <= 140) return 'Normal';
    if (valueMgdl <= 180) return 'Elevated';
    return 'High';
  }
}
