import 'package:nullworking/models/user.dart';
import 'package:nullworking/services/api/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserBusiness {
  final UserApi _userApi = UserApi();

  // 获取当前登录用户的信息
  Future<User?> getCurrentUser() async {
    try {
      final response = await _userApi.getCurrentUserInfo();
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['code'] == 200) {
          final userData = responseData['data'];
          if (userData != null) {
            return User.fromJson(userData);
          }
        } else {
          print('获取用户信息失败: ${responseData['message']}');
        }
      } else {
        print('网络请求失败: ${response.statusCode}');
      }
      
      // 如果 API 调用失败，尝试从 SharedPreferences 获取基本信息
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userName = prefs.getString('userName');
      
      if (userId != null && userName != null) {
        return User(
          userId: int.tryParse(userId),
          userName: userName,
        );
      }
      
      return null;
    } catch (e) {
      print('获取当前用户信息失败: $e');
      
      // 出错时尝试从 SharedPreferences 获取基本信息
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        final userName = prefs.getString('userName');
        
        if (userId != null && userName != null) {
          return User(
            userId: int.tryParse(userId),
            userName: userName,
          );
        }
      } catch (e) {
        print('从本地获取用户信息也失败: $e');
      }
      
      return null;
    }
  }  // 获取同部门下级员工列表
  Future<List<User>> getSubDeptUsers() async {
    try {
      final response = await _userApi.getSubDeptUser();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['code'] == 200) {
          final List<dynamic> data = responseData['data'] ?? [];
          return data.map((json) => User.fromJson(json)).toList();
        } else {
          print('获取下级员工失败: ${responseData['message']}');
          return [];
        }
      } else {
        print('网络请求失败: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('获取下级员工异常: $e');
      return [];
    }
  }
}
