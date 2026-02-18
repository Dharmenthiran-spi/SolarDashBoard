import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Config/api_config.dart';
import 'auth_service.dart';

class HttpHelper {
  static Future<Map<String, String>> _getHeaders() async {
    final headers = Map<String, String>.from(ApiConfig.headers);
    final token = await AuthService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> post(String path, dynamic data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      final headers = await _getHeaders();
      final response = await http.post(
        uri, 
        headers: headers, 
        body: data != null ? jsonEncode(data) : null
      ).timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> put(String path, dynamic data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      final headers = await _getHeaders();
      final response = await http.put(
        uri, 
        headers: headers, 
        body: data != null ? jsonEncode(data) : null
      ).timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> delete(String path, {dynamic body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      final headers = await _getHeaders();
      final request = http.Request('DELETE', uri)
        ..headers.addAll(headers)
        ..body = body != null ? jsonEncode(body) : "";
      
      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 204) {
        return {'success': true, 'data': null, 'statusCode': 204};
      }
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return {
          'success': true,
          'data': data,
          'statusCode': response.statusCode,
        };
      } catch (e) {
        return {
          'success': true,
          'data': response.body,
          'statusCode': response.statusCode,
        };
      }
    } else {
      String errorMessage = 'Error ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['detail'] ?? errorMessage;
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      return {
        'success': false,
        'error': errorMessage,
        'statusCode': response.statusCode,
      };
    }
  }

  static Map<String, dynamic> _handleError(dynamic error) {
    return {
      'success': false,
      'error': error.toString(),
    };
  }
}
