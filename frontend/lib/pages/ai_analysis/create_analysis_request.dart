import 'package:flutter/material.dart';

class CreateAnalysisRequestPage extends StatefulWidget {
  final String mode;
  final Map<String, dynamic> params;
  final String? resultId;

  const CreateAnalysisRequestPage({
    super.key,
    required this.mode,
    required this.params,
    this.resultId,
  });

  @override
  State<CreateAnalysisRequestPage> createState() =>
      _CreateAnalysisRequestPageState();
}

class _CreateAnalysisRequestPageState extends State<CreateAnalysisRequestPage> {
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI 分析'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
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
                          style: TextStyle(color: Colors.white70, fontSize: 14),
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
                                      lastDate: _endDate ?? DateTime(2100),
                                    );
                                    if (picked != null) {
                                      if (_endDate != null &&
                                          picked.isAfter(_endDate!)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('起始日期不能晚于截止日期'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
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
                                      initialDate: _endDate ??
                                          (_startDate ?? DateTime.now()),
                                      firstDate: _startDate ?? DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      if (_startDate != null &&
                                          picked.isBefore(_startDate!)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('截止日期不能早于起始日期'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
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
                          OutlinedButton(
                            onPressed: () => _selectPerson(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedPerson,
                                  style: TextStyle(
                                    color: _selectedPerson == '全部'
                                        ? Colors.white54
                                        : Colors.white,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
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

  void _selectPerson(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: SizedBox(
                    width: 40,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '选择人员',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _people.length,
                    itemBuilder: (context, index) {
                      final person = _people[index];
                      final isSelected = person == _selectedPerson;

                      return Card(
                        color: isSelected
                            ? const Color(0xFF00D9A3).withOpacity(0.3)
                            : const Color(0xFF2A2A2A),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() => _selectedPerson = person);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF00D9A3),
                                  child: Text(
                                    person[0],
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    person,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check,
                                    color: Color(0xFF00D9A3),
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
