import 'package:http/http.dart' as http;
import 'base_api.dart';

class CommentApi {
  final BaseApi _baseApi = BaseApi();

  /// 获取日志的评论列表
  Future<http.Response> getCommentsByLogId(String logId) async {
    return await _baseApi.get('api/comments/$logId');
  }

  /// 创建评论
  Future<http.Response> createComment(Map<String, dynamic> commentData) async {
    return await _baseApi.post('api/comments', body: commentData);
  }

  /// 删除评论
  Future<http.Response> deleteComment(int commentId) async {
    return await _baseApi.delete('api/comments/$commentId');
  }

  /// 获取用户的下属列表（用于@功能）
  Future<http.Response> getSubordinates() async {
    return await _baseApi.get('api/user/subordinates');
  }
}
