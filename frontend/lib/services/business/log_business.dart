import '../api/log_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LogBusiness {
  final LogApi _logApi = LogApi();

  /// body keys: taskId, logTitle, logContent, logStatus, taskProgress, startTime, endTime, logDate, fileIds
  Future<Map<String, dynamic>> createLog(Map<String, dynamic> body) async {
    try {
      final http.Response res = await _logApi.createLog(body);
      if (res.statusCode == 200) {
        final Map<String, dynamic> resp = jsonDecode(res.body);
        if (resp['code'] == 0) {
          return {'success': true, 'data': resp['data'] ?? {}};
        } else {
          return {'success': false, 'message': resp['message'] ?? '创建失败'};
        }
      } else {
        return {'success': false, 'message': '网络错误 ${res.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
