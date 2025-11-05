import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:nullworking/services/api/user_api.dart';
import 'package:nullworking/services/api/task_api.dart';

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
  // 多选：存储已选人员的姓名（不包含“全部”占位）
  Set<String> _selectedPeople = {};
  String? _selectedTaskId;
  final UserApi _userApi = UserApi();
  final TaskApi _taskApi = TaskApi();

  bool _loadingData = false;

  List<String> _people = ['全部'];
  List<Map<String, String>> _tasks = [];
  Map<String, int> _peopleMap = {}; // name -> userId

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRemoteData();
  }

  Future<void> _loadRemoteData() async {
    setState(() => _loadingData = true);

    // 加载人员（同级及下级部门用户）
    try {
      final userResp = await _userApi.getSubDeptUser();
      if (userResp.statusCode == 200) {
        final body = jsonDecode(userResp.body);
        if (body['code'] == 200 && body['data'] != null) {
          final users = body['data']['users'] as List<dynamic>?;
          if (users != null) {
            // 保留全部选项在头部，同时记录 name->id 映射
            final names = <String>[];
            final map = <String, int>{};
            for (var u in users) {
              final id = u['userId'];
              final name = u['realName']?.toString() ?? '';
              if (name.isNotEmpty) {
                names.add(name);
                if (id != null) {
                  try {
                    map[name] = int.parse(id.toString());
                  } catch (_) {
                    // ignore parse
                  }
                }
              }
            }
            setState(() {
              _people = ['全部', ...names];
              _peopleMap = map;
            });
          }
        }
      }
    } catch (e) {
      // 忽略，页面会继续使用现有数据
      debugPrint('加载用户失败: $e');
    }

    // 加载任务（当前用户创建与参与的任务）
    try {
      final taskList = await _taskApi.listTasks();
      if (taskList != null) {
        final combined = <Map<String, String>>[];
        for (var t in taskList.createdTasks) {
          combined.add({'id': t.taskId, 'title': t.taskTitle});
        }
        for (var t in taskList.participatedTasks) {
          // 避免重复任务ID
          if (!combined.any((e) => e['id'] == t.taskId)) {
            combined.add({'id': t.taskId, 'title': t.taskTitle});
          }
        }
        setState(() {
          _tasks = combined;
        });
      }
    } catch (e) {
      debugPrint('加载任务失败: $e');
    }

    setState(() => _loadingData = false);
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
            if (_loadingData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 120,
                    height: 24,
                    child: LinearProgressIndicator(),
                  ),
                ),
              ),
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
                                      initialDate:
                                          _endDate ??
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
                                Expanded(
                                  child: Text(
                                    // 显示全部或已选人数/姓名
                                    _selectedPeople.isEmpty
                                        ? '全部'
                                        : (_selectedPeople.length == 1
                                              ? _selectedPeople.first
                                              : '${_selectedPeople.length}人已选'),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _selectedPeople.isEmpty
                                          ? Colors.white54
                                          : Colors.white,
                                    ),
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
                      child: OutlinedButton(
                        onPressed: () => _selectTask(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedTaskId == null
                                    ? '选择任务'
                                    : _tasks.firstWhere(
                                        (t) => t['id'] == _selectedTaskId,
                                      )['title']!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _selectedTaskId == null
                                      ? Colors.white54
                                      : Colors.white,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
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
    // 使用 StatefulBuilder 在 modal 内维护临时选择，用户点击 确定 时再保存到页面状态
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          // 在 StatefulBuilder 外初始化一次 localSelected，避免每次 modal 重建时被重置
          final localSelected = <String>{}..addAll(_selectedPeople);
          return StatefulBuilder(
            builder: (context, modalSetState) {
              // 本地临时选择集合，初始为当前已选

              bool isAllSelected() {
                return _people.length > 1 &&
                    localSelected.length == (_people.length - 1);
              }

              void toggleAll() {
                if (isAllSelected()) {
                  localSelected.clear();
                } else {
                  localSelected.clear();
                  for (var i = 1; i < _people.length; i++) {
                    localSelected.add(_people[i]);
                  }
                }
                modalSetState(() {});
              }

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

                          // index == 0 是 “全部” 选项
                          if (index == 0) {
                            final allSelected = isAllSelected();
                            return Card(
                              color: allSelected
                                  ? const Color(0xFF00D9A3).withOpacity(0.3)
                                  : const Color(0xFF2A2A2A),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => modalSetState(() => toggleAll()),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFF00D9A3,
                                        ),
                                        child: Text(
                                          person[0],
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
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
                                      if (allSelected)
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
                          }

                          final isSelected = localSelected.contains(person);

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
                              onTap: () => modalSetState(() {
                                if (isSelected) {
                                  localSelected.remove(person);
                                } else {
                                  localSelected.add(person);
                                }
                              }),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF00D9A3),
                                      child: Text(
                                        person[0],
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // 保存本地选择到页面状态
                            setState(() {
                              _selectedPeople = <String>{}
                                ..addAll(localSelected);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _selectTask(BuildContext context) {
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
                  '选择任务',
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
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final isSelected = task['id'] == _selectedTaskId;

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
                            setState(() => _selectedTaskId = task['id']);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF00D9A3),
                                  child: Text(
                                    task['title']![0],
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    task['title']!,
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
              'userIds': _selectedPeople.isEmpty
                  ? _peopleMap.values.toList()
                  : _selectedPeople
                        .map((name) => _peopleMap[name])
                        .where((id) => id != null)
                        .map((id) => id!)
                        .toList(),
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
                    Text(
                      '选择人员: ${_selectedPeople.isEmpty ? '全部' : (_selectedPeople.length == 1 ? _selectedPeople.first : '${_selectedPeople.length}人')}',
                    ),
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
