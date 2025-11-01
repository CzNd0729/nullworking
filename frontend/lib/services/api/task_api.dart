import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_api.dart';
import 'package:nullworking/models/task.dart';

class TaskApi {
  final BaseApi _baseApi = BaseApi();

  Future<http.Response> publishTask(Map<String, dynamic> taskData) async {
    final body = <String, dynamic>{
      'title': taskData['title'].toString(),
      'content': taskData['content'].toString(),
      'priority': taskData['priority'].toString(),
      'deadline': taskData['deadline'].toString(),
    };

    // 处理 executorIds 列表
    body['executorIds'] = (taskData['executorIds'] as List<dynamic>).map((id) => id.toString()).toList();

    return await _baseApi.post(
      'api/tasks',
      body: body,
    );
  }

  Future<TaskListResponse?> listTasks({String? taskStatus, String? participantType}) async {
    String queryParams = '';
    if (taskStatus != null) {
      queryParams += 'taskStatus=$taskStatus';
    }
    if (participantType != null) {
      if (queryParams.isNotEmpty) {
        queryParams += '&';
      }
      queryParams += 'participantType=$participantType';
    }

    final response = await _baseApi.get('api/tasks${queryParams.isNotEmpty ? '?' + queryParams : ''}');
    
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['code'] == 200 && body['data'] != null) {
        return TaskListResponse.fromJson(body['data']);
      }
    }
    return null;
  }

  // Future<TaskListResponse?> listUserTasks() async {
  //   final response = await _baseApi.get('api/tasks');

  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body);
  //     if (body['code'] == 200 && body['data'] != null) {
  //       return TaskListResponse.fromJson(body['data']);
  //     }
  //   }
  //   return null;
  // }

  Future<http.Response> updateTask(Map<String, dynamic> taskData) async {
    final taskId = taskData['taskId'].toString();
    final body = <String, dynamic>{
      'title': taskData['title'].toString(),
      'content': taskData['content'].toString(),
      'priority': taskData['priority'].toString(),
      'deadline': taskData['deadline'].toString(),
    };

    // 处理 executorIds 列表
    body['executorIds'] = (taskData['executorIds'] as List<dynamic>).map((id) => id.toString()).toList();

    return await _baseApi.put(
      'api/tasks/$taskId',
      body: body,
    );
  }

  Future<http.Response> deleteTask(String taskId) async {
    return await _baseApi.delete(
      'api/tasks/$taskId',
    );
  }

  // 新增：根据任务ID获取任务详情
  Future<http.Response> getTaskById(String taskId) async {
    return await _baseApi.get('api/tasks/$taskId');
  }

  // Future<TaskListResponse?> listExecutorTasks({String taskStatus = '0', String participantType = 'executor'}) async {
  //   final response = await _baseApi.get('api/tasks?taskStatus=$taskStatus&participantType=$participantType');
    
  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body);
  //     if (body['code'] == 200 && body['data'] != null) {
  //       return TaskListResponse.fromJson(body['data']);
  //     }
  //   }
  //   return null;
  // }
}
