import 'package:flutter/material.dart';
import 'create_task_page.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Map<String, dynamic>> _assignedTasks = [];
  List<Map<String, dynamic>> _myTasks = [];

  void _addTask(Map<String, dynamic> taskData) {
    setState(() {
      // 根据executorIDs判断任务归属
      // executorIDs = 1 表示分配给当前用户，应该放在"我的任务"
      // executorIDs = 2 表示分配给其他用户，应该放在"派发任务"
      print(
        '添加任务: ${taskData['title']}, executorIDs: ${taskData['executorIDs']}',
      );
      if (taskData['executorIDs'] == 1) {
        print('任务添加到"我的任务"');
        _myTasks.add(taskData);
      } else {
        print('任务添加到"派发任务"');
        _assignedTasks.add(taskData);
      }
    });
  }

  // 构建任务卡片组件
  Widget _buildTaskCard(Map<String, dynamic> task) {
    final statusTag = task['status'] == 'pending' ? '进行中' : '已完成';
    final taskTitle = task['title'] ?? '';
    final assignee = task['assignee'] ?? '';
    final deadline = task['dueDate'] != null
        ? DateTime.parse(task['dueDate']).toString().substring(0, 10)
        : '';
    final priority = task['priority'] ?? 'P1';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务状态标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusTag == '进行中' ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                statusTag,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            // 任务标题
            Text(
              taskTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 分配信息
            Text('分配给: $assignee'),
            const SizedBox(height: 4),
            // 截止日期
            Text('截止日期: $deadline'),
            const SizedBox(height: 4),
            // 优先级
            Text(
              '优先级: $priority',
              style: TextStyle(
                color: priority == 'P0'
                    ? Colors.red
                    : (priority == 'P1' ? Colors.orange : Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            // 查看详情按钮
            ElevatedButton(
              onPressed: () {
                // 后续可添加查看详情的逻辑
              },
              child: const Text('查看详情'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务列表'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 通知铃铛图标
          IconButton(
            onPressed: () {
              // 后续可添加通知逻辑
            },
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索栏
            TextField(
              decoration: InputDecoration(
                hintText: '按标题或任务内容搜索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 派发任务模块
            ExpansionTile(
              title: const Text(
                '派发任务',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              children: _assignedTasks.isEmpty
                  ? const [
                      Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          '暂无派发的任务',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ]
                  : _assignedTasks.map((task) => _buildTaskCard(task)).toList(),
            ),
            const SizedBox(height: 16),
            // 我的任务模块
            ExpansionTile(
              title: const Text(
                '我的任务',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              children: _myTasks.isEmpty
                  ? const [
                      Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          '暂无我的任务',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ]
                  : _myTasks.map((task) => _buildTaskCard(task)).toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTaskPage()),
          );
          if (result != null && result is Map<String, dynamic>) {
            _addTask(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
