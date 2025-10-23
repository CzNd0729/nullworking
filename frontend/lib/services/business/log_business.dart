import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nullworking/services/api/task_api.dart';
import '../api/log_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/log.dart';
import '../../models/task.dart';

class LogBusiness {
  final LogApi _logApi = LogApi();
  final TaskApi _taskApi = TaskApi();
  final ImagePicker _imagePicker = ImagePicker();

  /// 选择图片（仅前端功能，不上传）
  Future<List<File>> pickImages() async {
    try {
      final List<XFile>? selectedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        return selectedFiles.map((xfile) => File(xfile.path)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('选择图片异常: $e');
      return [];
    }
  }

  /// 根据任务ID获取日志列表
  Future<List<Log>> getLogsByTaskId(String taskId) async {
    try {
      final http.Response res = await _taskApi.getTaskById(taskId);
      if (res.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(res.body);
        if (resp['code'] == 200) {
          List<Log> logs = [];
          if (resp['data']['logs'] is List) {
            for (var item in resp['data']['logs']) {
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

  /// 获取特定条件下的任务列表
  Future<List<Task>> getExecutorTasksForLogSelection() async {
    try {
      final tasksResponse = await _taskApi.listExecutorTasks();
      if (tasksResponse != null) {
        List<Task> tasks = [];
        if (tasksResponse.createdTasks != null) {
          tasks.addAll(tasksResponse.createdTasks!);
        }
        if (tasksResponse.participatedTasks != null) {
          tasks.addAll(tasksResponse.participatedTasks!);
        }
        return tasks;
      } else {
        debugPrint('获取任务列表失败: tasksResponse is null');
        return <Task>[];
      }
    } catch (e) {
      debugPrint('获取任务列表异常: $e');
      return <Task>[];
    }
  }

  /// 获取日志详情
  Future<Log?> fetchLogDetails(String logId) async {
    try {
      final http.Response res = await _logApi.getLogDetails(logId);
      if (res.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(res.body);
        if (resp['code'] == 200 && resp['data'] != null) {
          return Log.fromJson(resp['data']);
        } else {
          debugPrint('获取日志详情失败: ${resp['message']}');
          return null;
        }
      } else {
        debugPrint('获取日志详情网络错误: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('获取日志详情异常: $e');
      return null;
    }
  }

  /// 获取日志文件详情列表
  Future<List<Map<String, dynamic>>> fetchLogFiles(List<int> fileIds) async {
    List<Map<String, dynamic>> files = [];
    for (int fileId in fileIds) {
      try {
        final http.Response res = await _logApi.getLogFile(fileId);
        if (res.statusCode == 200) {
          final Map<String, dynamic> resp = jsonDecode(res.body);
          if (resp['code'] == 200 && resp['data'] != null) {
            files.add(resp['data']); // 假设data就是文件详情Map
          } else {
            debugPrint('获取文件详情失败: ${resp['message']}');
          }
        } else {
          debugPrint('获取文件详情网络错误: ${res.statusCode}');
        }
      } catch (e) {
        debugPrint('获取文件详情异常: $e');
      }
    }
    return files;
  }
}