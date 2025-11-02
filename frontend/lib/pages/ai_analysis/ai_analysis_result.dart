import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AIAnalysisResultPage extends StatelessWidget {
  AIAnalysisResultPage({super.key});

  final Map<String, dynamic> mockData = {
    "code": 200,
    "message": "success",
    "data": {
      "constructive_suggestions": [
        {
          "id": "sug-001",
          "severity": "medium",
          "title": "日志状态与任务进度一致性优化",
          "description": "部分任务进度已达100%，但对应的日志条目状态仍为未完成（如task86的单元测试、联调优化及上线部署日志，task88的所有日志），建议及时更新日志状态以准确反映任务完成情况。",
          "impact": "可提升进度跟踪的准确性，避免任务状态混淆，确保团队对任务进展的认知一致。"
        },
        {
          "id": "sug-002",
          "severity": "low",
          "title": "任务收尾工作优先级管理",
          "description": "两个核心任务均已接近完成（进度达100%），但收尾工作（如测试、部署、文档交付）尚未完成，建议合理排序收尾任务，优先闭环高优先级任务。",
          "impact": "可加快任务交付速度，提高工作闭环效率，减少未完成任务积压。"
        }
      ],
      "keyword_statistics": [
        {
          "keyword": "接口",
          "count": 8,
          "percentage": 50.0
        },
        {
          "keyword": "开发",
          "count": 6,
          "percentage": 37.5
        },
        {
          "keyword": "权限",
          "count": 3,
          "percentage": 18.75
        }
      ],
      "summary": "邹匀翻本周主要负责日志管理模块开发（task86）和前端联调验证（task88）两大任务。日志管理模块任务中，他完成了需求分析、数据库设计、核心API开发、权限集成等关键环节，进度达100%；前端联调任务完成了环境确认、数据验证、交互优化等工作，进度同样达100%。整体工作效率较高，覆盖从需求到开发的全流程，但存在日志状态与任务进度不一致的问题，部分已完成工作未及时更新日志状态，且收尾工作（如测试、部署）尚未闭环。建议后续优化日志记录规范性，合理安排收尾工作优先级，提升任务交付效率。",
      "frontend_chart_data": {
        "category_chart": {
          "x_axis": ["2025-10-27", "2025-10-28", "2025-10-29", "2025-10-30", "2025-10-31", "2025-11-01", "2025-11-02", "2025-11-03"],
          "y_axis": "每日进度增量（%）",
          "data": [27, 18, 47, 34, 20, 8, 40, 6]
        }
      }
    }
  };

  String _mapSeverityToChinese(String severity) {
    switch (severity) {
      case 'high': return '高';
      case 'medium': return '中';
      case 'low': return '低';
      default: return severity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> suggestions = mockData['data']['constructive_suggestions'];
    final List<dynamic> keywords = mockData['data']['keyword_statistics'];
    final Map<String, dynamic> chartData = mockData['data']['frontend_chart_data']['category_chart'];
    final String summary = mockData['data']['summary']; // 提取概述内容

    return Scaffold(
      appBar: AppBar(
        title: const Text('分析结果'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 建设性建议
              const Text(
                '建设性建议',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...suggestions.map((suggestion) {
                Color severityColor;
                switch (suggestion['severity']) {
                  case 'high': severityColor = Colors.red; break;
                  case 'medium': severityColor = Colors.orange; break;
                  case 'low': severityColor = Colors.green; break;
                  default: severityColor = Colors.grey;
                }

                return Card(
                  color: Colors.grey[800],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              suggestion['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: severityColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _mapSeverityToChinese(suggestion['severity']),
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('描述：${suggestion['description']}', style: const TextStyle(fontSize: 15, color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text('影响：${suggestion['impact']}', style: const TextStyle(fontSize: 15, color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 32),

              // 2. 关键词统计
              const Text(
                '关键词统计',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...keywords.map((keyword) {
                final double intensity = keyword['percentage'] / 100;
                final Color keywordColor = Color.fromRGBO(50, 150, 255, 0.5 + intensity * 0.5);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        keyword['keyword'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: keywordColor),
                      ),
                      Row(
                        children: [
                          Text('出现次数：${keyword['count']}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 20),
                          Text('占比：${keyword['percentage']}%', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 32),

              // 3. 柱状图
              const Text(
                '每日进度增量',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    groupsSpace: 12,
                    maxY: 50,
                    barTouchData: BarTouchData(enabled: true),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40, // 足够宽度避免换行
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final date = chartData['x_axis'][value.toInt()];
                            return Text(
                              date.split('-').last,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < chartData['data'].length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: chartData['data'][i].toDouble(),
                              color: Colors.blueAccent,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  chartData['y_axis'],
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 4. 概述（新增部分，放在图表下方）
              const Text(
                '概述',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.grey[800],
child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Text(
      summary,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.white70,
        height: 1.5, // 行高优化，提升可读性
                  ),
                  textAlign: TextAlign.justify, // 两端对齐
                ),
              ),
          )],
          ),
        ),
      ),
    );
  }
}