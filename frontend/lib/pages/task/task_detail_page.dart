import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../models/task.dart';
import '../../models/log.dart';
import '../log/create_log_page.dart';
import 'create_task_page.dart';
import '../../services/business/task_business.dart';
import '../../services/business/log_business.dart';
import '../../services/mock/mock_data.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;
  final bool isAssignedTask;

  const TaskDetailPage({
    super.key,
    required this.task,
    this.isAssignedTask = false,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final TaskBusiness _taskBusiness = TaskBusiness();
  final LogBusiness _logBusiness = LogBusiness();
  List<Log> _taskLogs = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    _loadTaskLogs();
  }

  Future<void> _loadTaskLogs() async {
    try {
      setState(() => _isLoadingLogs = true);

      // 移除 _debugMode 相关的逻辑和 MockData.generateTestLogs 调用

      final logs = await _logBusiness.getLogsByTaskId(widget.task.taskId);
      logs.sort((a, b) => b.logDate.compareTo(a.logDate));
      setState(() => _taskLogs = logs);
    } catch (e) {
      debugPrint('加载任务日志失败: $e');
      setState(() => _taskLogs = []);
    } finally {
      setState(() => _isLoadingLogs = false);
    }
  }

  int _getMaxCompletedProgress() {
    int maxProgress = 0;
    for (var log in _taskLogs) {
      if (log.logStatus == 1 && (log.taskProgress ?? 0) > maxProgress) {
        maxProgress = log.taskProgress ?? 0;
      }
    }
    return maxProgress;
  }

  List<Log> _getFilteredLogs() {
    final maxCompleted = _getMaxCompletedProgress();
    return _taskLogs.where((log) {
      if (log.logStatus == 1) return true;
      return (log.taskProgress ?? 0) > maxCompleted;
    }).toList()
      ..sort((a, b) => (a.taskProgress ?? 0).compareTo(b.taskProgress ?? 0));
  }

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

  Widget _buildLogTimeline() {
    if (_isLoadingLogs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2CB7B3)),
          ),
        ),
      );
    }

    final filteredLogs = _getFilteredLogs();
    
    if (filteredLogs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '暂无日志，点击"添加日志"开始记录',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final reversedLogs = List<Log>.from(filteredLogs.reversed);

    return Column(
      children: List.generate(reversedLogs.length, (index) {
        final log = reversedLogs[index];
        final isTop = index == 0;
        final isBottom = index == reversedLogs.length - 1;
        final prevLog = index > 0 ? reversedLogs[index - 1] : null;
        
        return _buildTimelineItem(
          log: log,
          isTop: isTop,
          isBottom: isBottom,
          prevLog: prevLog,
        );
      }),
    );
  }

  Widget _buildTimelineItem({
    required Log log,
    required bool isTop,
    required bool isBottom,
    Log? prevLog,
  }) {
    Color dotColor;
    bool isDashedLine = false;

    if (log.logStatus == 1) {
      dotColor = Colors.green;
      isDashedLine = false; // 已完成日志用实线
    } else {
      dotColor = Colors.grey;
      isDashedLine = true; // 未完成日志用虚线
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
                ),
              ),
              if (!isTop)
                Container(
                  height: 32,
                  width: 1,
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color: isDashedLine ? Colors.grey : Colors.green,
                      isDashed: isDashedLine,
                    ),
                  ),
                ),
              if (isTop && isDashedLine)
                Container(
                  height: 20,
                  width: 1,
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color: Colors.grey,
                      isDashed: true,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.logTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.logContent,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('yyyy年MM月dd日 HH:mm').format(log.logDate)}  ${log.taskProgress ?? 0}%',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.task.taskTitle;
    final description = widget.task.taskContent;
    final assignee = widget.task.executorNames.join(', ');
    final dueDate = widget.task.deadline.toLocal().toString().split(' ')[0];
    final dueTime = widget.task.deadline
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 5);
    final priority = 'P${widget.task.taskPriority}';
    String status;
    switch (widget.task.taskStatus) {
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
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
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
                    assignee,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    '截止日期',
                    '$dueDate $dueTime',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.flag, '优先级', priority),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.info_outline, '当前状态', status),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '任务关联日志',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('添加日志'),
                        onPressed: () async {
                          final newLog = await Navigator.push<Log?>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateLogPage(
                                preSelectedTask: widget.task,
                              ),
                            ),
                          );
                          if (newLog != null) {
                            _loadTaskLogs();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2CB7B3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLogTimeline(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: widget.isAssignedTask
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
                                      CreateTaskPage(taskToEdit: widget.task),
                                ),
                              );
                              if (updatedTask != null) {
                                Navigator.of(context).pop(updatedTask);
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
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text(
                                          '取消',
                                          style: TextStyle(color: Colors.blueAccent),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _taskBusiness.deleteTask(widget.task.taskId).then((response) {
                                            if (response == true) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('任务删除成功！'),
                                                  backgroundColor: Color(0xFF2CB7B3),
                                                ),
                                              );
                                              Navigator.of(context).pop(true);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('任务删除失败，请重试！'),
                                                  backgroundColor: Color(0xFF2CB7B3),
                                                ),
                                              );
                                            }
                                          });
                                        },
                                        child: const Text(
                                          '删除',
                                          style: TextStyle(color: Colors.redAccent),
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

class DashedLinePainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  DashedLinePainter({
    required this.color,
    required this.isDashed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const fixLength = 90.0;

    if (isDashed) {
      const dashLength = 2.0;
      const gapLength = 4.0;
      double currentPosition = 0.0;

      while (currentPosition < size.height + fixLength) {
        canvas.drawLine(
          Offset(0, currentPosition),
          Offset(0, currentPosition + dashLength),
          paint,
        );
        currentPosition += dashLength + gapLength;
      }
    } else {
      canvas.drawLine(Offset(0, 0), Offset(0, size.height+fixLength), paint);
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
    return color != oldDelegate.color || isDashed != oldDelegate.isDashed;
  }
}