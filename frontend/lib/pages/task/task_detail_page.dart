import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/api/task_api.dart'; // 导入 TaskApi
import 'create_task_page.dart'; // 导入 CreateTaskPage

class TaskDetailPage extends StatelessWidget {
  final Task task;
  final bool isAssignedTask; // 新增任务来源信息

  TaskDetailPage({super.key, required this.task, this.isAssignedTask = false});

  final TaskApi _taskApi = TaskApi(); // 实例化 TaskApi

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: isAssignedTask // 根据任务来源信息条件性显示按钮
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
                                    .pop(updatedTask); // 返回更新后的任务，让上一个页面接收并刷新
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
                                    backgroundColor: const Color(0xFF1E1E1E), // 与主色调相同
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
                                          Navigator.of(context).pop(); // 关闭弹窗
                                        },
                                        child: const Text(
                                          '取消',
                                          style: TextStyle(
                                              color: Colors.blueAccent),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // 关闭弹窗
                                          _taskApi
                                              .deleteTask(task.taskID)
                                              .then((response) {
                                            if (response.statusCode == 200) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text('任务删除成功！'),
                                                  backgroundColor: Color(
                                                      0xFF2CB7B3), // 与主色调相同
                                                ),
                                              );
                                              Navigator.of(context).pop(
                                                  true); // 返回上一页并指示刷新
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text('任务删除失败，请重试！'),
                                                  backgroundColor: Color(
                                                      0xFF2CB7B3), // 与主色调相同
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
                  : const SizedBox.shrink(), // 如果不是派发任务，则隐藏按钮
            ),
          ],
        ),
      ),
    );
  }
}
