import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/models/prediction_model.dart';

class DetectionResult {
  final String food;
  final double confidence;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final int calories;
  final String servingSize;
  final String? error;

  DetectionResult({
    required this.food,
    required this.confidence,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.calories,
    required this.servingSize,
    this.error,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error') && json['nutrition'] == null) {
      return DetectionResult(
        food: json['food']?.toString() ?? 'Detected Item',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        carbs: 0.0,
        protein: 0.0,
        fat: 0.0,
        fiber: 0.0,
        calories: 0,
        servingSize: '1 serving',
        error: json['error']?.toString(),
      );
    }

    final nut = json['nutrition'] as Map<String, dynamic>? ?? {};
    return DetectionResult(
      food: json['food']?.toString() ?? 'Food Item',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      carbs: (nut['carbs'] as num?)?.toDouble() ?? 0.0,
      protein: (nut['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (nut['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (nut['fiber'] as num?)?.toDouble() ?? 0.0,
      calories: (nut['calories'] as num?)?.toInt() ?? 0,
      servingSize: nut['serving_size']?.toString() ?? '1 serving',
    );
  }
}

class PredictionResponse {
  final String predictionId;
  final double predictedSpike;
  final double predictedPostMeal;
  final double preMealGlucose;
  final String riskLevel;
  final String riskColor;
  final int calories;
  final Map<String, dynamic> inputSummary;
  final List<ShapFeatureImpact> topFactors;

  PredictionResponse({
    required this.predictionId,
    required this.predictedSpike,
    required this.predictedPostMeal,
    required this.preMealGlucose,
    required this.riskLevel,
    required this.riskColor,
    required this.calories,
    required this.inputSummary,
    required this.topFactors,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    List<ShapFeatureImpact> factors = [];
    if (json['explanation'] != null && json['explanation']['top_factors'] != null) {
      final list = json['explanation']['top_factors'] as List;
      factors = list.map((item) => ShapFeatureImpact.fromJson(item)).toList();
    }

    return PredictionResponse(
      predictionId: json['prediction_id']?.toString() ?? '',
      predictedSpike: (json['predicted_spike'] as num?)?.toDouble() ?? 0.0,
      predictedPostMeal: (json['predicted_post_meal'] as num?)?.toDouble() ?? 0.0,
      preMealGlucose: (json['pre_meal_glucose'] as num?)?.toDouble() ?? 100.0,
      riskLevel: json['risk_level']?.toString() ?? 'Normal',
      riskColor: json['risk_color']?.toString() ?? '#10B981',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      inputSummary: json['input_summary'] as Map<String, dynamic>? ?? {},
      topFactors: factors,
    );
  }
}

class ScannerService {
  /// Send meal photo bytes to YOLOv8 object detection
  static Future<DetectionResult> detectFood(List<int> bytes, String filename) async {
    final response = await ApiClient.uploadImageBytes(
      ApiConstants.detectFood,
      bytes,
      filename,
    );
    return DetectionResult.fromJson(response);
  }

  /// Submit nutrition details, pre-meal glucose, insulin dose, & activity to XGBoost model
  static Future<PredictionResponse> predictSpike({
    String? foodName,
    required double carbsG,
    required double proteinG,
    required double fatG,
    required double fiberG,
    required double preMealGlucose,
    double? insulinDose,
    String? postMealActivity,
    int? timeOfDay,
  }) async {
    final payload = <String, dynamic>{
      'food_name': foodName ?? 'Meal',
      'carbs_g': carbsG,
      'protein_g': proteinG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'pre_meal_glucose': preMealGlucose,
      'insulin_dose': insulinDose ?? 0.0,
      'post_meal_activity': postMealActivity ?? 'none',
    };
    if (timeOfDay != null) {
      payload['time_of_day'] = timeOfDay;
    }
    final response = await ApiClient.post(ApiConstants.predictSpike, payload);
    return PredictionResponse.fromJson(response);
  }

  /// Get past logged meals & spike predictions history
  static Future<List<Map<String, dynamic>>> getMealHistory() async {
    final response = await ApiClient.get(ApiConstants.predictionsHistory);
    if (response != null && response['predictions'] != null) {
      return List<Map<String, dynamic>>.from(response['predictions']);
    }
    return [];
  }
}
