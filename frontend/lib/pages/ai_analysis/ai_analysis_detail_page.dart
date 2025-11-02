import 'package:flutter/material.dart';

class AIAnalysisDetailPage extends StatefulWidget {
  final String mode;
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
  String _analysisMode = 'time';
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPerson = '全部';
  String? _selectedTaskId;
  final List<String> _people = ['全部', '张三', '李四', '王五'];
  final List<Map<String, String>> _tasks = [
    {'id': 't1', 'title': '发布社交媒体报告'},
    {'id': 't2', 'title': '市场调研'},
    {'id': 't3', 'title': '用户反馈整理'},
  ];

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
            // 分析模式选择
            Card(
              color: const Color(0xFF1E1E1E),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 分析模式
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '分析模式',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('按时间分析'),
                                selected: _analysisMode == 'time',
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() => _analysisMode = 'time');
                                  }
                                },
                                selectedColor: const Color(0xFF8B5CF6),
                                backgroundColor: const Color(0xFF2A2A2A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('按任务分析'),
                                selected: _analysisMode == 'task',
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() => _analysisMode = 'task');
                                  }
                                },
                                selectedColor: const Color(0xFF8B5CF6),
                                backgroundColor: const Color(0xFF2A2A2A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_analysisMode == 'time') ...[
                    // 时间选择部分
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() => _startDate = picked);
                                    }
                                  },
                                  child: Text(
                                    _startDate == null
                                        ? '起始日期'
                                        : _startDate!.toString().split(' ')[0],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() => _endDate = picked);
                                    }
                                  },
                                  child: Text(
                                    _endDate == null
                                        ? '截止日期'
                                        : _endDate!.toString().split(' ')[0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedPerson,
                            decoration: const InputDecoration(
                              labelText: '选择人员',
                              border: OutlineInputBorder(),
                            ),
                            items: _people.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPerson = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 任务选择部分
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _tasks
                            .map(
                              (task) => RadioListTile<String>(
                                title: Text(task['title']!),
                                value: task['id']!,
                                groupValue: _selectedTaskId,
                                onChanged: (value) {
                                  setState(() => _selectedTaskId = value);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
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
    // 验证输入
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入提示词')));
      return;
    }

    // 验证选择的参数
    if (_analysisMode == 'time') {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请选择起始和截止日期')));
        return;
      }
    } else if (_selectedTaskId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择要分析的任务')));
      return;
    }

    setState(() => _loading = true);

    try {
      // 构建请求参数
      final requestData = _analysisMode == 'time'
          ? {
              'userIds': [1, 2], // 这里应该根据选择的人员获取实际的用户ID
              'startDate': _startDate!.toIso8601String(),
              'endDate': _endDate!.toIso8601String(),
              'prompt': prompt,
            }
          : {'taskId': _selectedTaskId, 'prompt': prompt};

      // TODO: 在这里调用 AI 接口
      debugPrint('发送分析请求: $requestData');

      // 模拟网络延迟
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('分析完成'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('分析模式: ${_analysisMode == 'time' ? '按时间' : '按任务'}'),
                  if (_analysisMode == 'time') ...[
                    Text(
                      '时间范围: ${_startDate!.toString().split(' ')[0]} 至 ${_endDate!.toString().split(' ')[0]}',
                    ),
                    Text('选择人员: $_selectedPerson'),
                  ] else ...[
                    Text(
                      '选择任务: ${_tasks.firstWhere((t) => t['id'] == _selectedTaskId)['title']}',
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('分析结果将在这里显示（目前为占位）'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('分析过程出错: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
