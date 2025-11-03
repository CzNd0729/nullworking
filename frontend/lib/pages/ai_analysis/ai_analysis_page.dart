import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nullworking/models/ai_analysis_result.dart';
import 'package:nullworking/services/business/ai_analysis_business.dart';
import 'create_analysis_request.dart';

class AIAnalysisPage extends StatefulWidget {
  const AIAnalysisPage({super.key});

  @override
  State<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends State<AIAnalysisPage> {
  final AiAnalysisBusiness _aiAnalysisBusiness = AiAnalysisBusiness();
  List<AiAnalysisResult>? _analysisList;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysisHistory();
  }

  Future<void> _loadAnalysisHistory() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _aiAnalysisBusiness.getResultList();
    if (mounted) {
      setState(() {
        _analysisList = result;
        _isLoading = false;
      });
    }
  }

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
                        const CreateAnalysisRequestPage(mode: 'time', params: {}),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _analysisList == null || _analysisList!.isEmpty
                      ? const Center(child: Text('没有历史分析记录'))
                      : RefreshIndicator(
                          onRefresh: _loadAnalysisHistory,
                          child: ListView.builder(
                            itemCount: _analysisList!.length,
                            itemBuilder: (context, index) {
                              return _buildAnalysisItem(_analysisList![index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(AiAnalysisResult analysisResult) {
    String statusText;
    Color statusColor;
    switch (analysisResult.status) {
      case 0:
        statusText = '处理中';
        statusColor = Colors.cyan;
        break;
      case 1:
        statusText = '完成';
        statusColor = Colors.blue;
        break;
      case 2:
        statusText = '失败';
        statusColor = Colors.red;
        break;
      default:
        statusText = '未知';
        statusColor = Colors.grey;
    }

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
              const Icon(Icons.history, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  analysisResult.prompt,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
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
                DateFormat('yyyy年MM月dd日 HH:mm')
                    .format(analysisResult.analysisTime),
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateAnalysisRequestPage(
                        resultId: analysisResult.resultId,
                        mode: 'view',
                        params: const {},
                      ),
                    ),
                  );
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
