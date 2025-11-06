import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:nullworking/models/ai_analysis_result.dart';
import 'package:nullworking/services/business/ai_analysis_business.dart';

class AIAnalysisResultPage extends StatefulWidget {
  final String resultId;

  const AIAnalysisResultPage({super.key, required this.resultId});

  @override
  State<AIAnalysisResultPage> createState() => _AIAnalysisResultPageState();
}

class _AIAnalysisResultPageState extends State<AIAnalysisResultPage> {
  final AiAnalysisBusiness _aiAnalysisBusiness = AiAnalysisBusiness();
  AiAnalysisResult? _analysisResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysisResult();
  }

  Future<void> _loadAnalysisResult() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _aiAnalysisBusiness.getResultById(widget.resultId);
    if (mounted) {
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    }
  }

  Color _parseRgbaColor(String? rgbaStr) {
    if (rgbaStr == null) return Colors.transparent;
    final match = RegExp(
      r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*(\d+\.?\d*)\)',
    ).firstMatch(rgbaStr);
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
    final nums = values
        .where((e) => e != null)
        .map((e) => (e as num).toDouble())
        .toList();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (s['title'] as String?) ?? '无标题',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: sevColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    sevText,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '描述：${(s['description'] as String?) ?? ''}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              '影响：${(s['impact'] as String?) ?? ''}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(Map<String, dynamic> cfg) {
    final data =
        (cfg['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final String lineColorHex =
        (cfg['additional_config']?['line_color'] as String?) ?? '#4285F4';
    final String fillStr =
        (cfg['additional_config']?['fill'] as String?) ?? 'rgba(0,0,0,0)';
    final Color lineColor = Color(
      int.parse(lineColorHex.replaceFirst('#', '0xFF')),
    );
    final Color fillColor = _parseRgbaColor(fillStr);

    final maxYValue = _getMaxValue(data.map((e) => e['y']).toList());
    final maxY = (maxYValue <= 0) ? 100.0 : maxYValue * 1.2; // 顶部预留20%空间

    // 计算图表宽度：每个数据点占用80像素
    // 额外添加一个空列(+1)以确保最后日期标签完整显示
    final chartWidth = ((data.length + 1) * 80.0).clamp(300.0, double.infinity);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '趋势图',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: data.length.toDouble(), // X轴多显示一个位置
                      minY: 0,
                      maxY: maxY,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, meta) {
                              // 只显示实际数据范围内的Y轴标签，隐藏预留空间的标签
                              if (v > maxYValue) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                '${v.toInt()}',
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
                            interval: 1,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              if (i >= 0 && i < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    data[i]['x'] as String? ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((e) {
                            final x = e.key.toDouble();
                            final y = (e.value['y'] as num? ?? 0).toDouble();
                            return FlSpot(x, y);
                          }).toList(),
                          isCurved: true,
                          color: lineColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: fillColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> cfg) {
    final data =
        (cfg['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final List<String> colorsHex =
        (cfg['additional_config']?['color_scheme'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['#34A853', '#4285F4', '#EA4335', '#FBBC05', '#9C27B0'];

    final maxYValue = _getMaxValue(data.map((e) => e['y']).toList());
    final maxY = (maxYValue <= 0) ? 10.0 : maxYValue * 1.2; // 顶部预留20%空间

    // 计算图表宽度：每个柱子占用80像素
    // 额外添加一个空列(+1)以确保最后标签完整显示
    final chartWidth = ((data.length + 1) * 80.0).clamp(300.0, double.infinity);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '柱状图',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, meta) {
                              // 只显示实际数据范围内的Y轴标签，隐藏预留空间的标签
                              if (v > maxYValue) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                '${v.toInt()}h',
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
                            interval: 1,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              if (i >= 0 && i < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    data[i]['x'] as String? ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      barGroups: data.asMap().entries.map((e) {
                        final colorHex = colorsHex[e.key % colorsHex.length];
                        final color = Color(
                          int.parse(colorHex.replaceFirst('#', '0xFF')),
                        );
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: (e.value['y'] as num? ?? 0).toDouble(),
                              color: color,
                              width: 20,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> cfg) {
    final data =
        (cfg['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final List<String> colorsHex =
        (cfg['additional_config']?['color_scheme'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['#4285F4', '#34A853', '#EA4335', '#FBBC05'];

    final total = data.fold<int>(
      0,
      (sum, e) => sum + ((e['y'] as num? ?? 0).toInt()),
    ); // 更改为使用 'y' 字段

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '饼图',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  borderData: FlBorderData(show: false),
                  sections: data.asMap().entries.map((entry) {
                    final item = entry.value;
                    final String hex = colorsHex[entry.key % colorsHex.length];
                    final Color color = Color(
                      int.parse(hex.replaceFirst('#', '0xFF')),
                    );
                    return PieChartSectionData(
                      color: color,
                      value: (item['value'] as num? ?? 0).toDouble(),
                      title: "${item['value']}%",
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: data.asMap().entries.map((entry) {
                final item = entry.value;
                final String hex = colorsHex[entry.key % colorsHex.length];
                final Color color = Color(
                  int.parse(hex.replaceFirst('#', '0xFF')),
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, color: color),
                          const SizedBox(width: 8),
                          Text(
                            item['name'] as String? ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${item['value']}%",
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text("总计 $total%", style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordPane(List<dynamic> keywords) {
    final kw = keywords.cast<Map<String, dynamic>>();
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "关键词统计",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...kw.map((k) {
              final double intensity = ((k['percentage'] as num?) ?? 0) / 100.0;
              final Color keywordColor = Color.fromRGBO(
                50,
                150,
                255,
                (0.5 + intensity * 0.5).clamp(0.0, 1.0),
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      k['keyword'] as String? ?? '未知',
                      style: TextStyle(
                        color: keywordColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${k['count']} • ${k['percentage']}%",
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI分析结果')),
        backgroundColor: Colors.grey[900],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_analysisResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI分析结果')),
        backgroundColor: Colors.grey[900],
        body: const Center(child: Text('未能加载分析结果')),
      );
    }
    final data = _analysisResult!.content as Map<String, dynamic>? ?? {};
    final suggestions =
        (data['constructive_suggestions'] as List<dynamic>?) ?? [];
    final keywords = (data['keyword_statistics'] as List<dynamic>?) ?? [];
    final charts = (data['frontend_chart_data'] as List<dynamic>?) ?? [];
    final summary = (data['summary'] as String?) ?? '暂无分析概述';

    return Scaffold(
      appBar: AppBar(title: const Text('AI分析结果')),
      backgroundColor: Colors.grey[900],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 建议
                const Text(
                  '建设性建议',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 12),
                ...suggestions
                    .map(
                      (s) => _buildSuggestionCard(
                        Map<String, dynamic>.from(s as Map),
                      ),
                    )
                    .toList(),

                const SizedBox(height: 18),
                // 关键词（右侧简单列表样式）
                _buildKeywordPane(keywords),

                const SizedBox(height: 18),
                // 概述
                const Text(
                  '概述',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      summary,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                // 数据图表（按 mock 数据顺序渲染）
                const Text(
                  '数据图表',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 12),
                ...charts.map<Widget>((c) {
                  final item = Map<String, dynamic>.from(c as Map);
                  final type = (item['selected_chart_type'] as String?) ?? '';
                  final rawCfg =
                      (item['chart_config'] as Map<String, dynamic>?) ?? {};
                  if (type.contains('Line_Chart'))
                    return _buildLineChart(rawCfg);
                  if (type.contains('Bar_Chart')) return _buildBarChart(rawCfg);
                  if (type.contains('Pie_Chart')) return _buildPieChart(rawCfg);
                  return const SizedBox.shrink();
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
