import 'package:http/http.dart' as http;
import 'base_api.dart';

class LogApi {
  final BaseApi _baseApi = BaseApi();

  Future<http.Response> createLog(Map<String, dynamic> body) async {
    return await _baseApi.post('api/logs', body: body);
  }

  // add more methods like listLogs, getLogDetail later if needed
}
