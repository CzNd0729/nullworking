import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/task.dart';
import '../../models/log.dart';
import '../../services/business/log_business.dart';
import '../task/create_task_page.dart';

class CreateLogPage extends StatefulWidget {
  final Task? preSelectedTask;
  final Log? logToEdit;

  const CreateLogPage({super.key, this.preSelectedTask, this.logToEdit});

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

  // 照片相关变量
  final List<Map<String, dynamic>> _selectedImages =
      []; // 存储 { 'file': File, 'fileId': int? }
  bool _isUploadingImages = false;
  final ImagePicker _imagePicker = ImagePicker();

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
      _plannedDate = log.logDate;
      final startParts = log.startTime.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      final endParts = log.endTime.split(':');
      _endTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
      _progress = (log.taskProgress ?? 0).toDouble();
      // 加载日志图片
      _loadLogImages(log.fileIds ?? []);
    }
  }

  Future<void> _loadLogImages(List<int> fileIds) async {
    if (fileIds.isEmpty) return;

    setState(() {
      _isUploadingImages = true; // 暂时用这个状态来表示加载中
    });

    try {
      final List<Map<String, dynamic>> fetchedFiles = await _logBusiness
          .fetchLogFiles(fileIds);
      for (var fileData in fetchedFiles) {
        // 假设fileData包含一个url字段和fileId字段
        // 这里我们需要下载图片并转换为File对象，或者直接使用网络图片URL
        // 为了简化，我们假设直接存储一个placeholder或者一个能展示的File对象
        // 实际应用中需要更复杂的逻辑来处理网络图片
        _selectedImages.add({
          'file': null, // 这里暂时为空，实际应该下载图片或使用网络图片组件
          'fileId': fileData['fileId'], // 假设后端返回的fileId字段
          'url': fileData['url'], // 假设后端返回的url字段
        });
      }
    } catch (e) {
      debugPrint('加载日志图片失败: $e');
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }

  Future<void> _openTaskSelection() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final tasks = await _logBusiness.getExecutorTasksForLogSelection();
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
    FocusManager.instance.primaryFocus?.unfocus();
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
    FocusManager.instance.primaryFocus?.unfocus();
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
                                      : const Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
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
                                      : const Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
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

  // 从相册选择图片（移除相机功能）
  Future<void> _pickImagesFromGallery() async {
    try {
      setState(() {
        _isUploadingImages = true;
      });

      final List<XFile>? selectedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        final List<File> filesToUpload = selectedFiles
            .map((xfile) => File(xfile.path))
            .toList();
        final List<int> uploadedFileIds = await _logBusiness.uploadLogFiles(
          filesToUpload,
        );

        setState(() {
          for (int i = 0; i < filesToUpload.length; i++) {
            _selectedImages.add({
              'file': filesToUpload[i],
              'fileId': uploadedFileIds.length > i ? uploadedFileIds[i] : null,
            });
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('照片选择并上传成功'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('照片选择失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }

  // 删除照片
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 预览照片
  void _previewImage(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: _selectedImages[index]['file'] != null
                  ? Image.file(
                      _selectedImages[index]['file'] as File,
                      fit: BoxFit.contain,
                    )
                  : (_selectedImages[index]['url'] != null
                        ? Image.network(
                            _selectedImages[index]['url'] as String,
                            fit: BoxFit.contain,
                          )
                        : const SizedBox.shrink()),
            ),
            Positioned(
              top: 40,
              right: 40,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (widget.logToEdit == null && _selectedTask == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择关联任务')));
      return;
    }

    // 当进度为100%且状态为已完成时，显示确认对话框
    if (_progress == 100 && _isCompleted) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF232325),
            title: const Text('注意', style: TextStyle(color: Colors.white)),
            content: const Text(
              '注意到进度为100%，此时提交日志会关闭任务，是否提交？',
              style: TextStyle(color: Colors.white70),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  '取消',
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('确认', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm != true) {
        return;
      }
    }

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入标题和内容')));
      return;
    }

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes < startMinutes) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('结束时间不能早于开始时间')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final List<int> fileIdsToAttach = _selectedImages
          .where((image) => image['fileId'] != null)
          .map<int>((image) => image['fileId'] as int)
          .toList();

      // 构建Log对象 - 图片仅在前端显示，不上传到fileIds
      final Log logToProcess = Log(
        logId: widget.logToEdit?.logId ?? '',
        taskId: _selectedTask?.taskId != null
            ? int.tryParse(_selectedTask!.taskId)
            : null,
        logTitle: title,
        logContent: content,
        logStatus: _isCompleted ? 1 : 0,
        taskProgress: _progress.toInt(),
        startTime:
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        logDate: _plannedDate,
        fileIds: fileIdsToAttach, // 图片仅在前端显示，不传文件ID到后端
      );

      final bool isUpdate = widget.logToEdit != null;
      final Map<String, dynamic> result = await _logBusiness.createOrUpdateLog(
        logToProcess,
        isUpdate: isUpdate,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isUpdate ? '日志更新成功！' : '日志创建成功！')),
          );
          Navigator.of(context).pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? (isUpdate ? '更新失败' : '创建失败'),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.logToEdit != null
                ? '更新日志失败: ${e.toString()}'
                : '创建日志失败: ${e.toString()}',
          ),
        ),
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
            // 上传照片卡片
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

                  // 已选择的照片预览
                  if (_selectedImages.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          final imageEntry = _selectedImages[index];
                          final File? imageFile = imageEntry['file'];
                          final String? imageUrl = imageEntry['url'];

                          Widget imageWidget;
                          if (imageFile != null) {
                            imageWidget = Image.file(
                              imageFile,
                              fit: BoxFit.cover,
                            );
                          } else if (imageUrl != null) {
                            imageWidget = Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error, color: Colors.red),
                            );
                          } else {
                            imageWidget = const Icon(Icons.broken_image);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => _previewImage(index),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors
                                          .grey[800], // Placeholder background
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageWidget,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 上传按钮
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
                        onTap: _isUploadingImages
                            ? null
                            : _pickImagesFromGallery,
                        borderRadius: BorderRadius.circular(12),
                        child: _isUploadingImages
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '处理中...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
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
            // 关联任务卡片
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
            // ... 其余部分保持不变
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
                      fillColor: const Color(0xFF4CAF50),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('提交', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
