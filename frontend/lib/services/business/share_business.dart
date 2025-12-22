import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nullworking/services/api/share_api.dart';

class ShareBusiness {
  final ShareApi _shareApi = ShareApi();

  Future<String?> generateShareUrl(int resultId) async {
    try {
      final response = await _shareApi.generateShareUrl(resultId);
      print(response.statusCode);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['code'] == 200 && body['data'] != null) {
          return body['data']['shortUrl']?.toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('生成分享链接异常：$e');
      return null;
    }
  }
}
