// mindmap_page.dart
import 'package:flutter/material.dart';
import '../../services/business/mindmap_business.dart';
import 'company_top10_page.dart';
import 'personal_top10_page.dart';
import '../../models/log.dart';
import '../../models/task.dart';
import '../../models/item.dart';
import '../../services/api/item_api.dart';
import '../task/task_detail_page.dart';  // 新增：导入任务详情页
import '../log/log_detail_page.dart';    // 新增：导入日志详情页
import 'package:nullworking/pages/notification/notification_list_page.dart'; // 新增导入
import '../../widgets/notification_icon_with_badge.dart'; // 新增导入

class MindMapPage extends StatefulWidget {
  const MindMapPage({super.key});

  @override
  State<MindMapPage> createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  // 存储当天数据（日志+任务+重要事项）
  List<Log> _todayLogs = [];
  List<Task> _todayTasks = [];
  List<Item> _companyImportantList = [];
  List<Item> _personalImportantList = [];
  bool _isLoading = true;
  String? _error;

  final MindMapBusiness _mindMapBusiness = MindMapBusiness();
  final ItemApi _itemApi = ItemApi();

  @override
  void initState() {
    super.initState();
    _fetchTodayData();
  }

  Future<void> _fetchTodayData() async {
    try {
      final data = await _mindMapBusiness.fetchTodayData();
      final companyItems = await _itemApi.getItems(isCompany: "1");
      final personalItems = await _itemApi.getItems(isCompany: "0");

      setState(() {
        if (data.containsKey('error')) {
          _error = data['error'];
        } else {
          _todayLogs = data['todayLogs'] ?? [];
          _todayTasks = data['todayTasks'] ?? [];
          _companyImportantList = companyItems?.items ?? [];
          _personalImportantList = personalItems?.items ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildCard({
    required String title,
    required List<Widget> contentWidgets,
    VoidCallback? onTap,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
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
                        child: Column(children: contentWidgets),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导图'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const NotificationIconWithBadge(), // Use the new widget
        ],
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
                                        contentWidgets: _companyImportantList
                                            .map(
                                              (item) => _buildImportantItem(item),
                                            )
                                            .toList(),
                                        onTap: () {
                                          // 点击进入公司十大重要事项（只读）
                                          if (!mounted) return;
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CompanyTop10Page(),
                                            ),
                                          );
                                        },
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
                                        contentWidgets: _personalImportantList
                                            .map(
                                              (item) => _buildImportantItem(item),
                                            )
                                            .toList(),
                                        onTap: () async {
                                          // 点击进入个人十大重要事项（可排序）
                                          if (!mounted) return;
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const PersonalTop10Page(),
                                            ),
                                          );
                                        },
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

  // 修改：添加任务项点击事件，跳转至任务详情页
  Widget _buildTaskItem(Task task) {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailPage(task: task),
          ),
        );
      },
      child: Container(
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
      ),
    );
  }

  // 修改：添加日志项点击事件，跳转至日志详情页
  Widget _buildLogItem(Log log) {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LogDetailPage(logId: log.logId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
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
      ),
    );
  }

  Widget _buildImportantItem(Item item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${item.displayOrder}.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (item.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.content,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}