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
      final realName = prefs.getString('realName');
      final phoneNumber = prefs.getString('phoneNumber');
      final email = prefs.getString('email');
      final deptId = prefs.getString('deptId');
      final deptName = prefs.getString('deptName');
      final roleId = prefs.getString('roleId');
      final roleName = prefs.getString('roleName');
      
      if (userId != null && userName != null) {
        return User(
          userId: int.tryParse(userId),
          userName: userName,
          realName: realName,
          phoneNumber: phoneNumber,
          email: email,
          deptId: int.tryParse(deptId ?? ''),
          deptName: deptName,
          roleId: int.tryParse(roleId ?? ''),
          roleName: roleName,
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
        final realName = prefs.getString('realName');
        final phoneNumber = prefs.getString('phoneNumber');
        final email = prefs.getString('email');
        final deptId = prefs.getString('deptId');
        final deptName = prefs.getString('deptName');
        final roleId = prefs.getString('roleId');
        final roleName = prefs.getString('roleName');
        
        if (userId != null && userName != null) {
          return User(
            userId: int.tryParse(userId),
            userName: userName,
            realName: realName,
            phoneNumber: phoneNumber,
            email: email,
            deptId: int.tryParse(deptId ?? ''),
            deptName: deptName,
            roleId: int.tryParse(roleId ?? ''),
            roleName: roleName,
          );
        }
      } catch (e) {
        print('从本地获取用户信息也失败: $e');
      }
      
      return null;
    }
  }

  Future<void> saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.userId != null) {
      await prefs.setString('userId', user.userId.toString());
    }
    if (user.userName != null) {
      await prefs.setString('userName', user.userName!);
    }
    if (user.realName != null) {
      await prefs.setString('realName', user.realName!);
    }
    if (user.phoneNumber != null) {
      await prefs.setString('phoneNumber', user.phoneNumber!); // Note: Changed from phone to phoneNumber
    }
    if (user.email != null) {
      await prefs.setString('email', user.email!);
    }
    if (user.deptId != null) {
      await prefs.setString('deptId', user.deptId.toString());
    }
    if (user.deptName != null) {
      await prefs.setString('deptName', user.deptName!);
    }
    if (user.roleId != null) {
      await prefs.setString('roleId', user.roleId.toString());
    }
    if (user.roleName != null) {
      await prefs.setString('roleName', user.roleName!);
    }
  }

  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('realName');
    await prefs.remove('phoneNumber');
    await prefs.remove('email');
    await prefs.remove('deptId');
    await prefs.remove('deptName');
    await prefs.remove('roleId');
    await prefs.remove('roleName');
  }

  // 获取同部门下级员工列表
  Future<List<User>> getSubordinateUsers() async {
    try {
      final response = await _userApi.getSubordinateUsers();
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['code'] == 200) {
          final List<dynamic> usersData = responseData['data']['users'] ?? [];
          return usersData.map((json) => User.fromJson(json)).toList();
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
