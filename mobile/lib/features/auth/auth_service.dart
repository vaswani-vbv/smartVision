import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';

class AuthService {
  /// Register a new user. Returns JWT token on success.
  static Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(ApiConstants.register, {
      'name': name,
      'email': email,
      'password': password,
    });
    final token = response['token'] as String;
    await TokenStorageService.saveToken(token);
    return token;
  }

  /// Login an existing user. Returns JWT token on success.
  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });
    final token = response['token'] as String;
    await TokenStorageService.saveToken(token);
    return token;
  }

  /// Logout the current user by clearing the stored token.
  static Future<void> logout() async {
    await TokenStorageService.deleteToken();
  }

  /// Check if the user already has a medical profile set up.
  static Future<bool> hasMedicalProfile() async {
    try {
      final response = await ApiClient.get(ApiConstants.profile);
      if (response is Map && response['message'] == 'No profile found') {
        return false;
      }
      return response != null && response['diabetes_type'] != null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await TokenStorageService.deleteToken();
        return false;
      }
      rethrow;
    } catch (_) {
      rethrow;
    }
  }
}
