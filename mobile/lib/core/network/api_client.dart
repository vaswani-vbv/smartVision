import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient {
  // Helper for Headers
  static Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await TokenStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // GET Request
  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // DELETE Request
  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    
    try {
      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 8));
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // POST Request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // POST Form Data (used for OAuth2 token login endpoints)
  static Future<dynamic> postForm(String endpoint, Map<String, String> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 8));
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  // MULTIPART POST (Upload Image Bytes for YOLO Detection - Web & Native safe)
  static Future<dynamic> uploadImageBytes(String endpoint, List<int> bytes, String filename) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders(isJson: false);
    
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      
      final multipartFile = http.MultipartFile.fromBytes('file', bytes, filename: filename);
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      throw ApiException('File upload error: $e');
    }
  }

  // Upload Avatar Image Bytes
  static Future<dynamic> uploadAvatar(List<int> bytes, String filename) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadAvatar}');
    final headers = await _getHeaders(isJson: false);
    
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      
      final multipartFile = http.MultipartFile.fromBytes('file', bytes, filename: filename);
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Avatar upload error: $e');
    }
  }

  // Submit Govt ID (with optional document image bytes)
  static Future<dynamic> submitGovtId({
    required String idType,
    required String idNumber,
    List<int>? documentBytes,
    String? filename,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.govtId}');
    final headers = await _getHeaders(isJson: false);
    
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      request.fields['id_type'] = idType;
      request.fields['id_number'] = idNumber;

      if (documentBytes != null && documentBytes.isNotEmpty) {
        final name = filename ?? 'govt_id.jpg';
        final ext = name.split('.').last.toLowerCase();
        final mimeType = switch (ext) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'gif' => 'image/gif',
          'bmp' => 'image/bmp',
          _ => 'image/jpeg',
        };
        final multipartFile = http.MultipartFile.fromBytes(
          'document_image',
          documentBytes,
          filename: name,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      throw ApiException('Govt ID submission error: $e');
    }
  }


  // Process HTTP Response
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Request failed with status code ${response.statusCode}';
      try {
        final bodyJson = jsonDecode(response.body);
        if (bodyJson is Map && bodyJson.containsKey('detail')) {
          errorMessage = bodyJson['detail'].toString();
        }
      } catch (_) {}
      
      throw ApiException(errorMessage, response.statusCode);
    }
  }
}
