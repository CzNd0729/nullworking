import 'package:flutter/material.dart';

import 'log_page.dart';
import '../../services/business/log_business.dart';
import '../../services/business/task_business.dart';
import '../../models/task.dart';
import '../task/create_task_page.dart';

// Note: this file will call backend to create logs via LogBusiness

class CreateLogPage extends StatefulWidget {
  const CreateLogPage({super.key});

  @override
  State<CreateLogPage> createState() => _CreateLogPageState();
}

class _CreateLogPageState extends State<CreateLogPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _priority = 'P1';
  // status represented as booleans for prototype
  bool _isCompleted = false;
  DateTime _plannedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  double _progress = 50.0;
  bool _isSubmitting = false;
  final LogBusiness _logBusiness = LogBusiness();
  final TaskBusiness _taskBusiness = TaskBusiness();
  Task? _selectedTask;

  Future<void> _openTaskSelection() async {
    // load tasks
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
      builder: (context) => DraggableScrollableSheet(
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
      ),
    );

    if (chosen != null) {
      setState(() {
        _selectedTask = chosen;
      });
    }
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
      setState(() {
        _plannedDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _onSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入标题和内容')));
      return;
    }

    // Validate that on the same day, end time is not earlier than start time
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes < startMinutes) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('结束时间不能早于开始时间')));
      return;
    }

    setState(() => _isSubmitting = true);

    final body = {
      'taskId': _selectedTask != null
          ? int.tryParse(_selectedTask!.taskId) ?? _selectedTask!.taskId
          : null,
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

    final res = await _logBusiness.createLog(body);

    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      // use returned data if available, otherwise create a simple local representation
      final data = res['data'] ?? {};
      final createdLog = LogEntry(
        id:
            data['logId']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        date: _plannedDate,
        status: _isCompleted ? '已完成' : '未完成',
        priority: _priority,
      );
      Navigator.of(context).pop(createdLog);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? '创建失败')),
      );
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
            // Related task card (prototype: select existing or create new)
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
            // Status checkboxes and planned date/time
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
                  // Use ToggleButtons for single-selection of status
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
                  const Text('规划完成日期', style: TextStyle(color: Colors.white70)),
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
                  const Text('计划开始时间', style: TextStyle(color: Colors.white70)),
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
                  const Text('计划结束时间', style: TextStyle(color: Colors.white70)),
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
                    child: Text('${_progress.toInt()}%'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _onSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
