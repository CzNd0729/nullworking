import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/log.dart';
import '../../services/business/log_business.dart';
import '../../services/business/task_business.dart';
import '../task/create_task_page.dart';
import '../../services/mock/mock_data.dart';

class CreateLogPage extends StatefulWidget {
  final Task? preSelectedTask;

  const CreateLogPage({
    super.key,
    this.preSelectedTask,
  });

  @override
  State<CreateLogPage> createState() => _CreateLogPageState();
}

class _CreateLogPageState extends State<CreateLogPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isCompleted = false;
  DateTime _plannedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  double _progress = 50.0;
  bool _isSubmitting = false;
  final LogBusiness _logBusiness = LogBusiness();
  final TaskBusiness _taskBusiness = TaskBusiness();
  Task? _selectedTask;
  final bool _debugMode = true;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedTask != null) {
      _selectedTask = widget.preSelectedTask;
    }
  }

  Future<void> _openTaskSelection() async {
    if (_debugMode) {
      final testTasks = MockData.generateTestTasks();
      final Task? chosen = await showModalBottomSheet<Task?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildTaskSelectionSheet(testTasks),
      );
      if (chosen != null) {
        setState(() => _selectedTask = chosen);
      }
      return;
    }

    final taskMap = await _taskBusiness.loadUserTasks();
    final List<Task> tasks = [];
    if (taskMap != null) {
      tasks.addAll(taskMap['createdTasks'] ?? []);
      tasks.addAll(taskMap['participatedTasks'] ?? []);
    }
    final Task? chosen = await showModalBottomSheet<Task?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTaskSelectionSheet(tasks),
    );
    if (chosen != null) {
      setState(() => _selectedTask = chosen);
    }
  }

  Widget _buildTaskSelectionSheet(List<Task> tasks) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const SizedBox(
                width: 40,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '选择任务',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final t = tasks[index];
                    return ListTile(
                      title: Text(
                        t.taskTitle,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '创建者: ${t.creatorName}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () => Navigator.of(context).pop(t),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate,
      firstDate: DateTime(_plannedDate.year - 5),
      lastDate: DateTime(_plannedDate.year + 5),
    );
    if (picked != null) {
      setState(() => _plannedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _onSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty || _selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题、内容并选择关联任务')),
      );
      return;
    }

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes < startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束时间不能早于开始时间')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final body = {
      'taskId': int.tryParse(_selectedTask!.taskId) ?? _selectedTask!.taskId,
      'logTitle': title,
      'logContent': content,
      'logStatus': _isCompleted ? 1 : 0,
      'taskProgress': _progress.toInt(),
      'startTime':
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      'endTime':
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      'logDate':
          '${_plannedDate.year}-${_plannedDate.month.toString().padLeft(2, '0')}-${_plannedDate.day.toString().padLeft(2, '0')}',
      'fileIds': [],
    };

    try {
      if (_debugMode) {
        // 修正Duration参数（使用命名参数milliseconds）
        await Future.delayed(const Duration(milliseconds: 1000));
        final newLog = Log(
          logId: DateTime.now().millisecondsSinceEpoch.toString(),
          taskId: int.tryParse(_selectedTask!.taskId),
          logTitle: title,
          logContent: content,
          logStatus: _isCompleted ? 1 : 0,
          taskProgress: _progress.toInt(),
          startTime: body['startTime'] as String,
          endTime: body['endTime'] as String,
          logDate: _plannedDate,
          fileIds: [],
        );
        if (mounted) {
          Navigator.of(context).pop(newLog);
        }
        return;
      }

      final res = await _logBusiness.createLog(body);
      if (res['success'] == true) {
        final data = res['data'] ?? {};
        final createdLog = Log.fromJson(data);
        Navigator.of(context).pop(createdLog);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? '创建失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建日志失败: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建日志'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '输入标题',
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '输入内容',
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '关联任务',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _openTaskSelection,
                    icon: const Icon(Icons.list),
                    label: Text(
                      _selectedTask == null
                          ? '选择现有任务'
                          : '已选择: ${_selectedTask!.taskTitle}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<Task?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateTaskPage(),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedTask = result;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('创建新任务'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '日志状态',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ToggleButtons(
                    isSelected: [_isCompleted, !_isCompleted],
                    onPressed: (index) {
                      setState(() {
                        _isCompleted = index == 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white70,
                    selectedColor: Colors.white,
                    fillColor: const Color(0xFF2A2A2A),
                    constraints: const BoxConstraints(
                      minHeight: 36,
                      minWidth: 100,
                    ),
                    children: const [Text('已完成'), Text('未完成')],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCompleted ? '实际完成日期' : '规划完成日期',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickDate,
                        child: const Icon(Icons.calendar_today),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_plannedDate.year}-${_plannedDate.month.toString().padLeft(2, '0')}-${_plannedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCompleted ? '实际开始时间' : '计划开始时间',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickStartTime,
                        child: const Icon(Icons.access_time),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCompleted ? '实际结束时间' : '计划结束时间',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickEndTime,
                        child: const Icon(Icons.access_time),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '进度',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _progress,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_progress.toInt()}%',
                    onChanged: (v) => setState(() => _progress = v),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_progress.toInt()}%',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2CB7B3),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('提交'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}