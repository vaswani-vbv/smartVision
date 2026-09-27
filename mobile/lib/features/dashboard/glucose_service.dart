import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/models/glucose_reading_model.dart';

class GlucoseStatsModel {
  final int periodDays;
  final int totalReadings;
  final double averageMgdl;
  final double highestMgdl;
  final double lowestMgdl;
  final int inRange;
  final int aboveRange;
  final int belowRange;
  final double inRangePct;

  GlucoseStatsModel({
    required this.periodDays,
    required this.totalReadings,
    required this.averageMgdl,
    required this.highestMgdl,
    required this.lowestMgdl,
    required this.inRange,
    required this.aboveRange,
    required this.belowRange,
    required this.inRangePct,
  });

  factory GlucoseStatsModel.fromJson(Map<String, dynamic> json) {
    return GlucoseStatsModel(
      periodDays: (json['period_days'] as num?)?.toInt() ?? 30,
      totalReadings: (json['total_readings'] as num?)?.toInt() ?? 0,
      averageMgdl: (json['average_mgdl'] as num?)?.toDouble() ?? 0.0,
      highestMgdl: (json['highest_mgdl'] as num?)?.toDouble() ?? 0.0,
      lowestMgdl: (json['lowest_mgdl'] as num?)?.toDouble() ?? 0.0,
      inRange: (json['in_range'] as num?)?.toInt() ?? 0,
      aboveRange: (json['above_range'] as num?)?.toInt() ?? 0,
      belowRange: (json['below_range'] as num?)?.toInt() ?? 0,
      inRangePct: (json['in_range_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GlucoseService {
  /// Fetch glucose readings history for N days
  static Future<List<GlucoseReadingModel>> getHistory({int days = 30}) async {
    final response = await ApiClient.get('${ApiConstants.glucoseReadings}/history?days=$days');
    if (response != null && response['readings'] != null) {
      final list = response['readings'] as List;
      return list.map((item) => GlucoseReadingModel.fromJson(item)).toList();
    }
    return [];
  }

  /// Fetch statistics (Average, Highest, Lowest, Time-In-Range %)
  static Future<GlucoseStatsModel?> getStats({int days = 30}) async {
    try {
      final response = await ApiClient.get('${ApiConstants.glucoseReadings}/stats?days=$days');
      if (response != null && response.containsKey('total_readings')) {
        return GlucoseStatsModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  /// Log a new blood glucose reading
  static Future<GlucoseReadingModel> logReading({
    required double valueMgdl,
    required String readingType,
    String? notes,
    DateTime? measuredAt,
  }) async {
    final response = await ApiClient.post('${ApiConstants.glucoseReadings}/log', {
      'value_mgdl': valueMgdl,
      'reading_type': readingType,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (measuredAt != null) 'measured_at': measuredAt.toIso8601String(),
    });
    return GlucoseReadingModel(
      id: response['reading_id']?.toString(),
      valueMgdl: valueMgdl,
      readingType: readingType,
      notes: notes,
      measuredAt: measuredAt ?? DateTime.now(),
    );
  }

  /// Delete a glucose reading
  static Future<void> deleteReading(String id) async {
    await ApiClient.delete('${ApiConstants.glucoseReadings}/reading/$id');
  }
}
