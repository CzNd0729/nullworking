import 'package:nullworking/services/api/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:nullworking/services/api/auth_service.dart';
import 'package:nullworking/services/business/user_business.dart'; // Import UserBusiness
import 'package:nullworking/services/notification_services/push_notification_service.dart';

class AuthBusiness {
  final UserApi _userApi = UserApi();
  final AuthService _authService = AuthService();
  final UserBusiness _userBusiness = UserBusiness(); // Instantiate UserBusiness
  final PushNotificationService _pushNotificationService =
      PushNotificationService();

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
      print('登录失败: $e');
      return null;
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
    await _pushNotificationService.deleteToken();
    await _authService.logout();
    // Also clear user data from UserBusiness
    await _userBusiness.clearCurrentUser(); // Assuming a clearCurrentUser method in UserBusiness
  }

  Future<String?> getRoleName() async {
    // Role name is now part of the User object in UserBusiness
    final user = await _userBusiness.getCurrentUser();
    return user?.roleName;
  }

  Future<String?> getDeptName() async {
    // Department name is now part of the User object in UserBusiness
    final user = await _userBusiness.getCurrentUser();
    return user?.deptName;
  }
}
