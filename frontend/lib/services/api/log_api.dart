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
    return await _baseApi.get('api/logs?taskId=$taskId');
  }
}