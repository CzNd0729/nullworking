import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://58.87.76.10:8080'; //服务端ip
  static const String _tokenKey = 'jwt_token';

  // 登录接口
  Future<http.Response> login(String username, String password) async {
    final url = Uri.parse(
      '$_baseUrl/api/auth/login?userName=$username&passWord=$password',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['token'] != null) {
        await _saveToken(body['token']);
      }
    }
    return response;
  }

  // 注册接口
  Future<http.Response> register(String username, String password, String phone, {String? email}) async {
    final queryParams = {
      'userName': username,
      'password': password,
      'phone': phone,
    };
    
    if (email != null && email.isNotEmpty) {
      queryParams['email'] = email;
    }

    final uri = Uri.parse('$_baseUrl/api/register').replace(
      queryParameters: queryParams,
    );

    return await http.get(uri);
  }

  // 验证token接口
  Future<http.Response> validateToken(String token) async {
    final url = Uri.parse('$_baseUrl/api/auth/validate');
    final headers = {'Authorization': 'Bearer $token'};
    return await http.get(url, headers: headers);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
