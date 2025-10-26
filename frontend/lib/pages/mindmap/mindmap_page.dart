import 'package:flutter/material.dart';
import 'package:nullworking/services/business/mindmap_business.dart';
import 'package:nullworking/models/log.dart';
import 'package:nullworking/models/task.dart';

class MindMapPage extends StatefulWidget {
  const MindMapPage({super.key});

  @override
  State<MindMapPage> createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  // 存储当天数据（日志+任务）
  List<Log> _todayLogs = [];
  List<Task> _todayTasks = [];
  String _companyImportant = '加载中...';
  String _personalImportant = '加载中...';
  bool _isLoading = true;
  String? _error;

  final MindMapBusiness _mindMapBusiness = MindMapBusiness();

  @override
  void initState() {
    super.initState();
    _fetchTodayData(); // 切换为获取真实数据的方法
  }

  // 新增：获取当天日志和任务数据
  Future<void> _fetchTodayData() async {
    final data = await _mindMapBusiness.fetchTodayData();
    setState(() {
      if (data.containsKey('error')) {
        _error = data['error'];
      } else {
        _todayLogs = data['todayLogs'] ?? [];
        _todayTasks = data['todayTasks'] ?? [];
        _companyImportant = data['companyImportant'] ?? '无数据';
        _personalImportant = data['personalImportant'] ?? '无数据';
      }
      _isLoading = false;
    });
  }

  // 重构：通用卡片组件（支持列表数据展示）
  Widget _buildCard({
    required String title,
    required List<Widget> contentWidgets,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            // 内容区域：如果有数据则展示列表，否则显示提示
            Expanded(
              child: contentWidgets.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: contentWidgets,
                      ),
                  ),
          ), // 确保Expanded的括号闭合
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导图'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('加载失败：$_error'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text(
                          '项目导图',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
                          children: [
                            // 公司重要事项（模拟数据）
                            _buildCard(
                              title: '公司重要事项',
                              contentWidgets: [Text(_companyImportant)],
                            ),
                            // 公司任务调度（展示当天未到截止日期的任务）
                            _buildCard(
                              title: '公司任务调度',
                              contentWidgets: _todayTasks
                                  .map((task) => _buildTaskItem(task))
                                  .toList(),
                            ),
                            // 个人重要事项（模拟数据）
                            _buildCard(
                              title: '个人重要事项',
                              contentWidgets: [Text(_personalImportant)],
                            ),
                            // 个人日志（展示当天的日志）
                            _buildCard(
                              title: '个人日志',
                              contentWidgets: _todayLogs
                                  .map((log) => _buildLogItem(log))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // 新增：任务列表项组件
  Widget _buildTaskItem(Task task) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.taskTitle,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '截止：${task.deadline.year}-${task.deadline.month}-${task.deadline.day}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // 新增：日志列表项组件
  Widget _buildLogItem(Log log) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.logTitle,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '时间：${log.startTime} - ${log.endTime}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}