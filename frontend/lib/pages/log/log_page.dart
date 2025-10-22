import 'package:flutter/material.dart';
import 'create_log_page.dart';
import '../../models/log.dart';
import '../../services/business/log_business.dart';
import 'log_detail_page.dart';

// 定义视图模式枚举
enum ViewMode {
  list,
  month,
  week,
  day,
}

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final FocusNode _searchFocusNode = FocusNode();
  final LogBusiness _logBusiness = LogBusiness();
  List<Log> _allLogs = [];
  List<Log> _filteredLogs = [];
  bool _isLoading = false;

  // 视图模式状态
  ViewMode _currentViewMode = ViewMode.list;
  late TabController _tabController;

  // 月视图相关状态
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = DateTime(_endDate!.year, _endDate!.month - 1, _endDate!.day);
    _loadLogs();
    _searchFocusNode.addListener(() {
      if (!mounted) return;
      if (!_searchFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });

    // 初始化标签控制器
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(() {
      setState(() {
        _currentViewMode = ViewMode.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _forceSearchUnfocus() {
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        final matchesQuery = query.isEmpty ||
            (log.logTitle.toLowerCase().contains(query)) ||
            (log.logContent.toLowerCase().contains(query));
        return matchesQuery;
      }).toList();
    });
  }

  Future<void> _pickStartDate() async {
    _forceSearchUnfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(dialogBackgroundColor: const Color(0xFF000000)),
        child: child!,
      ),
    );

    if (picked != null) {
      if (_endDate != null && picked.isAfter(_endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('起始日期不能晚于结束日期'))
        );
        return;
      }
      setState(() => _startDate = picked);
      _loadLogs();
    }
  }

  Future<void> _pickEndDate() async {
    _forceSearchUnfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(dialogBackgroundColor: const Color(0xFF000000)),
        child: child!,
      ),
    );

    if (picked != null) {
      if (_startDate != null && picked.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('结束日期不能早于起始日期'))
        );
        return;
      }
      setState(() => _endDate = picked);
      _loadLogs();
    }
  }

  void _clearFilters() {
    _forceSearchUnfocus();
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchController.clear();
    });
    _loadLogs();
  }

  // 只在列表视图显示的筛选栏
  Widget _buildFilterBar() {
    if (_currentViewMode != ViewMode.list) {
      return const SizedBox.shrink();
    }

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
                '日志安排时间',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_startDate != null || _endDate != null || _searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Text(
                    '清除筛选',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
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
                    backgroundColor: const Color(0xFF1E1E1E),
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
        ],
      ),
    );
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      String? startFormatted = _startDate != null 
          ? "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}" 
          : null;
      String? endFormatted = _endDate != null 
          ? "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}" 
          : null;
      
      final logs = await _logBusiness.listLogs(startTime: startFormatted, endTime: endFormatted);
      setState(() {
        _allLogs = logs;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('加载日志列表失败: $e');
      setState(() {
        _allLogs = [];
        _filteredLogs = [];
      });
    } finally {
      setState(() => _isLoading = false);
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
    DateTime startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    
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
    return _filteredLogs.where((log) {
      return log.logDate.year == date.year &&
             log.logDate.month == date.month &&
             log.logDate.day == date.day;
    }).toList();
  }

  // 构建月视图
  Widget _buildMonthView() {
    final monthDays = _generateMonthDays(_currentMonth);
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
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
              ),
              Text(
                '${_currentMonth.year}年${_currentMonth.month}月',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
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
                      style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 8),
          
          // 日期网格
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weeks.length,
              itemBuilder: (context, weekIndex) {
                return Container(
                  height: 80, // 增加行高以容纳更多日志
                  child: Row(
                    children: weeks[weekIndex].map((date) {
                      final isCurrentMonth = date.month == _currentMonth.month;
                      final dayLogs = _getLogsForDate(date);
                      
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isCurrentMonth ? Colors.white24 : Colors.white10,
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
                                    color: isCurrentMonth ? Colors.white : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: date.day == DateTime.now().day && 
                                                date.month == DateTime.now().month &&
                                                date.year == DateTime.now().year 
                                        ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              
                              // 日志标识区域
                              Expanded(
                                child: dayLogs.isEmpty
                                    ? const SizedBox()
                                    : GridView.builder(
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2, // 每行显示2个日志点
                                          crossAxisSpacing: 1,
                                          mainAxisSpacing: 1,
                                          childAspectRatio: 1.5,
                                        ),
                                        itemCount: dayLogs.length,
                                        itemBuilder: (context, logIndex) {
                                          final log = dayLogs[logIndex];
                                          final color = colors[logIndex % colors.length];
                                          final firstChar = log.logTitle.isNotEmpty 
                                              ? log.logTitle[0] 
                                              : '?';
                                          
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(2),
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

  // 构建周视图
  Widget _buildWeekView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            '周视图',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 时间轴占位
          ...List.generate(6, (hour) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // 时间标签
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${8 + hour}:00',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  // 时间段内容
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _getLogForTimeSlot(hour),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 构建日视图
  Widget _buildDayView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日日志',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 时间段列表
          ...List.generate(12, (hour) {
            final time = '${8 + hour}:00';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: _hasLogForHour(hour) 
                          ? const Color(0xFF2CB7B3).withOpacity(0.1) 
                          : Colors.transparent,
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: _getLogForHour(hour),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 辅助方法：检查小时段是否有日志
  bool _hasLogForHour(int hour) {
    final targetHour = 8 + hour;
    return _filteredLogs.any((log) {
      final startTime = int.tryParse(log.startTime.split(':').first) ?? 0;
      return startTime == targetHour;
    });
  }

  // 辅助方法：获取小时段对应的日志
  Widget _getLogForHour(int hour) {
    final targetHour = 8 + hour;
    final log = _filteredLogs.firstWhere(
      (log) => int.tryParse(log.startTime.split(':').first) == targetHour,
      orElse: () => Log(
        logId: '',
        logTitle: '',
        logContent: '',
        logDate: DateTime.now(),
        startTime: '',
        endTime: '',
        logStatus: 0,
      ),
    );
    return log.logTitle.isEmpty 
        ? const SizedBox() 
        : Text(
            log.logTitle,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          );
  }

  // 辅助方法：获取时间段对应的日志
  Widget _getLogForTimeSlot(int slot) {
    final targetHour = 8 + slot;
    final log = _filteredLogs.firstWhere(
      (log) => int.tryParse(log.startTime.split(':').first) == targetHour,
      orElse: () => Log(
        logId: '',
        logTitle: '',
        logContent: '',
        logDate: DateTime.now(),
        startTime: '',
        endTime: '',
        logStatus: 0,
      ),
    );
    return log.logTitle.isEmpty 
        ? const SizedBox() 
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              log.logTitle,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _forceSearchUnfocus,
            icon: const Icon(Icons.notifications),
          ),
        ],
        // 底部添加视图切换标签
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2CB7B3),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2CB7B3),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: '列表'),
            Tab(text: '月视图'),
            Tab(text: '周视图'),
            Tab(text: '日视图'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2CB7B3),
        onPressed: () async {
          _forceSearchUnfocus();
          final newLog = await Navigator.push<Log?>(
            context,
            MaterialPageRoute(builder: (_) => const CreateLogPage()),
          );
          if (newLog != null) {
            setState(() => _allLogs.insert(0, newLog));
            _applyFilters();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索框 - 只在列表视图显示
            if (_currentViewMode == ViewMode.list)
              Column(
                children: [
                  TextField(
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    onChanged: (value) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: '按标题或日志内容搜索',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onTapOutside: (event) => _forceSearchUnfocus(),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => _forceSearchUnfocus(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            // 筛选栏 - 只在列表视图显示
            _buildFilterBar(),
            
            const SizedBox(height: 16),
            
            // 内容区域
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2CB7B3)),
                      ),
                    ),
                  )
                : _filteredLogs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          '暂无日志',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: _buildCurrentView(),
                      ),
          ],
        ),
      ),
    );
  }

  // 根据当前视图模式构建对应的展示区域
  Widget _buildCurrentView() {
    switch (_currentViewMode) {
      case ViewMode.list:
        return ListView(
          children: _filteredLogs.map((log) => _buildLogCard(log)).toList(),
        );
      case ViewMode.month:
        return _buildMonthView();
      case ViewMode.week:
        return _buildWeekView();
      case ViewMode.day:
        return _buildDayView();
    }
  }

  // 列表视图的日志卡片
  Widget _buildLogCard(Log log) {
    String statusText;
    Color statusColor;
    switch (log.logStatus) {
      case 0:
        statusText = '未完成';
        statusColor = Colors.blueAccent;
        break;
      case 1:
        statusText = '已完成';
        statusColor = Colors.green;
        break;
      default:
        statusText = '未知';
        statusColor = Colors.grey;
    }

    return FractionallySizedBox(
      widthFactor: 0.95,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: const Color(0xFF1E1E1E),
        child: InkWell(
          onTap: () async {
            _forceSearchUnfocus();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LogDetailPage(log: log))
            );
            if (result != null) _loadLogs();
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  log.logTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  log.logContent,
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '日期: ${log.logDate.year}-${log.logDate.month.toString().padLeft(2, '0')}-${log.logDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '时间: ${log.startTime} - ${log.endTime}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}