import 'package:flutter/material.dart';
import 'create_log_page.dart';
import '../../models/log.dart';
import '../../services/business/log_business.dart';
import 'log_detail_page.dart'; // 导入LogDetailPage

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

  // single date picker removed; using start/end pickers instead

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
      setState(() {
        _startDate = picked;
      });
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
      setState(() {
        _endDate = picked;
      });
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

  Widget _buildFilterBar() {
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
    setState(() {
      _isLoading = true;
    });
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
        _applyFilters(); // Apply text filter after loading new logs
      });
    } catch (e) {
      debugPrint('加载日志列表失败: $e');
      setState(() {
        _allLogs = [];
        _filteredLogs = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}), // 移除菜单按钮
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _forceSearchUnfocus();
              // TODO: Add notification functionality if needed
            },
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
            setState(() {
              _allLogs.insert(0, newLog);
            });
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
            // Search
            TextField(
              focusNode: _searchFocusNode,
              controller: _searchController,
              onChanged: (value) => _applyFilters(), // Call setState to re-evaluate filter conditions
              decoration: InputDecoration(
                hintText: '按标题或日志内容搜索',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), // Changed from 12 to 8
                  borderSide: BorderSide.none,
                ),
              ),
              onTapOutside: (event) {
                _forceSearchUnfocus();
              },
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                _forceSearchUnfocus();
              },
            ),
            const SizedBox(height: 16),

            _buildFilterBar(), // 使用新的筛选栏 Widget

            const SizedBox(height: 16),

            // Logs list
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2CB7B3)),
                      ),
                    ),
                  )
                : Column(
                    children: _filteredLogs.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Text(
                                '暂无日志',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ]
                        : _filteredLogs.map((log) {
                            return _buildLogCard(log);
                          }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

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
        color: const Color(0xFF1E1E1E), // 设置卡片背景色
        child: InkWell(
          onTap: () async {
            _forceSearchUnfocus();
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => LogDetailPage(log: log)));
            if (result != null) {
              _loadLogs(); // 刷新日志列表
            }
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
