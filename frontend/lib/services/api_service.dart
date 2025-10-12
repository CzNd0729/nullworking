import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://58.87.76.10:8080'; //服务端ip

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    return await http.get(url);
  }

  // 可以在这里添加其他 HTTP 方法，如 post, put, delete
}
