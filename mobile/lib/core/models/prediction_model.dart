import 'dart:convert';

class ShapFeatureImpact {
  final String feature;
  final double value;
  final String description;

  ShapFeatureImpact({
    required this.feature,
    required this.value,
    required this.description,
  });

  factory ShapFeatureImpact.fromJson(Map<String, dynamic> json) {
    return ShapFeatureImpact(
      feature: json['feature']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
    );
  }
}

class PredictionModel {
  final String? id;
  final double carbsG;
  final double proteinG;
  final double fatG;
  final double preMealGlucose;
  final double predictedSpike;
  final double expectedPeakGlucose;
  final String riskLevel;
  final List<ShapFeatureImpact> shapExplanations;
  final DateTime predictedAt;

  PredictionModel({
    this.id,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    required this.preMealGlucose,
    required this.predictedSpike,
    required this.expectedPeakGlucose,
    required this.riskLevel,
    required this.shapExplanations,
    required this.predictedAt,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    List<ShapFeatureImpact> shapList = [];
    if (json['shap_values'] != null) {
      try {
        dynamic parsed = json['shap_values'];
        if (parsed is String) {
          parsed = jsonDecode(parsed);
        }
        if (parsed is List) {
          shapList = parsed.map((item) => ShapFeatureImpact.fromJson(item)).toList();
        }
      } catch (_) {}
    }

    final spike = (json['predicted_spike'] as num?)?.toDouble() ?? 0.0;
    final preGlucose = (json['pre_meal_glucose'] as num?)?.toDouble() ?? 100.0;
    final peak = (json['expected_peak_glucose'] as num?)?.toDouble() ?? (preGlucose + spike);

    return PredictionModel(
      id: json['id']?.toString(),
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      preMealGlucose: preGlucose,
      predictedSpike: spike,
      expectedPeakGlucose: peak,
      riskLevel: json['risk_level']?.toString() ?? (spike > 50 ? 'High' : spike > 30 ? 'Elevated' : 'Normal'),
      shapExplanations: shapList,
      predictedAt: json['predicted_at'] != null 
          ? DateTime.parse(json['predicted_at'].toString()) 
          : DateTime.now(),
    );
  }
}
