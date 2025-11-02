import 'package:flutter/material.dart';
import 'ai_analysis_result.dart'; // 导入结果页面

class AIAnalysisPage extends StatelessWidget {
  const AIAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI分析'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 原主页面内容（保持不变）
            const Text(
              'AI分析页面',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            
            // 新增跳转按钮，点击跳转到结果页
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 跳转到分析结果页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  AIAnalysisResultPage(),
                  ),
                );
              },
              child: const Text('查看分析结果'),
            ),
          ],
        ),
      ),
    );
  }
}