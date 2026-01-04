import 'package:http/http.dart' as http;
import 'base_api.dart';

class ShareApi {
  final BaseApi _baseApi = BaseApi();

  Future<http.Response> generateShareUrl(int resultId) async {
    final body = {
      'resultId': resultId,
    };
    return await _baseApi.post(
      'api/share/generate',
      body: body,
    );
  }
}
