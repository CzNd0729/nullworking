import 'package:flutter/material.dart';
import 'create_task_page.dart';
import 'task_detail_page.dart';
import '../../models/task.dart';
import '../../services/business/task_business.dart';
import 'package:nullworking/pages/notification/notification_list_page.dart'; // 新增导入
import '../../widgets/notification_icon_with_badge.dart'; // 新增导入

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TaskBusiness _taskBusiness = TaskBusiness();
  List<Task> _assignedTasks = [];
  List<Task> _myTasks = [];
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedStatusFilters = {'0', '1'};
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchFocusNode.addListener(() {
      if (!mounted) return;
      if (!_searchFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _forceSearchUnfocus() {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final taskData = await _taskBusiness.loadUserTasks();
      if (taskData != null) {
        setState(() {
          _assignedTasks = taskData['createdTasks']!;
          _myTasks = taskData['participatedTasks']!;
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
      _assignedTasks.add(newTask);
      _selectedStatusFilters = {'0', '1'};
    });
  }

  List<Task> _filterTasks(List<Task> tasks) {
    return _taskBusiness.filterTasks(
      tasks,
      _searchController.text,
      _selectedStatusFilters,
    );
  }

  void _toggleStatusFilter(String status) {
    _forceSearchUnfocus();
    setState(() {
      if (_selectedStatusFilters.contains(status)) {
        _selectedStatusFilters.remove(status);
      } else {
        _selectedStatusFilters.add(status);
      }
    });
  }

  void _clearAllFilters() {
    _forceSearchUnfocus();
    setState(() {
      _searchController.clear();
      _selectedStatusFilters.clear();
    });
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                GestureDetector(
                  onTap: _clearAllFilters,
                  child: const Text(
                    '清除筛选',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
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
      showCheckmark: false,
      side: BorderSide(color: color, width: 1.0),
    );
  }

  Widget _buildTaskCard(Task task, {required bool isAssignedTask}) {
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
    final deadline = task.deadline.toLocal().toString().substring(0, 16);
    final priority = 'P${task.taskPriority}';
    final progress =
        task.taskProgress / 100.0; // Assuming taskProgress is 0-100

    Color progressColor;
    if (task.taskProgress == 100) {
      progressColor = Colors.purple;
    } else if (task.taskProgress >= 76) {
      progressColor = Colors.green;
    } else if (task.taskProgress >= 51) {
      progressColor = Colors.blue;
    } else if (task.taskProgress >= 26) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return FractionallySizedBox(
      widthFactor: 0.95,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            12.0,
          ), // Ensure InkWell has rounded corners
          onTap: () {
            _forceSearchUnfocus();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailPage(task: task),
              ),
            ).then((result) {
              _forceSearchUnfocus();
              if (result != null) {
                _loadTasks();
              }
            });
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        statusTag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      taskTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('创建者: ${task.creatorName}'),
                    const SizedBox(height: 4),
                    Text('负责人: $assignee'),
                    const SizedBox(height: 4),
                    Text('截止时间: $deadline'),
                    if (task.completionTime != null &&
                        (task.taskStatus == '2' || task.taskStatus == '3')) ...[
                      const SizedBox(height: 4),
                      Text(
                        '完成时间: ${task.completionTime!.toLocal().toString().substring(0, 16)}',
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '优先级: $priority',
                      style: TextStyle(
                        color: priority == 'P0'
                            ? Colors.red
                            : (priority == 'P1' ? Colors.orange : Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        color: progressColor,
                        strokeWidth: 4,
                      ),
                    ),
                    Text(
                      '${task.taskProgress}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
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
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                title: const Text('任务列表'),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                centerTitle: true,
                actions: [
                  const NotificationIconWithBadge(), // Use the new widget
                ],
                floating: true,
                pinned: false,
                snap: true,
                forceElevated: innerBoxIsScrolled,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                  child: TextField(
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '按标题或任务内容搜索',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onTapOutside: (event) {
                      _forceSearchUnfocus();
                    },
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      _forceSearchUnfocus();
                    },
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverFilterBarDelegate(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildFilterBar(),
                    ),
                  ),
                  height: 110.0,
                ),
              ),
            ];
          },
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2CB7B3),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    ExpansionTile(
                      onExpansionChanged: (expanded) {
                        _forceSearchUnfocus();
                      },
                      initiallyExpanded: true,
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
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ]
                            : filteredTasks
                                  .map(
                                    (task) => _buildTaskCard(
                                      task,
                                      isAssignedTask: true,
                                    ),
                                  )
                                  .toList();
                      }(),
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      onExpansionChanged: (expanded) {
                        _forceSearchUnfocus();
                      },
                      initiallyExpanded: true,
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
                                    _myTasks.isEmpty
                                        ? '暂无我的任务'
                                        : '没有符合筛选条件的我的任务',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ]
                            : filteredTasks
                                  .map(
                                    (task) => _buildTaskCard(
                                      task,
                                      isAssignedTask: false,
                                    ),
                                  )
                                  .toList();
                      }(),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _forceSearchUnfocus();
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

class _SliverFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverFilterBarDelegate({required this.child, this.height = 120.0});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverFilterBarDelegate oldDelegate) {
    return true;
  }
}
