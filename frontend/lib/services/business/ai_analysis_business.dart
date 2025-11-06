import 'dart:convert';

import 'package:http/http.dart';
import 'package:flutter/foundation.dart';
import 'package:nullworking/models/ai_analysis_result.dart';
import 'package:nullworking/services/api/ai_analysis_api.dart';

class AiAnalysisBusiness {
  final AiAnalysisApi _aiAnalysisApi = AiAnalysisApi();

  Future<String?> logAnalysis(int mode, Map<String, dynamic> body) async {
    try {
      final response = await _aiAnalysisApi.logAnalysis(mode, body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['code'] == 200) {
          return responseBody['data'].toString();
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('LogAnalysis 请求异常：$e');
      return null;
    }
  }

  Future<AiAnalysisResult?> getResultById(String resultId) async {
    try {
      return await _aiAnalysisApi.getResultById(resultId);
    } catch (e) {
      debugPrint('获取分析结果失败：$e');
      return null;
    }
  }

  Future<List<AiAnalysisResult>?> getResultList() async {
    try {
      return await _aiAnalysisApi.getResultList();
    } catch (e) {
      debugPrint('获取分析结果列表失败：$e');
      return null;
    }
  }
}
