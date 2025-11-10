import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nullworking/services/api/task_api.dart';
import '../api/log_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/log.dart';
import '../../models/task.dart';
import 'dart:typed_data'; // 导入 Uint8List

class LogBusiness {
  final LogApi _logApi = LogApi();
  final TaskApi _taskApi = TaskApi();
  final ImagePicker _imagePicker = ImagePicker();

  /// 上传多个文件并返回它们的 fileId
  Future<List<int>> uploadLogFiles(List<File> files) async {
    List<int> fileIds = [];
    for (File file in files) {
      try {
        Uint8List fileBytes = await file.readAsBytes();
        String filename = file.path.split('/').last;
        final http.Response res = await _logApi.uploadLogFile(fileBytes.toList(), filename);
        if (res.statusCode == 200) {
          final Map<String, dynamic> resp = jsonDecode(res.body);
          if (resp['code'] == 200 && resp['data'] != null) {
            fileIds.add(resp['data'] as int); // 假设data就是fileId
          }
        } else {
          debugPrint('上传文件网络错误: ${res.statusCode}');
        }
      } catch (e) {
        debugPrint('上传文件异常: $e');
      }
    }
    return fileIds;
  }

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

  /// 新增：获取日志列表（补充兼容解析逻辑）
Future<List<Log>> listLogs({String? startTime, String? endTime}) async {
  try {
    final http.Response res = await _logApi.listLogs(startTime: startTime, endTime: endTime);
    if (res.statusCode == 200) {
      final Map<String, dynamic> resp = jsonDecode(res.body);
      if (resp['code'] == 200) {
        List<Log> logs = [];
        // 兼容两种格式：resp['data']['logs']（日志页面格式）和 resp['data']（可能的导图接口格式）
        List<dynamic> logList = [];
        if (resp['data'] is Map && resp['data']['logs'] is List) {
          logList = resp['data']['logs'];
        } else if (resp['data'] is List) {
          logList = resp['data'];
        }
        // 解析日志（和日志页面一致）
        for (var item in logList) {
          logs.add(Log.fromJson(item));
        }
        return logs;
      } else {
        debugPrint('获取日志列表失败: ${resp['message']}');
        return <Log>[];
      }
    } else {
      debugPrint('获取日志列表网络错误: ${res.statusCode}，响应：${res.body}');
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
      // 添加fileIds到body
      if (log.fileIds?.isNotEmpty == true) {
        body['fileIds'] = log.fileIds;
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

  /// 获取当天所有日志（复用日志页面的成功逻辑）
Future<List<Log>> getTodayLogs() async {
  try {
    final now = DateTime.now();
    final startStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final endStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 打印参数，确认和日志页面的请求参数一致
    final logs = await listLogs(startTime: startStr, endTime: endStr);
    return logs;
  } catch (e) {
    debugPrint('导图-获取当天日志异常: $e');
    return <Log>[];
  }
}

  /// 获取特定条件下的任务列表
  Future<List<Task>> getExecutorTasksForLogSelection() async {
    try {
      final tasksResponse = await _taskApi.listTasks(participantType: 'executor');
      if (tasksResponse != null) {
        List<Task> tasks = [];
        tasks.addAll(tasksResponse.createdTasks);
        tasks.addAll(tasksResponse.participatedTasks);
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
          String? filename;
          String? contentDisposition = res.headers['content-disposition'];
          if (contentDisposition != null) {
            final filenameRegex = RegExp(r'filename="([^"]+)"');
            final match = filenameRegex.firstMatch(contentDisposition);
            if (match != null && match.groupCount > 0) {
              filename = match.group(1);
            }
          }

          if (filename != null) {
            files.add({'fileId': fileId, 'fileName': filename, 'fileBytes': res.bodyBytes});
          } else {
            debugPrint('获取文件详情失败: 无法从Content-Disposition头中提取文件名');
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