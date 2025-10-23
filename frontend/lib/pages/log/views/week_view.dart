import 'package:flutter/material.dart';
import '../../../models/log.dart';

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

  // 获取指定日期和时间段的日志
  List<Log> _getLogsForTimeSlot(DateTime date, int hour) {
    return widget.logs.where((log) {
      return log.logDate.year == date.year &&
          log.logDate.month == date.month &&
          log.logDate.day == date.day &&
          int.tryParse(log.startTime.split(':')[0]) == hour;
    }).toList();
  }

  // 构建时间段单元格
  Widget _buildTimeSlotCell(DateTime date, int hour) {
    final logs = _getLogsForTimeSlot(date, hour);
    final isCurrentDay =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        color: isCurrentDay ? Colors.white.withOpacity(0.05) : null,
      ),
      child: logs.isEmpty
          ? const SizedBox()
          : Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF2CB7B3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: logs
                    .map(
                      (log) => Expanded(
                        child: Text(
                          log.logTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays();
    const timeSlots = [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 周导航
          Row(
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
          const SizedBox(height: 16),

          // 日期表头
          Row(
            children: [
              // 时间列表头
              const SizedBox(width: 50),
              // 星期表头
              ...List.generate(7, (index) {
                final date = weekDays[index];
                final isToday =
                    date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        _weekDays[index],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFF2CB7B3) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isToday ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // 时间格子
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: timeSlots.map((hour) {
                  return Row(
                    children: [
                      // 时间标签
                      SizedBox(
                        width: 50,
                        height: 60,
                        child: Center(
                          child: Text(
                            '$hour:00',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      // 每天的时间格子
                      ...weekDays.map(
                        (date) =>
                            Expanded(child: _buildTimeSlotCell(date, hour)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
