import 'package:http/http.dart' as http;
import 'base_api.dart';

class LogApi {
  final BaseApi _baseApi = BaseApi();

  // 已有：创建日志
  Future<http.Response> createLog(Map<String, dynamic> body) async {
    return await _baseApi.post('api/logs', body: body);
  }

  // 新增：根据任务ID获取日志列表（解决LogApi缺少方法的错误）
  Future<http.Response> getLogsByTaskId(String taskId) async {
    // 调用BaseApi的get方法，传递带taskId参数的URL
    return await _baseApi.get('api/logs/$taskId');
  }

  // 新增：获取日志列表
  Future<http.Response> listLogs({String? startTime, String? endTime}) async {
    Map<String, String> queryParams = {};
    String timeRange = '';
    if (startTime != null) {
      timeRange += startTime;
    }
    timeRange += '~';
    if (endTime != null) {
      timeRange += endTime;
    }

    if (timeRange != '~') {
      queryParams['startTime-endTime'] = timeRange;
    }
    return await _baseApi.get('api/logs', queryParams: queryParams);
  }

  // 新增：删除日志
  Future<http.Response> deleteLog(String logId) async {
    return await _baseApi.delete('api/logs/$logId');
  }

  // 新增：更新日志
  Future<http.Response> updateLog(String logId, Map<String, dynamic> body) async {
    return await _baseApi.put('api/logs/$logId', body: body);
  }
}