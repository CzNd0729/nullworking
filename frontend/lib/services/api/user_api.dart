import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_api.dart';
import 'auth_service.dart';

class UserApi {
  final BaseApi _baseApi = BaseApi();
  final AuthService _authService = AuthService();

  Future<http.Response> login(String username, String password) async {
    final queryParams = {'userName': username, 'passWord': password};
    
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

  Future<http.Response> register(String username, String password, String phone, {String? email}) async {
    final queryParams = {
      'userName': username,
      'password': password,
      'phone': phone,
    };
    
    if (email != null && email.isNotEmpty) {
      queryParams['email'] = email;
    }

    return await _baseApi.get(
      'api/register',
      queryParams: queryParams,
      authenticated: false,
    );
  }

  Future<http.Response> getHealth() async {
    return await _baseApi.get('api/health');
  }

}
