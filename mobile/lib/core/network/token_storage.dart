import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const _storage = FlutterSecureStorage();
  static const String _keyToken = 'jwt_auth_token';

  // Save Token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  // Get Token
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Delete Token (Logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // Check if Logged In
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
