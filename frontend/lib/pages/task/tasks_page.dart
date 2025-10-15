import 'package:flutter/material.dart';
import 'create_task_page.dart';
import 'task_detail_page.dart';
import '../../services/api/task_api.dart';
import '../../models/task.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TaskApi _taskApi = TaskApi();
  List<Task> _assignedTasks = [];
  List<Task> _myTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _taskApi.listUserTasks();
      if (response != null) {
        setState(() {
          _myTasks = response.createdTasks;
          _assignedTasks = response.participatedTasks; // Assuming participated means assigned by others
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载任务失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addTask(Task newTask) {
    setState(() {
      // 判断任务是创建者还是参与者，这里暂时假设creatorName就是当前用户
      // 更精确的判断需要用户ID
      if (newTask.creatorName == "当前用户") { // 假设 "当前用户" 是一个标识符，实际应替换为实际的用户名称或ID
        _myTasks.add(newTask);
      } else {
        _assignedTasks.add(newTask);
      }
    });
  }

  // 构建任务卡片组件
  Widget _buildTaskCard(Task task) {
    final statusTag = task.taskStatus == '0' ? '进行中' : '已完成'; // 假设'0'为进行中
    final taskTitle = task.taskTitle;
    final assignee = task.executorNames.join(', '); // 假设executorNames是分配者
    final deadline = task.deadline.toString().substring(0, 10);
    final priority = 'P${task.taskPriority}'; // 假设taskPriority是数字
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailPage(task: task),
                  ),
                );
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ExpansionTile(
                    title: const Text(
                      '派发任务',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
                        : _assignedTasks
                            .map((task) => _buildTaskCard(task))
                            .toList(),
                  ),
            const SizedBox(height: 16),
            // 我的任务模块
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ExpansionTile(
                    title: const Text(
                      '我的任务',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
          if (result != null && result is Task) {
            _addTask(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
