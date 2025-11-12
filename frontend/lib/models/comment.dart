class Comment {
  final int? commentId;
  final int logId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final List<MentionedUser>? mentionedUsers;
  final DateTime createTime;
  final int? replyToId;
  final String? replyToUserName;

  Comment({
    this.commentId,
    required this.logId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.mentionedUsers,
    required this.createTime,
    this.replyToId,
    this.replyToUserName,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // 兼容后端字段名: id/commentId, createdAt/createTime, logId可能不存在
    final commentId = json['id'] as int? ?? json['commentId'] as int?;
    final logId = json['logId'] as int? ?? 0;
    final userId = json['userId'] as int? ?? 0;

    // 解析时间字段
    DateTime parseTime;
    if (json['createdAt'] != null) {
      parseTime = DateTime.parse(json['createdAt'].toString());
    } else if (json['createTime'] != null) {
      parseTime = DateTime.parse(json['createTime'].toString());
    } else {
      parseTime = DateTime.now();
    }

    final content = json['content']?.toString() ?? '';

    // 如果没有userName，使用userId显示
    final userName = json['userName']?.toString() ?? '用户$userId';

    return Comment(
      commentId: commentId,
      logId: logId,
      userId: userId,
      userName: userName,
      userAvatar: json['userAvatar']?.toString(),
      content: content,
      mentionedUsers: json['mentionedUsers'] != null
          ? (json['mentionedUsers'] as List)
                .map((e) => MentionedUser.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      createTime: parseTime,
      replyToId: json['replyToId'] as int?,
      replyToUserName: json['replyToUserName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (commentId != null) 'commentId': commentId,
      'logId': logId,
      'userId': userId,
      'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      'content': content,
      if (mentionedUsers != null && mentionedUsers!.isNotEmpty)
        'mentionedUsers': mentionedUsers!.map((e) => e.toJson()).toList(),
      'createTime': createTime.toIso8601String(),
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToUserName != null) 'replyToUserName': replyToUserName,
    };
  }
}

class MentionedUser {
  final int userId;
  final String userName;
  final String? realName;

  MentionedUser({required this.userId, required this.userName, this.realName});

  factory MentionedUser.fromJson(Map<String, dynamic> json) {
    return MentionedUser(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? '',
      realName: json['realName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      if (realName != null) 'realName': realName,
    };
  }

  String get displayName => realName ?? userName;
}
