import 'dart:convert';

import 'package:nullworking/services/api/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MindMapBusiness {
  final UserApi _userApi = UserApi();

  /// 原有方法：获取导图页面用于展示的四个文本块（保留原样但更健壮）
  Future<Map<String, String>> fetchMindMapData() async {
    try {
      final response = await _userApi.getHealth();

      if (response.statusCode == 200) {
        return {
          'companyImportant': "公司重要事项数据",
          'companyTask': "公司任务调度数据",
          'personalImportant': "个人重要事项数据",
          'personalLog': "个人日志数据",
        };
      } else {
        return {
          'companyImportant': '请求失败: ${response.statusCode}',
          'companyTask': '请求失败: ${response.statusCode}',
          'personalImportant': '请求失败: ${response.statusCode}',
          'personalLog': '请求失败: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'companyImportant': '发生错误: $e',
        'companyTask': '发生错误: $e',
        'personalImportant': '发生错误: $e',
        'personalLog': '发生错误: $e',
      };
    }
  }

  /// 获取公司十大重要事项（mock 实现，后续可改为接口请求）
  /// 返回每项为 { 'title': ..., 'content': ... }
  Future<List<Map<String, String>>> fetchCompanyTop10() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List<Map<String, String>>.generate(10, (i) {
      return {
        'title': '公司重要事项 #${i + 1}',
        'content': '这是公司重要事项 #${i + 1} 的详细描述。',
      };
    });
  }

  /// 获取个人十大重要事项（优先从本地缓存读取）
  Future<List<Map<String, String>>> fetchPersonalTop10() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('personal_top10');
    if (saved != null && saved.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(saved);
        return decoded.map<Map<String, String>>((e) {
          if (e is Map) {
            return Map<String, String>.from(
              e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
            );
          }
          return {'title': e.toString(), 'content': ''};
        }).toList();
      } catch (_) {
        // fallthrough to return default
      }
    }

    // 默认数据
    await Future.delayed(const Duration(milliseconds: 200));
    return List<Map<String, String>>.generate(10, (i) {
      return {'title': '', 'content': ''};
    });
  }

  /// 保存个人十大事项顺序到本地
  Future<void> savePersonalTop10(List<Map<String, String>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personal_top10', json.encode(items));
  }
}
