import 'package:flutter/material.dart';
import 'dart:math';
import '../../../models/log.dart';
import '../log_detail_page.dart';

class WeekView extends StatefulWidget {
  final List<Log> logs;

  const WeekView({super.key, required this.logs});

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late DateTime _currentWeek;
  final List<String> _weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

  @override
  void initState() {
    super.initState();
    // 设置当前周的起始日期（周日）
    final now = DateTime.now();
    _currentWeek = now.subtract(Duration(days: now.weekday % 7));
  }

  // 获取一周的日期列表
  List<DateTime> _getWeekDays() {
    return List.generate(7, (index) => _currentWeek.add(Duration(days: index)));
  }

  // 获取指定日期的所有日志
  List<Log> _getLogsForDate(DateTime date) {
    return widget.logs.where((log) {
      return log.logDate.year == date.year &&
          log.logDate.month == date.month &&
          log.logDate.day == date.day;
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

  // 构建单日日志网格
  Widget _buildDayGrid(DateTime date, double dayWidth) {
    final logs = _getLogsForDate(date);
    Map<String, int> columnAssignments = {};
    final maxColumns = _getMaxColumns(logs);
    final columnWidth = (dayWidth - 8) / maxColumns; // 设置更大的边距，确保每列有足够空间

    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
        color: isToday ? Colors.white.withOpacity(0.02) : null,
      ),
      child: Stack(
        children: [
          // 时间网格线
          Column(
            children: List.generate(24, (hour) {
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
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
              left: 8 + (column * columnWidth),
              width: columnWidth - 4,
              height: height,
              child: _buildLogCard(log),
            );
          }).toList(),

          // 当前时间线（仅在今天显示）
          if (isToday)
            Positioned(
              left: 0,
              right: 0,
              top:
                  (TimeOfDay.now().hour * 60 +
                      TimeOfDay.now().minute.toDouble()) *
                  1.0,
              child: Container(height: 1, color: const Color(0xFF2CB7B3)),
            ),
        ],
      ),
    );
  }

  // 构建日志卡片
  Widget _buildLogCard(Log log) {
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
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFF2CB7B3).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          log.logTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            height: 1.2, // 设置行高稍微紧凑一点
          ),
          softWrap: true, // 允许文本换行
          overflow: TextOverflow.visible, // 不使用省略号
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays();
    final screenWidth = MediaQuery.of(context).size.width;
    final dayWidth = max((screenWidth - 76) / 7, 140.0); // 设置每天最小宽度为140像素

    return Container(
      width: screenWidth,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 周导航
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _currentWeek = _currentWeek.subtract(
                        const Duration(days: 7),
                      );
                    });
                  },
                ),
                Text(
                  '${_currentWeek.year}年${_currentWeek.month}月 第${(_currentWeek.day / 7).ceil()}周',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _currentWeek = _currentWeek.add(const Duration(days: 7));
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 日期表头和内容区域
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: max(screenWidth, dayWidth * 7 + 76), // 确保总宽度足够
                child: Column(
                  children: [
                    // 日期表头
                    Row(
                      children: [
                        // 时间轴标题
                        const SizedBox(width: 60),
                        ...weekDays.asMap().entries.map((entry) {
                          final date = entry.value;
                          final isToday =
                              date.year == DateTime.now().year &&
                              date.month == DateTime.now().month &&
                              date.day == DateTime.now().day;

                          return Container(
                            width: dayWidth,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              color: isToday
                                  ? Colors.white.withOpacity(0.02)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _weekDays[entry.key],
                                  style: TextStyle(
                                    color: isToday
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    color: isToday
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 14,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),

                    // 时间网格和日志展示
                    Expanded(
                      child: SingleChildScrollView(
                        child: SizedBox(
                          height: 60 * 24, // 24小时 * 每小时60逻辑像素
                          child: Stack(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 时间轴
                                  SizedBox(
                                    width: 60,
                                    child: Column(
                                      children: List.generate(24, (hour) {
                                        return SizedBox(
                                          height: 60,
                                          child: Center(
                                            child: Text(
                                              '${hour.toString().padLeft(2, '0')}:00',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  // 每天的日志网格
                                  ...weekDays.map(
                                    (date) => _buildDayGrid(date, dayWidth),
                                  ),
                                ],
                              ),

                              // 当前时间线
                              if (weekDays.any(
                                (date) =>
                                    date.year == DateTime.now().year &&
                                    date.month == DateTime.now().month &&
                                    date.day == DateTime.now().day,
                              ))
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top:
                                      (TimeOfDay.now().hour * 60 +
                                          TimeOfDay.now().minute.toDouble()) *
                                      1.0,
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFF2CB7B3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
