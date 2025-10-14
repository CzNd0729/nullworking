import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_api.dart';
import 'auth_service.dart';

class UserApi {
  final BaseApi _baseApi = BaseApi();
  final AuthService _authService = AuthService();

  Future<http.Response> login(String username, String password) async {
    // 尝试不同的参数名组合
    final queryParams = {
      'username': username,
      'password': password,
      'userName': username,
      'passWord': password,
    };

    print('尝试登录，用户名: $username');
    print('请求URL: http://58.87.76.10:8080/api/auth/login');
    print('请求参数: $queryParams');

    final response = await _baseApi.get(
      'api/auth/login',
      queryParams: queryParams,
      authenticated: false,
    );

    print('响应状态码: ${response.statusCode}');
    print('响应内容: ${response.body}');
    print('响应头: ${response.headers}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final token = body['data']?['token'] ?? body['token'];
      if (token != null) {
        await _authService.saveToken(token);
      }
    }
    return response;
  }

  Future<http.Response> register(
    String username,
    String password,
    String phone,
    String realName, {
    String? email,
  }) async {
    final queryParams = {
      'userName': username,
      'password': password,
      'phone': phone,
      'realName': realName,
    };

    if (email != null && email.isNotEmpty) {
      queryParams['email'] = email;
    }

    print('尝试注册，用户名: $username');
    print('请求URL: http://58.87.76.10:8080/api/auth/register');
    print('请求参数: $queryParams');

    final response = await _baseApi.get(
      'api/auth/register',
      queryParams: queryParams,
      authenticated: false,
    );

    print('注册响应状态码: ${response.statusCode}');
    print('注册响应内容: ${response.body}');

    return response;
  }

  Future<http.Response> getHealth() async {
    return await _baseApi.get('api/health');
  }
}
