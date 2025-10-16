import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_api.dart';
import 'package:nullworking/models/task.dart';

class TaskApi {
  final BaseApi _baseApi = BaseApi();

  Future<http.Response> publishTask(Map<String, dynamic> taskData) async {
    final queryParams = <String, String>{
      'title': taskData['title'].toString(),
      'content': taskData['content'].toString(),
      'priority': taskData['priority'].toString(),
      'executorIDs': taskData['executorIDs'].toString(),
      'deadline': taskData['deadline'].toString(),
    };

    return await _baseApi.post(
      'api/task/publishTask',
      queryParams: queryParams,
    );
  }

  Future<TaskListResponse?> listUserTasks() async {
    final response = await _baseApi.get('api/task/listUserTasks');
    print(response);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['code'] == 200 && body['data'] != null) {
        return TaskListResponse.fromJson(body['data']);
      }
    }
    return null;
  }

  Future<http.Response> updateTask(Map<String, dynamic> taskData) async {
    return await _baseApi.put('api/task/updateTask', body: taskData);
  }

  Future<http.Response> deleteTask(String taskId) async {
    final queryParams = {'taskId': taskId};
    return await _baseApi.delete(
      'api/task/deleteTask',
      queryParams: queryParams,
    );
  }
}
