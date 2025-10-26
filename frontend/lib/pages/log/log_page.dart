import 'package:flutter/material.dart';
import 'create_log_page.dart';
import '../../models/log.dart';
import '../../services/business/log_business.dart';
import 'log_detail_page.dart';
import 'views/month_view.dart';
import 'views/week_view.dart';
import 'views/day_view.dart';

// 定义视图模式枚举
enum ViewMode { list, month, week, day }

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
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

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        final matchesQuery =
            query.isEmpty ||
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

  Widget _buildTimeFilterButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
    );
  }

  void _setToday() {
    _forceSearchUnfocus();
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now();
    });
    _loadLogs();
  }

  void _setThisWeek() {
    _forceSearchUnfocus();
    setState(() {
      final now = DateTime.now();
      _startDate = now.subtract(Duration(days: now.weekday - 1));
      _endDate = now.add(Duration(days: DateTime.daysPerWeek - now.weekday));
    });
    _loadLogs();
  }

  void _setThisMonth() {
    _forceSearchUnfocus();
    setState(() {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
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
                '时间筛选',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_startDate != null ||
                  _endDate != null ||
                  _searchController.text.isNotEmpty)
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeFilterButton('今天', _setToday),
              _buildTimeFilterButton('本周', _setThisWeek),
              _buildTimeFilterButton('本月', _setThisMonth),
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

      final logs = await _logBusiness.listLogs(
        startTime: startFormatted,
        endTime: endFormatted,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _showViewModeMenu(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: _forceSearchUnfocus,
            icon: const Icon(Icons.notifications),
          ),
        ],
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索框 - 只在列表视图显示
            if (_currentViewMode == ViewMode.list) ...[
              TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                onChanged: (value) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: '按标题或日志内容搜索',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onTapOutside: (event) => _forceSearchUnfocus(),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) => _forceSearchUnfocus(),
              ),
              const SizedBox(height: 16),
              _buildFilterBar(),
              const SizedBox(height: 16),
            ],

            // 内容区域
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2CB7B3),
                        ),
                      ),
                    )
                  : _filteredLogs.isEmpty && _currentViewMode == ViewMode.list
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          '暂无日志',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  : _buildCurrentView(),
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
        return ListView.builder(
          itemCount: _filteredLogs.length,
          itemBuilder: (context, index) => _buildLogCard(_filteredLogs[index]),
        );
// log_page.dart 中 _buildCurrentView 方法的月视图部分
case ViewMode.month:
  return MonthView(
    logs: _filteredLogs,
    currentMonth: _currentMonth,
    onMonthChanged: (newMonth) {
      setState(() {
        _currentMonth = newMonth;
        // 切换月份时，同步更新筛选范围为新月份
        _startDate = DateTime(newMonth.year, newMonth.month, 1);
        _endDate = DateTime(newMonth.year, newMonth.month + 1, 0);
      });
      _loadLogs(); // 加载新月份的日志
    },
          onDaySelected: (selectedDate) {
            setState(() {
              _currentViewMode = ViewMode.day;
              _startDate = selectedDate;
              _endDate = selectedDate;
            });
            _loadLogs();
          },
        );
      case ViewMode.week:
        return WeekView(logs: _filteredLogs);
      case ViewMode.day:
      return DayView(
        logs: _filteredLogs,
        initialDate: _startDate ?? DateTime.now(),
        // 新增：日期变更回调（关键）
        onDateChanged: (newDate) {
          setState(() {
            // 同步更新筛选条件为新日期
            _startDate = newDate;
            _endDate = newDate;
          });
          // 重新加载该日期的日志
          _loadLogs();
        },
      );
  }
}

  // 显示视图模式选择菜单
  void _showViewModeMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '视图模式',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white24),
              // 修改_showViewModeMenu中的列表视图选择逻辑
ListTile(
  leading: const Icon(Icons.list, color: Colors.white70),
  title: const Text('列表', style: TextStyle(color: Colors.white)),
  selected: _currentViewMode == ViewMode.list,
  selectedColor: const Color(0xFF2CB7B3),
  onTap: () {
    setState(() {
      _currentViewMode = ViewMode.list;
      // 切换到列表视图时，清除单天筛选（恢复为默认的时间范围）
      if (_startDate != null && _endDate != null && 
          _startDate!.isAtSameMomentAs(_endDate!)) {
        _startDate = DateTime(_endDate!.year, _endDate!.month - 1, _endDate!.day);
        _endDate = DateTime.now();
      }
    });
    _loadLogs(); // 重新加载日志
    Navigator.pop(context);
  },
),
              // log_page.dart 中 _showViewModeMenu 方法的列表项修改
ListTile(
  leading: const Icon(Icons.calendar_month, color: Colors.white70),
  title: const Text('月视图', style: TextStyle(color: Colors.white)),
  selected: _currentViewMode == ViewMode.month,
  selectedColor: const Color(0xFF2CB7B3),
  onTap: () {
    setState(() {
      _currentViewMode = ViewMode.month;
      // 切换到月视图时，重置时间范围为当前月的完整范围
      _startDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
      _endDate = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    });
    _loadLogs(); // 重新加载当月日志
    Navigator.pop(context);
  },
),
ListTile(
  leading: const Icon(Icons.calendar_view_week, color: Colors.white70),
  title: const Text('周视图', style: TextStyle(color: Colors.white)),
  selected: _currentViewMode == ViewMode.week,
  selectedColor: const Color(0xFF2CB7B3),
  onTap: () {
    setState(() {
      _currentViewMode = ViewMode.week;
      // 切换到周视图时，重置时间范围为当前周的完整范围（周一至周日）
      final now = DateTime.now();
      _startDate = now.subtract(Duration(days: now.weekday - 1)); // 周一
      _endDate = now.add(Duration(days: 7 - now.weekday)); // 周日
    });
    _loadLogs(); // 重新加载当周日志
    Navigator.pop(context);
  },
),
              ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                ),
                title: const Text('日视图', style: TextStyle(color: Colors.white)),
                selected: _currentViewMode == ViewMode.day,
                selectedColor: const Color(0xFF2CB7B3),
                onTap: () {
                  setState(() => _currentViewMode = ViewMode.day);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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

    return Center(
      child: FractionallySizedBox(
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
                MaterialPageRoute(
                  builder: (context) => LogDetailPage(logId: log.logId),
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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
      ),
    );
  }
}
