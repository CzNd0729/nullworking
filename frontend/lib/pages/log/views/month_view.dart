import 'package:flutter/material.dart';
import '../../../models/log.dart';
import '../../../services/business/log_business.dart'; // Import LogBusiness

class MonthView extends StatefulWidget { // Change to StatefulWidget
  // final List<Log> logs; // 移除logs参数
  final DateTime currentMonth;
  final Function(DateTime) onMonthChanged;
  final Function(DateTime) onDaySelected;

  const MonthView({
    super.key,
    // required this.logs, // 移除logs参数
    required this.currentMonth,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> { // State class
  final LogBusiness _logBusiness = LogBusiness(); // Add LogBusiness instance
  List<Log> _logs = []; // Add local logs list
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _fetchLogs(); // Fetch logs on initialization
  }

  @override
  void didUpdateWidget(covariant MonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMonth != oldWidget.currentMonth) {
      _fetchLogs(); // Refetch logs if month changes
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Add fetch logs method
  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _logs = [];
    });

    try {
      final firstDay = _getFirstDayOfMonth(widget.currentMonth);
      final lastDay = _getLastDayOfMonth(widget.currentMonth);

      final fetchedLogs = await _logBusiness.listLogs(
        startTime: _formatDate(firstDay),
        endTime: _formatDate(lastDay),
      );
      setState(() {
        _logs = fetchedLogs;
      });
    } catch (e) {
      debugPrint('Error fetching logs for month view: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 获取月份的第一天
  DateTime _getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // 获取月份的最后一天
  DateTime _getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // 生成月视图的日期列表（从周日开始到周六结束）
  List<DateTime> _generateMonthDays(DateTime month) {
    final firstDay = _getFirstDayOfMonth(month);
    final lastDay = _getLastDayOfMonth(month);

    // 找到第一个周日
    DateTime startDate = firstDay.subtract(
      Duration(days: firstDay.weekday % 7),
    );

    // 找到最后一个周六
    DateTime endDate = lastDay.add(Duration(days: (6 - lastDay.weekday) % 7));

    List<DateTime> days = [];
    DateTime current = startDate;

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  // 获取某天的所有日志
  List<Log> _getLogsForDate(DateTime date) {
    return _logs.where((log) { // Use internal _logs
      return log.logDate.year == date.year &&
          log.logDate.month == date.month &&
          log.logDate.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final monthDays = _generateMonthDays(widget.currentMonth);
    final weeks = <List<DateTime>>[];

    // 将日期按周分组
    for (int i = 0; i < monthDays.length; i += 7) {
      weeks.add(monthDays.sublist(i, i + 7));
    }

    // 颜色列表用于不同日志的显示
    final colors = [
      const Color(0xFF2CB7B3),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF795548),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 月份导航
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  widget.onMonthChanged(
                    DateTime(widget.currentMonth.year, widget.currentMonth.month - 1),
                  );
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
              ),
              Text(
                '${widget.currentMonth.year}年${widget.currentMonth.month}月',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  widget.onMonthChanged(
                    DateTime(widget.currentMonth.year, widget.currentMonth.month + 1),
                  );
                },
                icon: const Icon(Icons.chevron_right, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 星期标题（周日到周六）
          Row(
            children: const ['日', '一', '二', '三', '四', '五', '六'].map((day) {
              return Expanded(
                child: Container(
                  height: 40,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // 日期网格
          _isLoading
              ? const CircularProgressIndicator()
              : Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: weeks.length,
                    itemBuilder: (context, weekIndex) {
                      return SizedBox(
                        height: 80,
                        child: Row(
                          children: weeks[weekIndex].map((date) {
                            final isCurrentMonth = date.month == widget.currentMonth.month;
                            final dayLogs = _getLogsForDate(date);

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // 只允许点击当前月份的日期
                                  if (isCurrentMonth) {
                                    widget.onDaySelected(date);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isCurrentMonth
                                          ? Colors.white24
                                          : Colors.white10,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    children: [
                                      // 日期数字
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        child: Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            color: isCurrentMonth
                                                ? Colors.white
                                                : Colors.white38,
                                            fontSize: 12,
                                            fontWeight:
                                                date.day == DateTime.now().day &&
                                                    date.month ==
                                                        DateTime.now().month &&
                                                    date.year == DateTime.now().year
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),

                                      // 日志标识区域
                                      Expanded(
                                        child: dayLogs.isEmpty
                                            ? const SizedBox()
                                            : GridView.builder(
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      crossAxisSpacing: 1,
                                                      mainAxisSpacing: 1,
                                                      childAspectRatio: 1.5,
                                                    ),
                                                itemCount: dayLogs.length,
                                                itemBuilder: (context, logIndex) {
                                                  final log = dayLogs[logIndex];
                                                  final color =
                                                      colors[logIndex %
                                                          colors.length];
                                                  final firstChar =
                                                      log.logTitle.isNotEmpty
                                                      ? log.logTitle[0]
                                                      : '?';

                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: color.withOpacity(0.7),
                                                      borderRadius:
                                                          BorderRadius.circular(2),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        firstChar,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
