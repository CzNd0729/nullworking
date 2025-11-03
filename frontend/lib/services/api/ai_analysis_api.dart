import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_api.dart';
import 'package:nullworking/models/ai_analysis_result.dart';

class AiAnalysisApi {
  final BaseApi _baseApi = BaseApi();

  Future<http.Response> logAnalysis(int mode, Map<String, dynamic> body) async {
    return await _baseApi.post(
      'api/analysis?mode=$mode',
      body: body,
    );
  }

  Future<AiAnalysisResult?> getResultById(String resultId) async {
    final response = await _baseApi.get('api/analysis/$resultId');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['code'] == 200 && body['data'] != null) {
        return AiAnalysisResult.fromJson(body['data']);
      }
    }
    return null;
  }

  Future<List<AiAnalysisResult>?> getResultList() async {
    final response = await _baseApi.get('api/analysis/list');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['code'] == 200 && body['data'] != null) {
        return (body['data'] as List)
            .map((item) => AiAnalysisResult.fromJson(item))
            .toList();
      }
    }
    return null;
  }
}
