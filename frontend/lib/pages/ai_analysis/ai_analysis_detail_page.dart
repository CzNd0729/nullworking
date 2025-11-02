import 'package:flutter/material.dart';

class AIAnalysisDetailPage extends StatefulWidget {
  final String mode; // 'time' or 'task'
  final Map<String, dynamic> params;

  const AIAnalysisDetailPage({
    super.key,
    required this.mode,
    required this.params,
  });

  @override
  State<AIAnalysisDetailPage> createState() => _AIAnalysisDetailPageState();
}

class _AIAnalysisDetailPageState extends State<AIAnalysisDetailPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 分析'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('输入提示词', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '例如：帮我总结该时间段内的主要舆情...',
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _onAnalyze,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('开始分析'),
            ),
          ],
        ),
      ),
    );
  }

  void _onAnalyze() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入提示词')));
      return;
    }
    setState(() => _loading = true);

    // TODO: 在这里调用 AI 接口或本地分析逻辑。当前仅模拟延迟。
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _loading = false);

    // 显示结果占位
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分析完成'),
        content: const Text('这是分析结果的占位显示。实际应显示 AI 的返回内容。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
