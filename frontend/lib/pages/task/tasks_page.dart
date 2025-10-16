import 'package:flutter/material.dart';
import 'create_task_page.dart';
import 'task_detail_page.dart';
import '../../services/api/task_api.dart';
import '../../models/task.dart';
// import '../login/login_page.dart'; // 导入登录页面

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
          _assignedTasks = response.createdTasks;
          _myTasks = response.participatedTasks;
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
      // 新创建的任务默认属于当前用户创建，归类到“派发任务”
      _assignedTasks.add(newTask);
    });
  }

  // 构建任务卡片组件
  Widget _buildTaskCard(Task task) {
    final statusTag;
    Color statusColor;

    switch (task.taskStatus) {
      case '0':
        statusTag = '未开始';
        statusColor = Colors.blueGrey;
        break;
      case '1':
        statusTag = '进行中';
        statusColor = Colors.green;
        break;
      case '2':
        statusTag = '已完成';
        statusColor = Colors.purple;
        break;
      case '3':
        statusTag = '已关闭';
        statusColor = Colors.red;
        break;
      default:
        statusTag = '未知状态';
        statusColor = Colors.grey;
    }

    final taskTitle = task.taskTitle;
    final assignee = task.executorNames.join(', ');
    final deadline = task.deadline.toString().substring(0, 10);
    final priority = 'P${task.taskPriority}';
    return FractionallySizedBox(
      widthFactor: 0.95, // 占屏幕宽度的95%
      child: Card(
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
                  color: statusColor,
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
          // // 登出按钮 (已移动到个人资料页面)
          // IconButton(
          //   onPressed: () {
          //     // 执行登出操作，例如清除用户token，然后跳转到登录页面
          //     // 这里只是示例，实际登出逻辑可能需要清除本地存储的用户信息
          //     Navigator.pushAndRemoveUntil(
          //       context,
          //       MaterialPageRoute(builder: (context) => const LoginPage()),
          //       (Route<dynamic> route) => false, // 移除所有之前的路由
          //     );
          //   },
          //   icon: const Icon(Icons.logout),
          // ),
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
                    initiallyExpanded: true, // 默认展开
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
                    initiallyExpanded: true, // 默认展开
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
