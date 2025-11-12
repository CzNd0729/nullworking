import 'package:nullworking/models/task.dart';

class NotificationModel {
  final DateTime creationTime;
  final bool isRead;
  final String content;
  final int? taskId;

  NotificationModel({
    required this.creationTime,
    required this.isRead,
    required this.content,
    this.taskId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      creationTime: DateTime.parse(json['creationTime'] as String),
      isRead: json['isRead'] as bool,
      content: json['content'] as String,
      taskId: json['taskId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creationTime': creationTime.toIso8601String(),
      'isRead': isRead,
      'content': content,
      'taskId': taskId,
    };
  }
}
