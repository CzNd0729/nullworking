import 'package:nullworking/services/api/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthBusiness {
  final UserApi _userApi = UserApi();

  Future<String?> login(String username, String password) async {
    try {
      final response = await _userApi.login(username, password);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['code'] == 200) {
          final int userId = responseData['data']['userId'];
          final String userName = responseData['data']['userName'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', userId.toString());
          await prefs.setString('userName', userName);
          return null;
        } else {
          return responseData['message'] ?? '登录失败';
        }
      } else {
        return '网络请求失败，请稍后重试';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(String username, String password, String realName, {String? phone, String? email}) async {
    try {
      final response = await _userApi.register(username, password, phone, realName, email: email);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['code'] == 200) {
          return null;
        } else {
          return responseData['message'] ?? '注册失败';
        }
      } else {
        return '网络请求失败，请稍后重试';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('token');
  }
}
