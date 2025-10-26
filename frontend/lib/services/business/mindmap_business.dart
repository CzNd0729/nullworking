import 'dart:convert';

import 'package:nullworking/services/api/user_api.dart';
import 'package:nullworking/services/business/log_business.dart';
import 'package:nullworking/services/business/task_business.dart';
import 'package:nullworking/models/log.dart';
import 'package:nullworking/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MindMapBusiness {
  final LogBusiness _logBusiness = LogBusiness();
  final TaskBusiness _taskBusiness = TaskBusiness();

  // 新增：获取当天数据（日志+未完成任务）
  Future<Map<String, dynamic>> fetchTodayData() async {
    try {
      // 并行请求当天日志和任务
      final logsFuture = _logBusiness.getTodayLogs(); // 调用日志业务层的当天日志方法
      final tasksFuture = _taskBusiness.getTodayUnfinishedTasks(); // 调用任务业务层的当天任务方法

      final List<Log> todayLogs = await logsFuture;
      final List<Task> todayTasks = await tasksFuture;

      return {
        'todayLogs': todayLogs,
        'todayTasks': todayTasks,
        'companyImportant': '公司重要事项数据（示例）', // 保留原有其他卡片的模拟数据
        'personalImportant': '个人重要事项数据（示例）',
      };
    } catch (e) {
      return {
        'error': '加载失败：$e',
      };
    }
  }

  /// 原有方法：获取导图页面用于展示的四个文本块（保留原样但更健壮）
  Future<Map<String, String>> fetchMindMapData() async {
    try {
      // 并行请求当天日志和任务
      final logsFuture = _logBusiness.getTodayLogs();
      final tasksFuture = _taskBusiness.getTodayUnfinishedTasks();

      final List<Log> todayLogs = await logsFuture;
      final List<Task> todayTasks = await tasksFuture;

      return {
        'companyImportant': '公司重要事项数据（示例）',
        'personalImportant': '个人重要事项数据（示例）',
      };
    } catch (e) {
      return {
        'companyImportant': '加载失败',
        'personalImportant': '加载失败',
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