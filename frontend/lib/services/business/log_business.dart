import 'package:flutter/foundation.dart'; // 导入debugPrint所需包
import '../api/log_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/log.dart';

class LogBusiness {
  final LogApi _logApi = LogApi();

  /// 根据任务ID获取日志列表
  Future<List<Log>> getLogsByTaskId(String taskId) async {
    try {
      // 调用LogApi新增的getLogsByTaskId方法
      final http.Response res = await _logApi.getLogsByTaskId(taskId);
      if (res.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(res.body);
        if (resp['code'] == 200) {
          List<Log> logs = [];
          if (resp['data'] is List) {
            for (var item in resp['data']) {
              logs.add(Log.fromJson(item));
            }
          }
          return logs;
        } else {
          debugPrint('获取日志失败: ${resp['message']}'); // 已修复debugPrint
          return <Log>[];
        }
      } else {
        debugPrint('获取日志网络错误: ${res.statusCode}'); // 已修复debugPrint
        return <Log>[];
      }
    } catch (e) {
      debugPrint('获取日志异常: $e'); // 已修复debugPrint
      return <Log>[];
    }
  }

  /// 新增：获取日志列表
  Future<List<Log>> listLogs({String? startTime, String? endTime}) async {
    try {
      final http.Response res = await _logApi.listLogs(startTime: startTime, endTime: endTime);
      if (res.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(res.body);
        if (resp['code'] == 200) {
          List<Log> logs = [];
          if (resp['data'] is Map && resp['data']['logs'] is List) {
            for (var item in resp['data']['logs']) {
              logs.add(Log.fromJson(item));
            }
          }
          return logs;
        } else {
          debugPrint('获取日志列表失败: ${resp['message']}');
          return <Log>[];
        }
      } else {
        debugPrint('获取日志列表网络错误: ${res.statusCode}');
        return <Log>[];
      }
    } catch (e) {
      debugPrint('获取日志列表异常: $e');
      return <Log>[];
    }
  }

  /// 新增：删除日志
  Future<Map<String, dynamic>> deleteLog(String logId) async {
    try {
      final http.Response res = await _logApi.deleteLog(logId);
      if (res.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(res.body);
        if (resp['code'] == 200) {
          return {'success': true, 'message': resp['message'] ?? '删除成功'};
        } else {
          return {'success': false, 'message': resp['message'] ?? '删除失败'};
        }
      } else {
        return {'success': false, 'message': '网络错误 ${res.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// 新增：更新日志
  Future<Map<String, dynamic>> updateLog(String logId, Map<String, dynamic> body) async {
    try {
      final http.Response res = await _logApi.updateLog(logId, body);
      if (res.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(res.body);
        if (resp['code'] == 200) {
          return {'success': true, 'message': resp['message'] ?? '更新成功'};
        } else {
          return {'success': false, 'message': resp['message'] ?? '更新失败'};
        }
      } else {
        return {'success': false, 'message': '网络错误 ${res.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// 创建或更新日志
  Future<Map<String, dynamic>> createOrUpdateLog(Log log, {required bool isUpdate}) async {
    try {
      Map<String, dynamic> body = log.toJson();
      // 移除后端不需要的logId字段，只在更新时使用
      if (!isUpdate) {
        body.remove('logId');
      }
      // 如果taskId为null，则移除taskId字段
      if (log.taskId == null) {
        body.remove('taskId');
      }
      http.Response res;
      if (isUpdate) {
        res = await _logApi.updateLog(log.logId, body);
      } else {
        res = await _logApi.createLog(log);
      }
      
      if (res.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(res.body);
        if (resp['code'] == 200) {
          if (isUpdate) {
            return {'success': true, 'message': resp['message'] ?? '更新成功'};
          } else {
            return {'success': true, 'data': resp['data'] ?? {}};
          }
        } else {
          return {'success': false, 'message': resp['message'] ?? (isUpdate ? '更新失败' : '创建失败')};
        }
      }
      else {
        return {'success': false, 'message': '网络错误 ${res.statusCode}'};
      }
    } catch (e) {
      debugPrint('创建或更新日志异常: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}