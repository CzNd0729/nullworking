import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_api.dart';
import 'package:nullworking/models/task.dart';

class TaskApi {
  final BaseApi _baseApi = BaseApi();

  Future<http.Response> publishTask(Map<String, dynamic> taskData) async {
    final queryParams = <String, dynamic>{
      'title': taskData['title'].toString(),
      'content': taskData['content'].toString(),
      'priority': taskData['priority'].toString(),
      'deadline': taskData['deadline'].toString(),
    };

    // 处理 executorIDs 列表
    queryParams['executorIDs'] = (taskData['executorIDs'] as List<dynamic>).map((id) => id.toString()).toList();

    return await _baseApi.post(
      'api/task/publishTask',
      queryParams: queryParams,
    );
  }

  Future<TaskListResponse?> listUserTasks() async {
    final response = await _baseApi.get('api/task/listUserTasks');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['code'] == 200 && body['data'] != null) {
        return TaskListResponse.fromJson(body['data']);
      }
    }
    return null;
  }

  Future<http.Response> updateTask(Map<String, dynamic> taskData) async {
    final queryParams = <String, dynamic>{
      'taskID': taskData['taskID'].toString(),
      'title': taskData['title'].toString(),
      'content': taskData['content'].toString(),
      'priority': taskData['priority'].toString(),
      'deadline': taskData['deadline'].toString(),
    };

    // 处理 executorIDs 列表
    queryParams['executorIDs'] = (taskData['executorIDs'] as List<dynamic>).map((id) => id.toString()).toList();

    return await _baseApi.put(
      'api/task/updateTask',
      queryParams: queryParams,
    );
  }

  Future<http.Response> deleteTask(String taskID) async {
    final queryParams = {'taskID': taskID};
    return await _baseApi.delete(
      'api/task/deleteTask',
      queryParams: queryParams,
    );
  }
}
