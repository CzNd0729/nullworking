// mindmap_page.dart
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
    _fetchTodayData();
  }

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
            // 内容区域：确保内容可以完整展示
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
            ),
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
                  // 减小整体内边距，让内容更贴近边缘
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // 移除"项目导图"标题
                      Expanded(
                        // 使用Column而不是GridView，让每个模块垂直排列并占满空间
                        child: Column(
                          children: [
                            // 第一行：公司重要事项和公司任务调度
                            Expanded(
                              child: Row(
                                children: [
                                  // 公司重要事项
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: _buildCard(
                                        title: '公司重要事项',
                                        contentWidgets: [Text(_companyImportant)],
                                      ),
                                    ),
                                  ),
                                  // 公司任务调度
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: _buildCard(
                                        title: '公司任务调度',
                                        contentWidgets: _todayTasks
                                            .map((task) => _buildTaskItem(task))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 第二行：个人重要事项和个人日志
                            Expanded(
                              child: Row(
                                children: [
                                  // 个人重要事项
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: _buildCard(
                                        title: '个人重要事项',
                                        contentWidgets: [Text(_personalImportant)],
                                      ),
                                    ),
                                  ),
                                  // 个人日志
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: _buildCard(
                                        title: '个人日志',
                                        contentWidgets: _todayLogs
                                            .map((log) => _buildLogItem(log))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

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

  Widget _buildLogItem(Log log) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          log.logTitle,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '时间：${log.startTime} - ${log.endTime}',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        // 新增：日志内容预览（可选，根据需求决定是否添加）
        if (log.logContent.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            log.logContent,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),
  );
}}