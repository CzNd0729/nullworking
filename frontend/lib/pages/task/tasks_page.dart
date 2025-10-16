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

  // 筛选相关状态
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedStatusFilters = {}; // 支持多选筛选

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      // 新创建的任务默认属于当前用户创建，归类到"派发任务"
      _assignedTasks.add(newTask);
    });
  }

  // 筛选任务的方法
  List<Task> _filterTasks(List<Task> tasks) {
    return tasks.where((task) {
      // 搜索筛选
      final searchQuery = _searchController.text.toLowerCase();
      final matchesSearch =
          searchQuery.isEmpty ||
          task.taskTitle.toLowerCase().contains(searchQuery) ||
          task.taskContent.toLowerCase().contains(searchQuery);

      // 状态筛选
      final matchesStatus =
          _selectedStatusFilters.isEmpty ||
          _selectedStatusFilters.contains(task.taskStatus);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // 切换状态筛选
  void _toggleStatusFilter(String status) {
    setState(() {
      if (_selectedStatusFilters.contains(status)) {
        _selectedStatusFilters.remove(status);
      } else {
        _selectedStatusFilters.add(status);
      }
    });
  }

  // 清除所有筛选
  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatusFilters.clear();
    });
  }

  // 构建筛选栏组件
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 筛选标题和清除按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '状态筛选',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_selectedStatusFilters.isNotEmpty ||
                  _searchController.text.isNotEmpty)
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text(
                    '清除筛选',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 状态筛选按钮
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildStatusFilterChip('0', '进行中', Colors.green),
              _buildStatusFilterChip('1', '已延期', Colors.orange),
              _buildStatusFilterChip('2', '已完成', Colors.purple),
              _buildStatusFilterChip('3', '已关闭', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  // 构建状态筛选按钮
  Widget _buildStatusFilterChip(String status, String label, Color color) {
    final isSelected = _selectedStatusFilters.contains(status);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => _toggleStatusFilter(status),
      backgroundColor: color.withOpacity(0.2),
      selectedColor: color,
      showCheckmark: false, // 去掉√符号
      side: BorderSide(color: color, width: 1.0),
    );
  }

  // 构建任务卡片组件
  Widget _buildTaskCard(Task task) {
    final statusTag;
    Color statusColor;

    switch (task.taskStatus) {
      case '0':
        statusTag = '进行中';
        statusColor = Colors.green;
        break;
      case '1':
        statusTag = '已延期';
        statusColor = Colors.orange;
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
              controller: _searchController,
              onChanged: (value) => setState(() {}), // 触发重新筛选
              decoration: InputDecoration(
                hintText: '按标题或任务内容搜索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 筛选栏
            _buildFilterBar(),
            const SizedBox(height: 16),
            // 派发任务模块
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ExpansionTile(
                    initiallyExpanded: true, // 默认展开
                    title: const Text(
                      '派发任务',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: () {
                      final filteredTasks = _filterTasks(_assignedTasks);
                      return filteredTasks.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  _assignedTasks.isEmpty
                                      ? '暂无派发的任务'
                                      : '没有符合筛选条件的派发任务',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ),
                            ]
                          : filteredTasks
                                .map((task) => _buildTaskCard(task))
                                .toList();
                    }(),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: () {
                      final filteredTasks = _filterTasks(_myTasks);
                      return filteredTasks.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  _myTasks.isEmpty ? '暂无我的任务' : '没有符合筛选条件的我的任务',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ),
                            ]
                          : filteredTasks
                                .map((task) => _buildTaskCard(task))
                                .toList();
                    }(),
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
