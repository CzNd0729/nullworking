import 'package:flutter/material.dart';
import 'ai_analysis_detail_page.dart';

class AIAnalysisPage extends StatelessWidget {
  const AIAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI分析日志'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 处理通知
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 选择日志按钮 -> 弹出选择框
            InkWell(
              onTap: () {
                _showChooseModeDialog(context);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.note_add_outlined),
                    ),
                    const SizedBox(width: 16),
                    const Text('选择需要分析的日志', style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 历史分析标题
            const Text(
              '历史AI分析',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            // 历史分析列表
            Expanded(
              child: ListView(
                children: [
                  _buildAnalysisItem(
                    icon: Icons.trending_up,
                    title: '社交媒体趋势分析 - 2023',
                    time: '2023年10月26日 14:30',
                    status: '完成',
                    statusColor: Colors.blue,
                  ),
                  _buildAnalysisItem(
                    icon: Icons.bar_chart,
                    title: '市场情绪洞察',
                    time: '2023年10月25日 09:15',
                    status: '处理中',
                    statusColor: Colors.cyan,
                  ),
                  _buildAnalysisItem(
                    icon: Icons.sentiment_satisfied_alt,
                    title: '用户反馈情感分析',
                    time: '2023年10月24日 18:00',
                    status: '完成',
                    statusColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChooseModeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('选择分析方式'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                _showTimeAnalysisDialog(context);
              },
              child: const Text('按时间分析'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                _showTaskAnalysisDialog(context);
              },
              child: const Text('按任务分析'),
            ),
          ],
        );
      },
    );
  }

  void _showTimeAnalysisDialog(BuildContext context) async {
    DateTime? startDate;
    DateTime? endDate;
    String selectedPerson = '全部';
    final people = ['全部', '张三', '李四', '王五'];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('按时间分析'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => startDate = picked);
                      },
                      child: Text(
                        startDate == null
                            ? '选择起始时间'
                            : '起始：${startDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => endDate = picked);
                      },
                      child: Text(
                        endDate == null
                            ? '选择截止时间'
                            : '截止：${endDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('选择人员'),
                    DropdownButton<String>(
                      value: selectedPerson,
                      items: people
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedPerson = v ?? '全部'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    // 确认并跳转
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AIAnalysisDetailPage(
                          mode: 'time',
                          params: {
                            'start': startDate?.toIso8601String(),
                            'end': endDate?.toIso8601String(),
                            'person': selectedPerson,
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTaskAnalysisDialog(BuildContext context) async {
    // 示例任务列表
    final tasks = [
      {'id': 't1', 'title': '发布社交媒体报告'},
      {'id': 't2', 'title': '市场调研'},
      {'id': 't3', 'title': '用户反馈整理'},
    ];
    String? selectedTaskId;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('按任务分析'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final t = tasks[index];
                    return RadioListTile<String>(
                      title: Text(t['title']!),
                      value: t['id']!,
                      groupValue: selectedTaskId,
                      onChanged: (v) => setState(() => selectedTaskId = v),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedTaskId == null) {
                      // 如果未选择，提示并不关闭
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('请选择一个任务')));
                      return;
                    }
                    final task = tasks.firstWhere(
                      (t) => t['id'] == selectedTaskId,
                    );
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AIAnalysisDetailPage(
                          mode: 'task',
                          params: {
                            'taskId': task['id'],
                            'title': task['title'],
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAnalysisItem({
    required IconData icon,
    required String title,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 查看详情
                },
                child: const Text('查看详情'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
