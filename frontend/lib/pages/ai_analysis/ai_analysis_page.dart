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
            // 新建分析按钮
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const AIAnalysisDetailPage(mode: 'time', params: {}),
                  ),
                );
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
                    const Text('新建AI分析', style: TextStyle(fontSize: 16)),
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
