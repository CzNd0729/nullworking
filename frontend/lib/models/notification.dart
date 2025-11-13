class NotificationModel {
  final DateTime creationTime;
  bool isRead;
  final String content;
  final int? taskId;
  final int? logId;
  final int notificationId;

  NotificationModel({
    required this.creationTime,
    required this.isRead,
    required this.content,
    this.taskId,
    this.logId,
    required this.notificationId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      creationTime: DateTime.parse(json['creationTime'] as String),
      isRead: json['isRead'] as bool,
      content: json['content'] as String,
      taskId: json['taskId'] as int?,
      logId: json['logId'] as int?,
      notificationId: json['notificationId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creationTime': creationTime.toIso8601String(),
      'isRead': isRead,
      'content': content,
      'taskId': taskId,
      'logId': logId,
      'notificationId': notificationId,
    };
  }
}
