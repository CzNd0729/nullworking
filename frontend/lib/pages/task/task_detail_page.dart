import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/task.dart';
import '../../models/log.dart';
import '../log/create_log_page.dart';
import 'create_task_page.dart';
import '../../services/business/task_business.dart';
import '../../services/business/log_business.dart';
import '../log/log_detail_page.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;
  // final bool isAssignedTask; // 删除此行

  const TaskDetailPage({
    super.key,
    required this.task,
    // this.isAssignedTask = false, // 删除此行
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

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LogDetailPage(logId: log.logId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 32),
        child: IntrinsicHeight(
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
                      border: Border.all(
                        color: const Color(0xFF1E1E1E),
                        width: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 1,
                      child: CustomPaint(
                        painter: DashedLinePainter(
                          color: isDashedLine ? Colors.grey : Colors.green,
                          isDashed: isDashedLine,
                          isBottom: isBottom,
                        ),
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
                    Row(
                      children: [
                        Text(
                          log.endTime,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        if (log.userName != null &&
                            log.userName!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            log.userName!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 进度值独立显示在右侧
              if (log.taskProgress != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: log.logStatus == 1 ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${log.taskProgress!}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
    final title = widget.task.taskTitle;
    final description = widget.task.taskContent;
    final assignee = widget.task.executorNames.join(', ');
    final creationDate = widget.task.creationTime.toLocal().toString().split(
      ' ',
    )[0];
    final creationTime = widget.task.creationTime
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 5);
    final dueDate = widget.task.deadline.toLocal().toString().split(' ')[0];
    final dueTime = widget.task.deadline
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 5);
    final completionDate = widget.task.completionTime
        ?.toLocal()
        .toString()
        .split(' ')[0];
    final completionTime = widget.task.completionTime
        ?.toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 5);
    final priority = 'P${widget.task.taskPriority}';
    String status;
    switch (widget.task.taskStatus) {
      case '0':
        if (DateTime.now().isAfter(widget.task.deadline)) {
          status = '已延期';
        } else {
          status = '进行中';
        }
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
        actions: [
          if (!widget.task.isParticipated) // 如果任务是用户创建的（非参与的），则显示修改和删除按钮
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _editTask(),
            ),
          if (!widget.task.isParticipated &&
              widget.task.taskStatus != '2') // 如果任务是用户创建的（非参与的）且未完成，则显示删除按钮
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDeleteTask(),
            ),
        ],
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
                    '任务信息',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person_outline,
                    '创建者',
                    widget.task.creatorName,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.person_outline, '负责人', assignee),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    '创建时间',
                    '$creationDate $creationTime',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    '截止时间',
                    '$dueDate $dueTime',
                  ),
                  if (widget.task.completionTime != null &&
                      (widget.task.taskStatus == '2' ||
                          widget.task.taskStatus == '3')) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.calendar_today,
                      '完成时间',
                      '$completionDate $completionTime',
                    ),
                  ],
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
                        '关联日志',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // 只有当用户是任务的负责人（参与者）时，才显示添加日志按钮
                      if (widget.task.isParticipated)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('添加日志'),
                          onPressed: () async {
                            final newLog = await Navigator.push<Log?>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateLogPage(preSelectedTask: widget.task),
                              ),
                            );
                            if (newLog != null) {
                              _loadTaskLogs();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
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
            // 原来的按钮区域已移除
          ],
        ),
      ),
    );
  }

  Future<void> _editTask() async {
    final updatedTask = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(taskToEdit: widget.task),
      ),
    );
    if (updatedTask != null) {
      Navigator.of(context).pop(updatedTask);
    }
  }

  Future<void> _confirmDeleteTask() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('确认删除', style: TextStyle(color: Colors.white)),
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
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final bool isDashed;
  final bool isBottom; // 添加 isBottom 参数

  DashedLinePainter({
    required this.color,
    required this.isDashed,
    this.isBottom = false, // 默认为 false
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    if (isBottom) {
      return;
    }
    // The margin of _buildTimelineItem is 32, so we extend the line by that amount.
    final totalHeight = size.height + 32.0;

    if (isDashed) {
      const dashLength = 2.0;
      const gapLength = 4.0;
      double currentPosition = 0.0;

      while (currentPosition < totalHeight) {
        canvas.drawLine(
          Offset(0, currentPosition),
          Offset(0, currentPosition + dashLength),
          paint,
        );
        currentPosition += dashLength + gapLength;
      }
    } else {
      canvas.drawLine(Offset(0, 0), Offset(0, totalHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
    return color != oldDelegate.color ||
        isDashed != oldDelegate.isDashed ||
        isBottom != oldDelegate.isBottom;
  }
}
