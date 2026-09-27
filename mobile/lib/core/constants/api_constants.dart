import 'package:flutter/foundation.dart';

class ApiConstants {
  // Safe Platform Detection across Web, Android, iOS, and Desktop
  static String get baseUrl {
    // Check if custom API URL was passed at runtime via --dart-define
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.4.2.88:8000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  // System Health
  static const String health = '/health';

  // Authentication Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // User Info Endpoints
  static const String me = '/users/me';

  // User & Profile Endpoints
  static const String profile = '/users/profile';
  static const String uploadAvatar = '/users/upload-avatar';
  static const String govtId = '/users/govt-id';

  // Helper to format full image URL from relative backend path
  static String getFullImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    // Remove '/api' from baseUrl for root assets like /uploads/
    final baseRoot = baseUrl.replaceAll('/api', '');
    return '$baseRoot$relativePath';
  }

  // Glucose Log Endpoints
  static const String glucoseReadings = '/glucose';

  // AI & Computer Vision Endpoints
  static const String detectFood = '/camera/detect';
  static const String predictSpike = '/predictions/predict';
  static const String predictionsHistory = '/predictions/history';

  // Smart Meal Planner Endpoints
  static const String recommendMeals = '/meal-planner/recommend';
  static const String quickMealPlanner = '/meal-planner/quick';
}

