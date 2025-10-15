import 'package:http/http.dart' as http;
import 'base_api.dart';

class TaskApi {
  final BaseApi _baseApi = BaseApi();

  // 发布任务
  Future<http.Response> publishTask(Map<String, dynamic> taskData) async {
    // 根据API文档：POST请求，参数通过query string传递
    final queryParams = <String, String>{
      'title': taskData['title'].toString(),
      'content': taskData['content'].toString(),
      'priority': taskData['priority'].toString(),
      'executorIDs': taskData['executorIDs'].toString(), // 单个整数，不是数组
      'deadline': taskData['deadline'].toString(),
    };

    print('使用POST请求，参数通过query string传递');
    return await _baseApi.post(
      'api/task/publishTask',
      queryParams: queryParams,
    );
  }

  // 查看任务
  Future<http.Response> listUserTasks() async {
    return await _baseApi.get('api/task/ListUserTasks');
  }

  // 更新任务
  Future<http.Response> updateTask(Map<String, dynamic> taskData) async {
    return await _baseApi.put('api/task/updateTask', body: taskData);
  }

  // 删除任务 (软删除)
  Future<http.Response> deleteTask(String taskId) async {
    final queryParams = {'taskId': taskId};
    return await _baseApi.delete(
      'api/task/deleteTask',
      queryParams: queryParams,
    );
  }
}
