import 'package:shared_preferences/shared_preferences.dart';
import 'package:nullworking/services/api/base_api.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() {
    return _instance;
  }
  AuthService._internal();

  static const String _tokenKey = 'jwt_token';
  // Remove this line to break circular dependency
  // final BaseApi _baseApi = BaseApi();

  Future<void> saveToken(String token) async {
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

  Future<int> checkHealth() async {
    try {
      // Instantiate BaseApi here for the health check
      final BaseApi baseApi = BaseApi();
      final response = await baseApi.get('api/health');
      return response.statusCode;
    } catch (e) {
      // Handle network errors or other exceptions
      print('Error checking health: $e');
      return 500; // Internal Server Error or other appropriate status code
    }
  }

  Future<http.Response> sendEmailCode(String email) async {
    final BaseApi baseApi = BaseApi();
    final body = {'email': email};
    return await baseApi.post('api/auth/send-email-code',
        body: body, authenticated: false);
  }

  Future<http.Response> resetPassword(
      String email, String code, String newPassword) async {
    final BaseApi baseApi = BaseApi();
    final body = {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    };
    return await baseApi.post('api/auth/reset-password',
        body: body, authenticated: false);
  }
}
