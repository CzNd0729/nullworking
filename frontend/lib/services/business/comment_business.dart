import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/comment.dart';
import '../../models/user.dart';
import '../api/comment_api.dart';

class CommentBusiness {
  final CommentApi _commentApi = CommentApi();

  /// 获取日志的评论列表
  Future<List<Comment>> getCommentsByLogId(String logId) async {
    try {
      final response = await _commentApi.getCommentsByLogId(logId);

      debugPrint('评论API响应码: ${response.statusCode}');
      debugPrint('评论API响应体: ${response.body}');

      if (response.body.isEmpty) {
        debugPrint('响应体为空');
        return [];
      }

      if (response.statusCode == 200 || response.statusCode == 403) {
        final data = jsonDecode(response.body);
        debugPrint('解析后的data: $data');

        if (data['code'] == 200 && data['data'] != null) {
          final commentsData = data['data'];
          debugPrint('commentsData: $commentsData');

          if (commentsData is Map && commentsData.containsKey('comments')) {
            final List<dynamic> commentsJson = commentsData['comments'] as List;
            debugPrint('找到${commentsJson.length}条评论');
            final comments = commentsJson
                .map((json) => Comment.fromJson(json as Map<String, dynamic>))
                .toList();
            debugPrint('成功解析${comments.length}条评论');
            return comments;
          } else {
            debugPrint('commentsData格式不正确或没有comments字段');
          }
        } else {
          debugPrint('code不是200或data为null');
        }
      } else {
        debugPrint('状态码不是200或403');
      }
      return [];
    } catch (e) {
      debugPrint('获取评论异常: $e');
      return [];
    }
  }

  /// 创建评论
  Future<Map<String, dynamic>> createComment({
    required String logId,
    required String content,
    List<MentionedUser>? mentionedUsers,
    int? replyToId,
    String? replyToUserName,
  }) async {
    try {
      final commentData = {
        'logId': int.parse(logId),
        'content': content,
        if (mentionedUsers != null && mentionedUsers.isNotEmpty)
          'mentionedUsers': mentionedUsers.map((e) => e.toJson()).toList(),
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToUserName != null) 'replyToUserName': replyToUserName,
      };

      final response = await _commentApi.createComment(commentData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['code'] == 200) {
          return {'success': true, 'message': '评论成功', 'data': data['data']};
        } else {
          return {'success': false, 'message': data['message'] ?? '评论失败'};
        }
      } else {
        return {'success': false, 'message': '评论请求失败: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('创建评论异常: $e');
      return {'success': false, 'message': '评论异常: ${e.toString()}'};
    }
  }

  /// 删除评论
  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    try {
      final response = await _commentApi.deleteComment(commentId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 200) {
          return {'success': true, 'message': '删除成功'};
        } else {
          return {'success': false, 'message': data['message'] ?? '删除失败'};
        }
      } else {
        return {'success': false, 'message': '删除请求失败: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('删除评论异常: $e');
      return {'success': false, 'message': '删除异常: ${e.toString()}'};
    }
  }

  /// 获取下属列表（用于@功能）
  Future<List<User>> getSubordinates() async {
    try {
      final response = await _commentApi.getSubordinates();

      // 检查响应体是否为空
      if (response.body.isEmpty) {
        return [];
      }

      if (response.statusCode == 200 || response.statusCode == 403) {
        final data = jsonDecode(response.body);

        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> usersJson = data['data'] as List;
          return usersJson
              .map((json) => User.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('获取下属列表异常: $e');
      return [];
    }
  }
}
