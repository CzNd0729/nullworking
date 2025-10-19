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

    // 处理 executorIDs 列表
    body['executorIDs'] = (taskData['executorIDs'] as List<dynamic>).map((id) => id.toString()).toList();

    return await _baseApi.post(
      'api/tasks',
      body: body,
    );
  }

  Future<TaskListResponse?> listUserTasks() async {
    final response = await _baseApi.get('api/tasks');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['code'] == 200 && body['data'] != null) {
        return TaskListResponse.fromJson(body['data']);
      }
    }
    return null;
  }

  Future<http.Response> updateTask(Map<String, dynamic> taskData) async {
    final taskID = taskData['taskID'].toString();
    final body = <String, dynamic>{
      'title': taskData['title'].toString(),
      'content': taskData['content'].toString(),
      'priority': taskData['priority'].toString(),
      'deadline': taskData['deadline'].toString(),
    };

    // 处理 executorIDs 列表
    body['executorIDs'] = (taskData['executorIDs'] as List<dynamic>).map((id) => id.toString()).toList();

    return await _baseApi.put(
      'api/tasks/$taskID',
      body: body,
    );
  }

  Future<http.Response> deleteTask(String taskID) async {
    return await _baseApi.delete(
      'api/tasks/$taskID',
    );
  }
}
