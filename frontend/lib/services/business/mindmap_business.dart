import 'package:nullworking/services/api/user_api.dart';

class MindMapBusiness {
  final UserApi _userApi = UserApi();

  Future<Map<String, String>> fetchMindMapData() async {
    try {
      final response = await _userApi.getHealth();

      if (response.statusCode == 200) {
        return {
          'companyImportant': "公司重要事项数据",
          'companyTask': "公司任务调度数据",
          'personalImportant': "个人重要事项数据",
          'personalLog': "个人日志数据",
        };
      } else {
        return {
          'companyImportant': '请求失败: ${response.statusCode}',
          'companyTask': '请求失败: ${response.statusCode}',
          'personalImportant': '请求失败: ${response.statusCode}',
          'personalLog': '请求失败: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'companyImportant': '发生错误: $e',
        'companyTask': '发生错误: $e',
        'personalImportant': '发生错误: $e',
        'personalLog': '发生错误: $e',
      };
    }
  }
}
