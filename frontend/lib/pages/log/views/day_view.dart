import 'package:flutter/material.dart';
import '../../../models/log.dart';

class DayView extends StatefulWidget {
  final List<Log> logs;

  const DayView({super.key, required this.logs});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  late DateTime _selectedDate;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
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

  // 获取特定时间段的日志
  List<Log> _getLogsForHour(int hour) {
    final logsForDate = _getLogsForDate();
    return logsForDate.where((log) {
      final startHour = int.tryParse(log.startTime.split(':')[0]) ?? 0;
      return startHour == hour;
    }).toList();
  }

  // 构建时间段卡片
  Widget _buildTimeSlotCard(int hour) {
    final logs = _getLogsForHour(hour);
    final hasLogs = logs.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间线和点
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  '$hour:00',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: hasLogs ? const Color(0xFF2C2C2C) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: hasLogs
                  ? Column(
                      children: logs.map((log) => _buildLogItem(log)).toList(),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Text(
                        '暂无计划',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
            ),
          ),
        ],
      ),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeRange,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.logTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (log.logContent.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              log.logContent,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // 构建日期选择器
  Widget _buildDateSelector() {
    final weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${_selectedDate.year}年${_selectedDate.month}月',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
          _buildDateSelector(),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: timeSlots
                    .map((hour) => _buildTimeSlotCard(hour))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
