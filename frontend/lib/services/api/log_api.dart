import 'package:http/http.dart' as http;
import 'base_api.dart';
import '/models/log.dart';

class LogApi {
  final BaseApi _baseApi = BaseApi();

  // 已有：创建日志
  Future<http.Response> createLog(Log log) async {
    final body = log.toJson();
    // 在创建日志时，后端会自动生成logId，所以这里将其移除
    body.remove('logId');
    // 如果taskId为null，则移除taskId字段
    if (log.taskId == null) {
      body.remove('taskId');
    }
    return await _baseApi.post('api/logs', body: body);
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