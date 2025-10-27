import 'dart:convert';

import 'package:nullworking/services/api/user_api.dart';
import 'package:nullworking/services/api/item_api.dart';
import 'package:nullworking/services/business/log_business.dart';
import 'package:nullworking/services/business/task_business.dart';
import 'package:nullworking/models/log.dart';
import 'package:nullworking/models/task.dart';
import 'package:nullworking/models/item.dart';

class MindMapBusiness {
  final LogBusiness _logBusiness = LogBusiness();
  final TaskBusiness _taskBusiness = TaskBusiness();
  final ItemApi _itemApi = ItemApi();

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

  /// 返回每项为 { 'title': ..., 'content': ... }
  Future<List<Item>> fetchCompanyTop10() async {
    final response = await _itemApi.getItems(isCompany: "1");
    if (response != null && response.items.isNotEmpty) {
      return response.items;
    }
    return [];
  }

  /// 获取个人十大重要事项（优先从本地缓存读取）
  Future<List<Item>> fetchPersonalTop10() async {
    final response = await _itemApi.getItems(isCompany: "0");
    if (response != null && response.items.isNotEmpty) {
      return response.items;
    }
    return [];
  }
}