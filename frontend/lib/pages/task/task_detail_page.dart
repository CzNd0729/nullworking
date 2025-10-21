import 'package:flutter/material.dart';
import '../../models/task.dart';
import 'create_task_page.dart';
import '../../services/business/task_business.dart';

class TaskDetailPage extends StatelessWidget {
  final Task task;
  final bool isAssignedTask;

  TaskDetailPage({super.key, required this.task, this.isAssignedTask = false});

  final TaskBusiness _taskBusiness = TaskBusiness();

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
                    '$assignee',
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: isAssignedTask
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final updatedTask = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        CreateTaskPage(taskToEdit: task)),
                              );
                              if (updatedTask != null) {
                                Navigator.of(context)
                                    .pop(updatedTask);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '修改',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: const Color(0xFF1E1E1E),
                                    title: const Text(
                                      '确认删除',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: const Text(
                                      '您确定要删除此任务吗？',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text(
                                          '取消',
                                          style: TextStyle(
                                              color: Colors.blueAccent),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _taskBusiness
                                              .deleteTask(task.taskId)
                                              .then((response) {
                                            if (response == true) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text('任务删除成功！'),
                                                  backgroundColor: Color(
                                                      0xFF2CB7B3),
                                                ),
                                              );
                                              Navigator.of(context).pop(
                                                  true);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text('任务删除失败，请重试！'),
                                                  backgroundColor: Color(
                                                      0xFF2CB7B3),
                                                ),
                                              );
                                            }
                                          });
                                        },
                                        child: const Text(
                                          '删除',
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '删除',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
