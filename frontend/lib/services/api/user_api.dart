import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_api.dart';
import 'auth_service.dart';

class UserApi {
  final BaseApi _baseApi = BaseApi();
  final AuthService _authService = AuthService();

  Future<http.Response> login(String username, String password) async {
    final queryParams = {
      'userName': username,
      'password': password,
    };

    final response = await _baseApi.get(
      'api/auth/login',
      queryParams: queryParams,
      authenticated: false,
    );

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

    final response = await _baseApi.get(
      'api/auth/register',
      queryParams: queryParams,
      authenticated: false,
    );
    return response;
  }

  Future<http.Response> getHealth() async {
    return await _baseApi.get('api/health');
  }

  Future<http.Response> getSubDeptUser() async {
    return await _baseApi.get('api/user/getSubDeptUser');
  }
}
