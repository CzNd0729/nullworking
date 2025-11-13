import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_api.dart';
import 'auth_service.dart';

class UserApi {
  final BaseApi _baseApi = BaseApi();
  final AuthService _authService = AuthService();

  Future<http.Response> login(String username, String password) async {
    final body = {'userName': username, 'password': password};

    final response = await _baseApi.post(
      'api/auth/login',
      body: body,
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
    String? phone,
    String realName, {
    String? email,
  }) async {
    final body = {
      'userName': username,
      'password': password,
      'phone': phone,
      'realName': realName,
    };

    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    final response = await _baseApi.post(
      'api/auth/register',
      body: body,
      authenticated: false,
    );
    return response;
  }

  Future<http.Response> getHealth() async {
    return await _baseApi.get('api/health');
  }

  Future<http.Response> getCurrentUserInfo(String userId) async {
    return await _baseApi.get('api/users/profile/$userId');
  }

  Future<http.Response> getSubordinateUsers() async {
    return await _baseApi.get('api/users/subordinateUsers');
  }

  Future<http.Response> updateUserProfile(Map<String, String> data) async {
    return await _baseApi.put('api/users/profile', body: data);
  }

  Future<http.Response> updatePushToken(String pushToken) async {
    final body = {'pushToken': pushToken};
    return await _baseApi.put('api/users/push-token', body: body);
  }

  Future<http.Response> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final body = {'oldPassword': oldPassword, 'newPassword': newPassword};
    return await _baseApi.put('api/users/change-password', body: body);
  }
}
