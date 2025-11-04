import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class AIAnalysisResultPage extends StatelessWidget {
  AIAnalysisResultPage({super.key});

  // ---------- Mock data (你给的完整数据) ----------
  final Map<String, dynamic> mockData = {
    "code": 200,
    "message": "success",
    "data": {
      "constructive_suggestions": [
        {
          "id": "sug-001",
          "severity": "medium",
          "title": "测试自动创建日志任务需补充执行计划",
          "description":
              "\"测试自动创建日志\"任务仅接收任务（logDate10-30），未生成后续测试用例、执行步骤或验证标准文档，建议补充\"测试用例设计\"与\"自动化测试脚本开发\"环节日志，明确任务闭环流程",
          "impact": "可降低后续测试环节返工率，提升任务完成度至100%"
        },
        {
          "id": "sug-002",
          "severity": "low",
          "title": "日志管理模块联调阶段优化建议",
          "description":
              "联调与性能优化（logId121）中仅优化列表查询索引，未记录具体索引优化前后的性能指标（如响应时间对比），建议补充\"性能指标基线记录\"与\"优化效果验证\"说明，为后续同类任务积累优化经验",
          "impact": "可标准化性能优化流程，提升技术方案可追溯性"
        }
      ],
      "keyword_statistics": [
        {"keyword": "日志管理", "count": 14, "percentage": 35},
        {"keyword": "接口开发", "count": 8, "percentage": 20},
        {"keyword": "联调", "count": 5, "percentage": 12},
        {"keyword": "权限模块", "count": 3, "percentage": 7},
        {"keyword": "测试", "count": 4, "percentage": 10},
        {"keyword": "需求分析", "count": 2, "percentage": 5},
        {"keyword": "数据库设计", "count": 2, "percentage": 5},
        {"keyword": "任务完成", "count": 1, "percentage": 3}
      ],
      "summary":
          "邹匀翻本周围绕\"日志管理模块\"完成2个核心任务：完成日志管理模块后端开发（task86），实现从需求分析到上线交付的全流程闭环（taskProgress从14%提升至100%）；完成前后端联调验证（task88），达成任务进度100%。同时接收\"测试自动创建日志\"任务（task90）并处于初始状态。工作时长分布不均，10-30日达32小时，日均工作时长14.7小时，任务覆盖需求分析、接口开发、权限控制、联调测试等全链路。本周核心进展为\"日志管理模块后端开发\"任务完成度100%，建议补充测试自动创建日志任务的执行计划与性能优化数据记录。",
      "frontend_chart_data": [
        {
          "selected_chart_type": "折线图（任务进度推进）",
          "chart_config": {
            "x_axis": "日期",
            "y_axis": "任务完成度（%）",
            "data": [
              {"date": "10-27", "progress": 14},
              {"date": "10-28", "progress": 21},
              {"date": "10-29", "progress": 59},
              {"date": "10-30", "progress": 81},
              {"date": "11-01", "progress": 89},
              {"date": "11-02", "progress": 100}
            ],
            "additional_config": {
              "line_color": "#4285F4",
              "fill": "rgba(66, 133, 244, 0.1)",
              "display_labels": true
            }
          }
        },
        {
          "selected_chart_type": "柱状图（每日工作时长）",
          "chart_config": {
            "x_axis": "日期",
            "y_axis": "工作时长（小时）",
            "data": [
              {"date": "10-27", "hours": 16},
              {"date": "10-28", "hours": 16},
              {"date": "10-29", "hours": 24},
              {"date": "10-30", "hours": 32},
              {"date": "10-31", "hours": 8},
              {"date": "11-01", "hours": 8},
              {"date": "11-02", "hours": 16}
            ],
            "additional_config": {
              "color_scheme": [
                "#34A853",
                "#4285F4",
                "#EA4335",
                "#FBBC05",
                "#9C27B0"
              ],
              "display_labels": true
            }
          }
        },
        {
          "selected_chart_type": "饼图（任务类型占比）",
          "chart_config": {
            "name": "任务类型",
            "value": "耗时占比（%）",
            "data": [
              {"task_type": "后端开发", "proportion": 45},
              {"task_type": "联调测试", "proportion": 30},
              {"task_type": "环境确认", "proportion": 15},
              {"task_type": "需求分析", "proportion": 10}
            ],
            "additional_config": {
              "color_scheme": ["#4285F4", "#34A853", "#EA4335", "#FBBC05"],
              "display_labels": true
            }
          }
        }
      ]
    }
  };

  // ---------- helpers ----------
  Color _parseRgbaColor(String? rgbaStr) {
    if (rgbaStr == null) return Colors.transparent;
    final match =
        RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*(\d+\.?\d*)\)').firstMatch(rgbaStr);
    if (match != null) {
      return Color.fromRGBO(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
        double.parse(match.group(4)!),
      );
    }
    return Colors.transparent;
  }

  double _getMaxValue(List<dynamic>? values) {
    if (values == null || values.isEmpty) return 0.0;
    final nums = values.where((e) => e != null).map((e) => (e as num).toDouble()).toList();
    if (nums.isEmpty) return 0.0;
    return nums.reduce((a, b) => a > b ? a : b);
  }

  // ---------- UI widgets ----------
  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    // 明确类型并提供默认值
    final String severityKey = (s['severity'] as String?) ?? 'unknown';
    final Map<String, dynamic> severityLookup = {
      'high': {'color': Colors.red, 'text': '高'},
      'medium': {'color': Colors.orange, 'text': '中'},
      'low': {'color': Colors.green, 'text': '低'},
    };
    final Map<String, dynamic> severityVal =
        severityLookup[severityKey] ?? {'color': Colors.grey, 'text': '未知'};
    final Color sevColor = severityVal['color'] as Color;
    final String sevText = severityVal['text'] as String;

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(
                (s['title'] as String?) ?? '无标题',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: sevColor, borderRadius: BorderRadius.circular(4)),
              child: Text(sevText, style: const TextStyle(color: Colors.white, fontSize: 12)),
            )
          ]),
          const SizedBox(height: 8),
          Text('描述：${(s['description'] as String?) ?? ''}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text('影响：${(s['impact'] as String?) ?? ''}', style: const TextStyle(color: Colors.white70)),
        ]),
      ),
    );
  }

  Widget _buildLineChart(Map<String, dynamic> cfg) {
    final data = (cfg['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final String lineColorHex = (cfg['additional_config']?['line_color'] as String?) ?? '#4285F4';
    final String fillStr = (cfg['additional_config']?['fill'] as String?) ?? 'rgba(0,0,0,0)';
    final Color lineColor = Color(int.parse(lineColorHex.replaceFirst('#', '0xFF')));
    final Color fillColor = _parseRgbaColor(fillStr);

    final maxProgress = _getMaxValue(data.map((e) => e['progress']).toList());
    final maxY = (maxProgress <= 0) ? 100.0 : maxProgress * 1.1;

    return SizedBox(
      height: 300,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData:  FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, meta) {
              return Text('${v.toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12));
            }),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i >= 0 && i < data.length && i % 1 == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[i]['date'] as String? ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              final x = e.key.toDouble();
              final y = (e.value['progress'] as num).toDouble();
              return FlSpot(x, y);
            }).toList(),
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: fillColor),
          ),
        ],
      )),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> cfg) {
    final data = (cfg['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final List<String> colorsHex = (cfg['additional_config']?['color_scheme'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['#34A853', '#4285F4', '#EA4335', '#FBBC05', '#9C27B0'];

    final maxHours = _getMaxValue(data.map((e) => e['hours']).toList());
    final maxY = (maxHours <= 0) ? 10.0 : maxHours * 1.1;

    return SizedBox(
      height: 300,
      child: BarChart(BarChartData(
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData:  FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, meta) {
            return Text('${v.toInt()}h', style: const TextStyle(color: Colors.white70, fontSize: 12));
          })),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i >= 0 && i < data.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(data[i]['date'] as String? ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              );
            }
            return const SizedBox.shrink();
          })),
        ),
        barGroups: data.asMap().entries.map((e) {
          final colorHex = colorsHex[e.key % colorsHex.length];
          final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(
              toY: (e.value['hours'] as num).toDouble(),
              color: color,
              width: 20,
              borderRadius: BorderRadius.circular(6),
            )
          ]);
        }).toList(),
      )),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> cfg) {
    final data = (cfg['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final List<String> colorsHex = (cfg['additional_config']?['color_scheme'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['#4285F4', '#34A853', '#EA4335', '#FBBC05'];

    final total = data.fold<int>(0, (sum, e) => sum + ((e['proportion'] as num).toInt()));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        SizedBox(
          height: 220,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 36,
            borderData: FlBorderData(show: false),
            sections: data.asMap().entries.map((entry) {
              final item = entry.value;
              final String hex = colorsHex[entry.key % colorsHex.length];
              final Color color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
              return PieChartSectionData(
                color: color,
                value: (item['proportion'] as num).toDouble(),
                title: "${item['proportion']}%",
                radius: 60,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList(),
          )),
        ),
        const SizedBox(height: 12),
        Column(children: data.asMap().entries.map((entry) {
          final item = entry.value;
          final String hex = colorsHex[entry.key % colorsHex.length];
          final Color color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 12, height: 12, color: color),
                const SizedBox(width: 8),
                Text(item['task_type'] as String? ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
              Text("${item['proportion']}%", style: const TextStyle(color: Colors.white54)),
            ]),
          );
        }).toList()),
        const SizedBox(height: 8),
        Text("总计 $total%", style: const TextStyle(color: Colors.white54))
      ]),
    );
  }

  Widget _buildKeywordPane(List<dynamic> keywords) {
    final kw = keywords.cast<Map<String, dynamic>>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("关键词统计", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...kw.map((k) {
          final double intensity = ((k['percentage'] as num?) ?? 0) / 100.0;
          final Color keywordColor = Color.fromRGBO(50, 150, 255, (0.5 + intensity * 0.5).clamp(0.0, 1.0));
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(k['keyword'] as String? ?? '未知', style: TextStyle(color: keywordColor, fontSize: 14, fontWeight: FontWeight.w500)),
              Text("${k['count']} • ${k['percentage']}%", style: const TextStyle(color: Colors.white54)),
            ]),
          );
        }).toList()
      ]),
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final data = (mockData['data'] ?? {}) as Map<String, dynamic>;
    final suggestions = (data['constructive_suggestions'] as List<dynamic>?) ?? [];
    final keywords = (data['keyword_statistics'] as List<dynamic>?) ?? [];
    final charts = (data['frontend_chart_data'] as List<dynamic>?) ?? [];
    final summary = (data['summary'] as String?) ?? '暂无分析概述';

    return Scaffold(
      appBar: AppBar(title: const Text('AI分析结果')),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 建议
          const Text('建设性建议', style: TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 12),
          ...suggestions.map((s) => _buildSuggestionCard(Map<String, dynamic>.from(s as Map))).toList(),

          const SizedBox(height: 18),
          // 关键词（右侧简单列表样式）
          _buildKeywordPane(keywords),

          const SizedBox(height: 18),
          // 概述
          const Text('概述', style: TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 8),
          Card(color: Colors.grey[850], child: Padding(padding: const EdgeInsets.all(12), child: Text(summary, style: const TextStyle(color: Colors.white70, height: 1.5)))),

          const SizedBox(height: 18),
          // 数据图表（按 mock 数据顺序渲染）
          const Text('数据图表', style: TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 12),
          ...charts.map<Widget>((c) {
            final item = Map<String, dynamic>.from(c as Map);
            final type = (item['selected_chart_type'] as String?) ?? '';
            final cfg = (item['chart_config'] as Map<String, dynamic>?) ?? {};
            if (type.contains('折线')) return _buildLineChart(cfg);
            if (type.contains('柱状')) return _buildBarChart(cfg);
            if (type.contains('饼图')) return _buildPieChart(cfg);
            return const SizedBox.shrink();
          }).toList(),
        ]),
      ),
    );
  }
}
