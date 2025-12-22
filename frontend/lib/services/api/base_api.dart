import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/navigator_key.dart';

class BaseApi {
  static const String _baseUrl = 'http://58.87.76.10:8082';
  final AuthService _authService = AuthService(); // Use the singleton instance

  Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // 如果是登录接口本身的 401/403，不应该强制登出（因为用户正在尝试登录）
      // 这里简单判断一下，如果请求的是 login 接口，就不拦截
      // 但是 BaseApi 不知道当前请求的 endpoint，除非传进来
      // 不过通常 login 接口调用时 authenticated=false，或者我们可以在调用处处理
      // 更好的方式是检查 response body 或者只针对 authenticated=true 的请求处理

      // 简单处理：如果已经有 token (authenticated=true 调用的)，且返回 401/403，则登出
      // 但是 _handleResponse 无法知道 authenticated 参数

      // 让我们假设所有经过 BaseApi 的请求，如果返回 401/403 且不是登录接口，都应该登出
      // 登录接口通常是 /api/auth/login

      if (response.request != null &&
          !response.request!.url.path.contains('/login')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

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
    await _handleResponse(response);
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
    await _handleResponse(response);
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
    final response = await http.Response.fromStream(streamedResponse);
    await _handleResponse(response);
    return response;
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
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    await _handleResponse(response);
    return response;
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
    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    await _handleResponse(response);
    return response;
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
    final response = await http.delete(uri, headers: headers);
    await _handleResponse(response);
    return response;
  }
}
