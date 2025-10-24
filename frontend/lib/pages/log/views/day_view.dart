import 'package:flutter/material.dart';
import '../../../models/log.dart';
import '../log_detail_page.dart';

class DayView extends StatefulWidget {
  final List<Log> logs;
  final DateTime? initialDate;

  const DayView({super.key, required this.logs, this.initialDate});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  late DateTime _selectedDate;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 获取指定日期的所有日志
  List<Log> _getLogsForDate() {
    return widget.logs.where((log) {
      return log.logDate.year == _selectedDate.year &&
          log.logDate.month == _selectedDate.month &&
          log.logDate.day == _selectedDate.day;
    }).toList();
  }

  // 计算日志时间位置
  double _calculateLogPosition(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour + (minute / 60);
  }

  // 计算日志高度
  double _calculateLogHeight(String startTime, String endTime) {
    final start = _calculateLogPosition(startTime);
    final end = _calculateLogPosition(endTime);
    return (end - start) * 60; // 每小时60逻辑像素
  }

  // 检查两个日志是否时间重叠
  bool _isOverlapping(Log a, Log b) {
    final aStart = _calculateLogPosition(a.startTime);
    final aEnd = _calculateLogPosition(a.endTime);
    final bStart = _calculateLogPosition(b.startTime);
    final bEnd = _calculateLogPosition(b.endTime);
    return aStart < bEnd && bStart < aEnd;
  }

  // 计算日志应该在第几列
  int _calculateColumn(
    Log log,
    List<Log> allLogs,
    Map<String, int> columnAssignments,
  ) {
    if (columnAssignments.containsKey(log.logId)) {
      return columnAssignments[log.logId]!;
    }

    Set<int> usedColumns = {};
    for (var other in allLogs) {
      if (other.logId != log.logId &&
          columnAssignments.containsKey(other.logId) &&
          _isOverlapping(log, other)) {
        usedColumns.add(columnAssignments[other.logId]!);
      }
    }

    int column = 0;
    while (usedColumns.contains(column)) {
      column++;
    }

    columnAssignments[log.logId] = column;
    return column;
  }

  // 获取重叠日志组的最大列数
  int _getMaxColumns(List<Log> logs) {
    Map<String, int> columnAssignments = {};
    for (var log in logs) {
      _calculateColumn(log, logs, columnAssignments);
    }
    return columnAssignments.values.fold(
          0,
          (max, col) => col > max ? col : max,
        ) +
        1;
  }

  // 构建时间段网格
  Widget _buildTimeGrid(List<Log> logs) {
    Map<String, int> columnAssignments = {};
    final maxColumns = _getMaxColumns(logs);
    final availableWidth =
        MediaQuery.of(context).size.width -
        108; // 60 for timeline + 32 for padding + 16 for margins
    final columnWidth = availableWidth / maxColumns;

    return Stack(
      children: [
        // 时间轴
        Column(
          children: List.generate(24, (hour) {
            return Container(
              height: 60,
              margin: const EdgeInsets.only(bottom: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间标签
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // 时间网格线
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        // 日志卡片
        ...logs.map((log) {
          final startPosition = _calculateLogPosition(log.startTime) * 60;
          final height = _calculateLogHeight(log.startTime, log.endTime);
          final column = _calculateColumn(log, logs, columnAssignments);

          return Positioned(
            top: startPosition,
            left: 60 + (column * columnWidth), // 时间轴宽度 + 列偏移
            width: columnWidth - 8, // 减去边距
            child: SizedBox(height: height, child: _buildLogItem(log)),
          );
        }).toList(),
      ],
    );
  }

  // 构建日志项
  Widget _buildLogItem(Log log) {
    Color statusColor;
    String timeRange = '${log.startTime} - ${log.endTime}';

    switch (log.logStatus) {
      case 0:
        statusColor = Colors.blueAccent;
        break;
      case 1:
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LogDetailPage(logId: log.logId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    timeRange,
                    style: TextStyle(color: statusColor, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              log.logTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (log.logContent.isNotEmpty) ...[
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  log.logContent,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 获取所在周的起始日期（周日）
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  // 获取本月的第几周
  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday % 7;
    final offset = date.day + firstWeekdayOfMonth - 1;
    return (offset / 7).ceil();
  }

  // 切换到前一周
  void _previousWeek() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
    });
  }

  // 切换到后一周
  void _nextWeek() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 7));
    });
  }

  // 构建日期选择器
  Widget _buildDateSelector() {
    final weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
                onPressed: _previousWeek,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_selectedDate.year}年${_selectedDate.month}月',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2CB7B3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '第${_getWeekOfMonth(_selectedDate)}周',
                      style: const TextStyle(
                        color: Color(0xFF2CB7B3),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white54),
                onPressed: _nextWeek,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                },
                child: Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2CB7B3) : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekDays[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : isToday
                              ? const Color(0xFF2CB7B3)
                              : Colors.white,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsForDate = _getLogsForDate();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _buildTimeGrid(logsForDate),
            ),
          ),
        ],
      ),
    );
  }
}
