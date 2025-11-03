import 'package:shared_preferences/shared_preferences.dart';
import 'package:nullworking/services/api/base_api.dart';

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
      final response = await baseApi.get('api/health', authenticated: false); // Health check usually doesn't require auth
      return response.statusCode;
    } catch (e) {
      // Handle network errors or other exceptions
      print('Error checking health: $e');
      return 500; // Internal Server Error or other appropriate status code
    }
  }
}
