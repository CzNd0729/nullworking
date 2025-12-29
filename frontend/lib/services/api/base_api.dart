import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class BaseApi {
  static const String _baseUrl = 'https://58.87.76.10';
  final AuthService _authService = AuthService(); // Use the singleton instance

  Future<Map<String, String>> _getHeaders({bool authenticated = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Flutter App',
      'Cache-Control': 'no-cache',
    };
    if (authenticated) {
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool authenticated = true,
  }) async {
    var uri = Uri.parse('$_baseUrl/$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final headers = await _getHeaders(authenticated: authenticated);
    final response = await http.get(uri, headers: headers);
    return response;
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
  }) async {
    var url = Uri.parse('$_baseUrl/$endpoint');
    if (queryParams != null) {
      url = url.replace(queryParameters: queryParams);
    }
    final headers = await _getHeaders(authenticated: authenticated);
    final response = await http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return response;
  }

  Future<http.Response> postFile(
    String endpoint,
    List<int> fileBytes,
    String filename, {
    bool authenticated = true,
  }) async {
    var uri = Uri.parse('$_baseUrl/$endpoint');
    final headers = await _getHeaders(authenticated: authenticated);

    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file', // 后端接收文件的字段名，可能需要根据实际API调整
          fileBytes,
          filename: filename,
        ),
      );

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
  }) async {
    var url = Uri.parse('$_baseUrl/$endpoint');
    if (queryParams != null) {
      url = url.replace(queryParameters: queryParams);
    }
    final headers = await _getHeaders(authenticated: authenticated);
    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
  }) async {
    var url = Uri.parse('$_baseUrl/$endpoint');
    if (queryParams != null) {
      url = url.replace(queryParameters: queryParams);
    }
    final headers = await _getHeaders(authenticated: authenticated);
    return await http.patch(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? queryParams,
    bool authenticated = true,
  }) async {
    var uri = Uri.parse('$_baseUrl/$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final headers = await _getHeaders(authenticated: authenticated);
    return await http.delete(uri, headers: headers);
  }
}
