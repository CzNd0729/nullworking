// 数据模型定义
class Task {
  final String taskID;
  final String creatorName;
  final String taskTitle;
  final String taskContent;
  final String taskPriority;
  final String taskStatus;
  final DateTime creationTime;
  final DateTime deadline;
  final List<String> executorNames;

  Task({
    required this.taskID,
    required this.creatorName,
    required this.taskTitle,
    required this.taskContent,
    required this.taskPriority,
    required this.taskStatus,
    required this.creationTime,
    required this.deadline,
    required this.executorNames,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskID: json['taskID'].toString(),
      creatorName: json['creatorName'].toString(),
      taskTitle: json['taskTitle'].toString(),
      taskContent: json['taskContent'].toString(),
      taskPriority: json['taskPriority'].toString(),
      taskStatus: json['taskStatus'].toString(),
      creationTime: DateTime.parse(json['creationTime']),
      deadline: DateTime.parse(json['deadline']),
      executorNames: List<String>.from(json['executorNames']),
    );
  }
}

class TaskListResponse {
  final List<Task> createdTasks;
  final List<Task> participatedTasks;

  TaskListResponse({
    required this.createdTasks,
    required this.participatedTasks,
  });

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    return TaskListResponse(
      createdTasks: (json['created'] as List)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList(),
      participatedTasks: (json['participated'] as List)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList(),
    );
  }
}
