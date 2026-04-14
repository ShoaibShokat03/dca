import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

/// Thin HTTP client wrapper that handles auth tokens, timeouts,
/// and consistent error shape for all API calls.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final String message;
  final int statusCode;

  ApiResponse({required this.success, this.data, required this.message, required this.statusCode});

  factory ApiResponse.fromJson(Map<String, dynamic> json, int statusCode) {
    return ApiResponse(
      success: json['success'] == true,
      data: json['data'],
      message: (json['message'] as String?) ?? '',
      statusCode: statusCode,
    );
  }
}

class ApiService {
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    if (auth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<ApiResponse> _processResponse(http.Response response) async {
    final statusCode = response.statusCode;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiResponse.fromJson(decoded, statusCode);
      }
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Parse error: ${response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body}',
        statusCode: statusCode,
      );
    }
  }

  static Future<ApiResponse> get(String url, {bool auth = true, Map<String, String>? params}) async {
    try {
      final headers = await _headers(auth: auth);
      Uri uri = Uri.parse(url);
      if (params != null && params.isNotEmpty) {
        uri = uri.replace(queryParameters: {...uri.queryParameters, ...params});
      }
      final res = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);
      return _processResponse(res);
    } on SocketException {
      throw ApiException('No internet connection. Check your network.');
    } on HttpException {
      throw ApiException('Server unreachable.');
    } on FormatException {
      throw ApiException('Bad server response.');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }

  static Future<ApiResponse> post(String url, {bool auth = true, Map<String, dynamic>? body}) async {
    try {
      final headers = await _headers(auth: auth);
      // Send as form-encoded (matches the Yii backend expectations)
      final stringBody = <String, String>{};
      body?.forEach((k, v) {
        if (v != null) stringBody[k] = v.toString();
      });
      final res = await http
          .post(Uri.parse(url), headers: headers, body: stringBody)
          .timeout(ApiConfig.requestTimeout);
      return _processResponse(res);
    } on SocketException {
      throw ApiException('No internet connection. Check your network.');
    } on HttpException {
      throw ApiException('Server unreachable.');
    } on FormatException {
      throw ApiException('Bad server response.');
    } catch (e) {
      throw ApiException('Request failed: $e');
    }
  }
}
