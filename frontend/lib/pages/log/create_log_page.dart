import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/log.dart';
import '../../services/business/log_business.dart';
import '../task/create_task_page.dart';

class CreateLogPage extends StatefulWidget {
  final Task? preSelectedTask;
  final Log? logToEdit;

  const CreateLogPage({
    super.key,
    this.preSelectedTask,
    this.logToEdit,
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
  Task? _selectedTask;
  // final bool _debugMode = true; // 移除 debugMode

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedTask != null) {
      _selectedTask = widget.preSelectedTask;
    } else if (widget.logToEdit != null) {
      // 编辑模式下预填充表单
      final log = widget.logToEdit!;
      _titleController.text = log.logTitle;
      _contentController.text = log.logContent;
      _isCompleted = log.logStatus == 1;
      _plannedDate = log.logDate; // logDate 是非空的，可以直接赋值
      // 解析 startTime 和 endTime 字符串为 TimeOfDay 对象
      final startParts = log.startTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      final endParts = log.endTime.split(':');
      _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      _progress = (log.taskProgress ?? 0).toDouble();
      // _selectedTask 暂时不处理，如果需要可以根据 taskId 加载 Task 对象
    }
  }

  Future<void> _openTaskSelection() async {
    // if (_debugMode) {
    //   final testTasks = MockData.generateTestTasks();
    //   final Task? chosen = await showModalBottomSheet<Task?>(
    //     context: context,
    //     isScrollControlled: true,
    //     backgroundColor: Colors.transparent,
    //     builder: (context) => _buildTaskSelectionSheet(testTasks),
    //   );
    //   if (chosen != null) {
    //     setState(() => _selectedTask = chosen);
    //   }
    //   return;
    // }

    final tasks = await _logBusiness.getExecutorTasksForLogSelection();
    // final List<Task> tasks = [];
    // if (taskMap != null) {
    //   tasks.addAll(taskMap['createdTasks'] ?? []);
    //   tasks.addAll(taskMap['participatedTasks'] ?? []);
    // }
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

  void _showTimePickerDialog(bool isStartTime) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedHour = isStartTime ? _startTime.hour : _endTime.hour;
        int selectedMinute = isStartTime ? _startTime.minute : _endTime.minute;
        String? errorMessage;

        bool isValidEndTime(int hour, int minute) {
          if (!isStartTime) {
            final startMinutes = _startTime.hour * 60 + _startTime.minute;
            final selectedMinutes = hour * 60 + minute;
            return selectedMinutes >= startMinutes;
          }
          return true;
        }

        return Dialog(
          backgroundColor: const Color(0xFF232325),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isStartTime ? '选择开始时间' : '选择结束时间',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 小时选择器
                    SizedBox(
                      width: 60,
                      height: 150,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: selectedHour,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedHour = index;
                          if (!isStartTime &&
                              !isValidEndTime(index, selectedMinute)) {
                            errorMessage = '结束时间不能早于开始时间';
                          } else {
                            errorMessage = null;
                          }
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 24,
                          builder: (context, index) {
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  color: index == selectedHour
                                      ? Colors.white
                                      : Colors.white60,
                                  fontSize: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const Text(
                      ' : ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // 分钟选择器
                    SizedBox(
                      width: 60,
                      height: 150,
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: selectedMinute,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedMinute = index;
                          if (!isStartTime &&
                              !isValidEndTime(selectedHour, index)) {
                            errorMessage = '结束时间不能早于开始时间';
                          } else {
                            errorMessage = null;
                          }
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 60,
                          builder: (context, index) {
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  color: index == selectedMinute
                                      ? Colors.white
                                      : Colors.white60,
                                  fontSize: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '取消',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (!isValidEndTime(selectedHour, selectedMinute)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('结束时间不能早于开始时间'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final newTime = TimeOfDay(
                          hour: selectedHour,
                          minute: selectedMinute,
                        );
                        setState(() {
                          if (isStartTime) {
                            _startTime = newTime;
                          } else {
                            _endTime = newTime;
                          }
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                      ),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    // If in create mode and no task is selected, show error.
    // In edit mode, _selectedTask might be null if not associated with a task, but editing should still be allowed.
    if (widget.logToEdit == null && _selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择关联任务')),
      );
      return;
    }

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题和内容')),
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

    // 构建Log对象
    final Log logToProcess = Log(
      logId: widget.logToEdit?.logId ?? '', // 编辑时使用现有logId，创建时为空
      taskId: _selectedTask?.taskId != null ? int.tryParse(_selectedTask!.taskId) : null,      logTitle: title,
      logContent: content,
      logStatus: _isCompleted ? 1 : 0,
      taskProgress: _progress.toInt(),
      startTime:
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      endTime:
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      logDate: _plannedDate,
      fileIds: [],
    );

    try {
      final bool isUpdate = widget.logToEdit != null;
      final Map<String, dynamic> result = await _logBusiness.createOrUpdateLog(logToProcess, isUpdate: isUpdate);

      if (result['success'] == true) {
        // Log? processedLog = isUpdate ? logToProcess : Log.fromJson(result['data'] ?? {}); // 移除这行
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isUpdate ? '日志更新成功！' : '日志创建成功！')),
          );
          Navigator.of(context).pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? (isUpdate ? '更新失败' : '创建失败'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.logToEdit != null ? '更新日志失败: ${e.toString()}' : '创建日志失败: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.logToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑日志' : '新建日志'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日志详情卡片（包含标题和内容）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF232325),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '日志详情',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '日志标题',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '请输入日志标题',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '日志内容',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _contentController,
                    minLines: 4,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '请输入日志内容',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Upload photos card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF232325),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '上传照片',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          // TODO: Implement photo upload functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('照片上传功能即将上线'),
                              backgroundColor: Color(0xFF4CAF50),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Color(0xFF4CAF50),
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '点击上传照片',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '支持 jpg、png 格式',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Related task card (prototype: select existing or create new)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF232325),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 将 crossAxisAlignment 设置为 start
                children: [
                  const Text(
                    '关联任务',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: _openTaskSelection,
                        icon: const Icon(Icons.list),
                        label: Text(
                          _selectedTask == null
                              ? '选择现有任务'
                              : '已选择: ${_selectedTask!.taskTitle}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000000),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF232325),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      '日志状态',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ToggleButtons(
                      isSelected: [_isCompleted, !_isCompleted],
                      onPressed: (index) {
                        setState(() {
                          _isCompleted = index == 0;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white70,
                      selectedColor: Colors.white,
                      fillColor: const Color(0xFF4CAF50), // 高亮绿色
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        minWidth: 120,
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('已完成', style: TextStyle(fontSize: 16)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('未完成', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '完成日期',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _pickDate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2A2A),
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Icon(Icons.calendar_today),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_plannedDate.year}-${_plannedDate.month.toString().padLeft(2, '0')}-${_plannedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '开始时间',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showTimePickerDialog(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2A2A),
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Icon(Icons.access_time),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '结束时间',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showTimePickerDialog(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2A2A),
                                padding: const EdgeInsets.all(12),
                              ),
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
                  backgroundColor: Colors.green,
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
                    : const Text(
                        '提交',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}