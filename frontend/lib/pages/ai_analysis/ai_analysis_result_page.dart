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

  final List<String> _chartColorPalette = const [
    '#4285F4', // Google Blue
    '#34A853', // Google Green
    '#EA4335', // Google Red
    '#FBBC05', // Google Yellow
    '#9C27B0', // Deep Purple
    '#00BCD4', // Cyan
    '#FF9800', // Orange
    '#E91E63', // Pink
    '#673AB7', // Violet
    '#009688', // Teal
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];

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

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
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

  Widget _buildLineChart(Map<String, dynamic> cfg, String? description) {
    final data =
        (cfg['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final String yAxisLabel = (cfg['y_axis'] as String?) ?? '';

    // 全局获取所有非'x'的键作为y轴参数
    final Set<String> allYKeys = {};
    for (final item in data) {
      item.keys.where((key) => key != 'x').forEach((key) {
        if (item[key] is num) { // 校验是否为数值类型
          allYKeys.add(key);
        }
      });
    }
    final List<String> yKeys = allYKeys.toList();

    // 为每个yKey分配颜色和填充
    final List<Map<String, dynamic>> lineConfigs = yKeys.asMap().entries.map((entry) {
      final int index = entry.key;
      final String key = entry.value;
      final String lineColorHex =
          (cfg['additional_config']?[key]?['line_color'] as String?) ??
              _chartColorPalette[index % _chartColorPalette.length];
      final String fillStr =
          (cfg['additional_config']?[key]?['fill'] as String?) ?? 'rgba(0,0,0,0)';
      return {
        'key': key,
        'lineColor': Color(int.parse(lineColorHex.replaceFirst('#', '0xFF'))),
        'fillColor': _parseRgbaColor(fillStr),
      };
    }).toList();

    // 计算所有y轴的最大值
    double globalMaxYValue = 0.0;
    for (final item in data) {
      for (final yKey in yKeys) {
        final double yValue = (item[yKey] as num? ?? 0).toDouble();
        if (yValue > globalMaxYValue) {
          globalMaxYValue = yValue;
        }
      }
    }

    final double maxY = (globalMaxYValue <= 0) ? 100.0 : globalMaxYValue * 1.2;

    final chartWidth = ((data.length + 1) * 80.0).clamp(300.0, double.infinity);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description ?? '趋势图',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (yAxisLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Y轴: $yAxisLabel',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            // 图例
            if (lineConfigs.length > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: lineConfigs.map((config) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 4,
                        color: config['lineColor'] as Color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        config['key'] as String,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
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
                      maxX: data.length.toDouble() > 0 ? data.length.toDouble() -1 : 0, // Ensure maxX is not negative
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
                              if (v > globalMaxYValue) {
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
                      lineBarsData: lineConfigs.map((config) {
                        final String currentYKey = config['key'] as String;
                        return LineChartBarData(
                          spots: data.asMap().entries.map((e) {
                            final x = e.key.toDouble();
                            final y = (e.value[currentYKey] as num? ?? 0).toDouble();
                            return FlSpot(x, y);
                          }).toList(),
                          isCurved: true,
                          color: config['lineColor'] as Color,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: config['fillColor'] as Color,
                          ),
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

  // 方案1：固定字体+文字换行 实现
  Widget _buildBarChart(Map<String, dynamic> cfg, String? description) {
    final data =
        (cfg['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final List<String> colorsHex =
        (cfg['additional_config']?['color_scheme'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        _chartColorPalette;
    final String yAxisLabel = (cfg['y_axis'] as String?) ?? '';

    // 全局获取所有非'x'的键作为y轴参数
    final Set<String> allYKeys = {};
    for (final item in data) {
      item.keys.where((key) => key != 'x').forEach((key) {
        if (item[key] is num) { // 校验是否为数值类型
          allYKeys.add(key);
        }
      });
    }
    final List<String> yKeys = allYKeys.toList();

    // 为每个yKey分配颜色
    final Map<String, Color> yKeyColors = {};
    for (int i = 0; i < yKeys.length; i++) {
      yKeyColors[yKeys[i]] = Color(int.parse(colorsHex[i % colorsHex.length].replaceFirst('#', '0xFF')));
    }

    // 计算所有y轴的最大值
    double globalMaxYValue = 0.0;
    for (final item in data) {
      for (final yKey in yKeys) {
        final double yValue = (item[yKey] as num? ?? 0).toDouble();
        if (yValue > globalMaxYValue) {
          globalMaxYValue = yValue;
        }
      }
    }

    final double maxY = (globalMaxYValue <= 0) ? 10.0 : (globalMaxYValue * 1.2).toDouble();

    // 核心配置：固定字体大小（10号字，适合换行显示）
    const double xAxisFontSize = 10.0;

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description ?? '柱状图',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (yAxisLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Y轴: $yAxisLabel',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            // 新增X轴字段说明（同之前，带颜色标识）
            // 修改为图例，显示yKey的颜色
            if (yKeyColors.length > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: yKeyColors.entries.map((entry) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        color: entry.value,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  // 增加每个柱子的横向占用宽度（80→100），给换行标签留空间
                  width: ((data.length + 1) * 100.0).clamp(300.0, double.infinity),
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
                              if (v > globalMaxYValue) {
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
                            // 增加底部预留空间（默认20→40），容纳两行文字
                            reservedSize: 40,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              if (i >= 0 && i < data.length) {
                                final labelText = data[i]['x'] as String? ?? '';
                                return SizedBox(
                                  // 限制标签容器宽度，触发自动换行
                                  width: 80,
                                  child: Text(
                                    labelText,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: xAxisFontSize, // 固定字体大小
                                    ),
                                    textAlign: TextAlign.center, // 文字居中
                                    maxLines: 2, // 最多显示2行
                                    overflow: TextOverflow.ellipsis, // 超出部分省略
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      barGroups: data.asMap().entries.map((e) {
                        final xIndex = e.key;
                        return BarChartGroupData(
                          x: xIndex,
                          barRods: yKeys.asMap().entries.map((yEntry) {
                            final yKey = yEntry.value;
                            final color = yKeyColors[yKey]!;
                            final yValue = (e.value[yKey] as num? ?? 0).toDouble();
                            return BarChartRodData(
                              toY: yValue,
                              color: color,
                              width: 25 / yKeys.length, // 根据yKeys的数量调整柱子宽度
                              borderRadius: BorderRadius.circular(6),
                            );
                          }).toList(),
                          barsSpace: 4, // 柱子之间的空间
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

  Widget _buildPieChart(Map<String, dynamic> cfg, String? description) {
    final data =
        (cfg['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final List<String> colorsHex = (cfg['additional_config']?['color_scheme'] as List<dynamic>?) // 允许为null
            ?.map((e) => e.toString())
            .toList() ??
        _chartColorPalette;

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description ?? '饼图',
              style: const TextStyle(
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
                    // 修复类型错误：num→double?
                    final double? pieValue = (item['value'] as num?)?.toDouble();
                    return PieChartSectionData(
                      color: color,
                      value: pieValue,
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
            ...kw.map((k) {
              final double intensity = ((k['percentage'] as num?) ?? 0) / 100.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      k['keyword'] as String? ?? '未知',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 + (intensity * 10),
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
                const Text(
                  '关键词统计',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 12),
                _buildKeywordPane(keywords),
                const SizedBox(height: 18),
                const Text(
                  '数据图表',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 12),
                ...charts.map<Widget>((c) {
                  final item = Map<String, dynamic>.from(c as Map);
                  final type = (item['selected_chart_type'] as String?) ?? '';
                  final description = (item['description'] as String?);
                  final rawCfg =
                      (item['chart_config'] as Map<String, dynamic>?) ?? {};
                  if (type.contains('Line_Chart'))
                    return _buildLineChart(rawCfg, description);
                  if (type.contains('Bar_Chart'))
                    return _buildBarChart(rawCfg, description);
                  if (type.contains('Pie_Chart'))
                    return _buildPieChart(rawCfg, description);
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