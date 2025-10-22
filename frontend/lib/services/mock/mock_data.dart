import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/log.dart';

class MockData {
  static Task generateTestTask() {
    return Task(
      taskId: "test_123",
      taskTitle: "移动端应用开发任务",
      taskContent: "开发一个包含任务管理和日志记录功能的Flutter应用，支持进度跟踪和状态管理",
      creatorName: "测试管理员",
      executorNames: ["测试开发者"],
      deadline: DateTime.now().add(const Duration(days: 7)),
      taskPriority: "2",
      taskStatus: "0",
      creationTime: DateTime.now(), // 补充缺少的参数
    );
  }

  static List<Log> generateTestLogs(String taskId) {
    final now = DateTime.now();
    final timeFormatter = DateFormat('HH:mm');

    return [
      Log(
        logId: "log_001",
        taskId: int.tryParse(taskId),
        logTitle: "项目初始化与需求分析",
        logContent: "完成项目框架搭建，梳理了核心功能需求，确定了开发优先级和时间节点",
        logStatus: 1,
        taskProgress: 20,
        startTime: timeFormatter.format(now.subtract(const Duration(days: 5, hours: 3))),
        endTime: timeFormatter.format(now.subtract(const Duration(days: 5, hours: 1))),
        logDate: now.subtract(const Duration(days: 5)),
        fileIds: [],
      ),
      Log(
        logId: "log_002",
        taskId: int.tryParse(taskId),
        logTitle: "UI组件开发与页面布局",
        logContent: "完成了任务列表、详情页和日志创建页面的UI开发，实现了响应式布局",
        logStatus: 1,
        taskProgress: 45,
        startTime: timeFormatter.format(now.subtract(const Duration(days: 3, hours: 2))),
        endTime: timeFormatter.format(now.subtract(const Duration(days: 3))),
        logDate: now.subtract(const Duration(days: 3)),
        fileIds: [],
      ),
      Log(
        logId: "log_003",
        taskId: int.tryParse(taskId),
        logTitle: "业务逻辑与数据处理",
        logContent: "实现了任务创建、编辑和删除功能，正在开发日志时间轴展示功能",
        logStatus: 0,
        taskProgress: 70,
        startTime: timeFormatter.format(now.subtract(const Duration(hours: 5))),
        endTime: timeFormatter.format(now.subtract(const Duration(hours: 2))),
        logDate: now,
        fileIds: [],
      ),
    ];
  }

  static List<Task> generateTestTasks() {
    return [
      generateTestTask(),
      Task(
        taskId: "test_456",
        taskTitle: "用户需求调研",
        taskContent: "针对目标用户群体进行需求调研，形成调研报告",
        creatorName: "测试管理员",
        executorNames: ["测试分析师"],
        deadline: DateTime.now().add(const Duration(days: 3)),
        taskPriority: "1",
        taskStatus: "0",
        creationTime: DateTime.now(), // 补充缺少的参数
      ),
    ];
  }
}