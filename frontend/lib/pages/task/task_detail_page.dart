import 'package:flutter/material.dart';
import '../../models/task.dart';

class TaskDetailPage extends StatelessWidget {
  final Task task;

  const TaskDetailPage({super.key, required this.task});

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = task.taskTitle;
    final description = task.taskContent;
    final assignee = task.executorNames.join(', ');
    final assigneeRole = ""; // Task 模型中没有直接的 assigneeRole 字段
    final dueDate = task.deadline.toLocal().toString().split(' ')[0];
    final dueTime = task.deadline
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 5);
    final priority = 'P${task.taskPriority}';
    String status;
    switch (task.taskStatus) {
      case '0':
        status = '进行中';
        break;
      case '1':
        status = '已延期';
        break;
      case '2':
        status = '已完成';
        break;
      case '3':
        status = '已关闭';
        break;
      default:
        status = '未知状态';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF000000),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '任务概览',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person_outline,
                    '负责人',
                    '$assignee ($assigneeRole)',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    '截止日期',
                    '$dueDate $dueTime',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.flag, '优先级', '$priority'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.info_outline, '当前状态', '$status'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '任务关联日志',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('暂无日志', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
