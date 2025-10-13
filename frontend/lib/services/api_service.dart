import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _baseUrl = 'http://58.87.76.10:8080'; //服务端ip

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    return await http.get(url);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final headers = {'Content-Type': 'application/json'};
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  // 登录接口 - 使用GET请求和查询参数
  Future<http.Response> login(String username, String password) async {
    final url = Uri.parse(
      '$_baseUrl/api/login?userName=$username&password=$password',
    );
    return await http.get(url);
  }

  // 注册接口 - 使用GET请求和查询参数
  Future<http.Response> register(String username, String password, String phone, {String? email}) async {
    print('发送注册请求到: $_baseUrl/api/register');
    print('用户名: $username');
    print('密码长度: ${password.length}');
    print('电话号码: $phone');
    print('邮箱: $email');

    // 构建查询参数
    final queryParams = {
      'userName': username,
      'password': password,
      'phone': phone,
    };
    
    // 如果提供了邮箱，添加到查询参数中
    if (email != null && email.isNotEmpty) {
      queryParams['email'] = email;
    }

    // 构建URL
    final uri = Uri.parse('$_baseUrl/api/register').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);

    print('注册API响应状态码: ${response.statusCode}');
    print('注册API响应内容: ${response.body}');

    return response;
  }

  // 验证token接口
  Future<http.Response> validateToken(String token) async {
    final url = Uri.parse('$_baseUrl/api/auth/validate');
    final headers = {'Authorization': 'Bearer $token'};
    return await http.get(url, headers: headers);
  }
}
