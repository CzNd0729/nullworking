import 'package:flutter/material.dart';
import 'create_log_page.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<LogEntry> _allLogs = [];
  List<LogEntry> _filteredLogs = [];

  @override
  void initState() {
    super.initState();
    // 初始不填充示例数据，保持空列表
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        final matchesQuery =
            query.isEmpty ||
            log.title.toLowerCase().contains(query) ||
            log.content.toLowerCase().contains(query);
        // Date range matching (date-only comparison)
        final logDateOnly = DateTime(
          log.date.year,
          log.date.month,
          log.date.day,
        );
        bool matchesDate = true;
        if (_startDate != null && _endDate != null) {
          final startOnly = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          final endOnly = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          );
          matchesDate =
              logDateOnly.isAtSameMomentAs(startOnly) ||
              (logDateOnly.isAfter(startOnly) &&
                  logDateOnly.isBefore(endOnly)) ||
              logDateOnly.isAtSameMomentAs(endOnly) ||
              (logDateOnly.isAfter(startOnly) &&
                  (logDateOnly.isAtSameMomentAs(endOnly) ||
                      logDateOnly.isBefore(endOnly)));
          // simplify: check inclusive range
          matchesDate =
              !logDateOnly.isBefore(startOnly) && !logDateOnly.isAfter(endOnly);
        } else if (_startDate != null) {
          final startOnly = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          matchesDate = !logDateOnly.isBefore(startOnly);
        } else if (_endDate != null) {
          final endOnly = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          );
          matchesDate = !logDateOnly.isAfter(endOnly);
        }

        // Time-of-day matching: only applies when startDate and endDate are the same day
        bool matchesTime = true;
        if (_startTime != null &&
            _endTime != null &&
            _startDate != null &&
            _endDate != null &&
            _isSameDate(_startDate!, _endDate!)) {
          final int logMinutes = log.date.hour * 60 + log.date.minute;
          final int startMinutes = _timeToMinutes(_startTime!);
          final int endMinutes = _timeToMinutes(_endTime!);
          matchesTime = logMinutes >= startMinutes && logMinutes <= endMinutes;
        }
        return matchesQuery && matchesDate && matchesTime;
      }).toList();
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // single date picker removed; using start/end pickers instead

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(dialogBackgroundColor: const Color(0xFF000000)),
        child: child!,
      ),
    );
    if (picked != null) {
      if (_endDate != null && picked.isAfter(_endDate!)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('起始日期不能晚于结束日期')));
        return;
      }
      setState(() {
        _startDate = picked;
      });
      _applyFilters();
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(dialogBackgroundColor: const Color(0xFF000000)),
        child: child!,
      ),
    );
    if (picked != null) {
      if (_startDate != null && picked.isBefore(_startDate!)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('结束日期不能早于起始日期')));
        return;
      }
      setState(() {
        _endDate = picked;
      });
      _applyFilters();
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked != null) {
      if (_endTime != null &&
          _timeToMinutes(picked) > _timeToMinutes(_endTime!)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('起始时间不能晚于结束时间')));
        return;
      }
      setState(() {
        _startTime = picked;
      });
      _applyFilters();
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 19, minute: 59),
    );
    if (picked != null) {
      if (_startTime != null &&
          _timeToMinutes(picked) < _timeToMinutes(_startTime!)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('结束时间不能早于起始时间')));
        return;
      }
      setState(() {
        _endTime = picked;
      });
      _applyFilters();
    }
  }

  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _startTime = null;
      _endTime = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'P0':
        return Colors.redAccent;
      case 'P1':
        return Colors.orange;
      case 'P2':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('日志管理'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2CB7B3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final newLog = await Navigator.push<LogEntry?>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateLogPage()),
                );
                if (newLog != null) {
                  setState(() {
                    _allLogs.insert(0, newLog);
                  });
                  _applyFilters();
                }
              },
              child: const Text('新建', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: '按标题或日志内容搜索',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter card
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
                    children: [
                      const Expanded(
                        child: Text(
                          '日志创建时间',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text(
                          '清除筛选',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Date range selectors: start / end
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _pickStartDate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              _startDate == null
                                  ? '开始日期'
                                  : '${_startDate!.year} / ${_startDate!.month.toString().padLeft(2, '0')} / ${_startDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _pickEndDate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              _endDate == null
                                  ? '结束日期'
                                  : '${_endDate!.year} / ${_endDate!.month.toString().padLeft(2, '0')} / ${_endDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Time of day selectors for the same-day range
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _pickStartTime,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              _startTime == null
                                  ? '开始时间'
                                  : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _pickEndTime,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              _endTime == null
                                  ? '结束时间'
                                  : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logs list
            Column(
              children: _filteredLogs.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          '暂无日志',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ]
                  : _filteredLogs.map((log) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            // 未来可跳转到日志详情
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        log.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: log.status == '进行中'
                                                ? Colors.redAccent
                                                : Colors.grey.shade700,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            log.status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _priorityColor(log.priority),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            log.priority,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  log.content,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class LogEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String status;
  final String priority;

  LogEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.status,
    required this.priority,
  });
}
