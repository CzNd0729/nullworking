import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 导入 shared_preferences
import 'package:geolocator/geolocator.dart'; // Add geolocator import
import 'package:webview_flutter/webview_flutter.dart'; // Add webview_flutter import here

import '../../models/task.dart';
import '../../models/log.dart';
import '../../services/business/log_business.dart';
import '../task/create_task_page.dart';
// import '../baidu_map_page.dart'; // Remove BaiduMapPage import

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
  String? _currentUserId;
  String? _currentUserName;

  // 照片相关变量
  final List<Map<String, dynamic>> _selectedImages =
      []; // 存储 { 'file': File, 'fileId': int? }
  bool _isUploadingImages = false;
  final ImagePicker _imagePicker = ImagePicker();

  // 定位相关变量
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  String? _address; // Add address variable

  WebViewController? _mapController; // Add WebViewController

  @override
  void initState() {
    super.initState();
    // 如果有预选任务，设置为选中任务
    if (widget.preSelectedTask != null) {
      _selectedTask = widget.preSelectedTask;
    }
    // 加载用户ID和名称
    _loadCurrentUser();

    _mapController = WebViewController();
    _mapController!.loadFlutterAsset('assets/map.html').then((value) {
      if (_latitude != null && _longitude != null) {
        _updateMapLocation(_latitude!, _longitude!); // Update map if location already available
      }
    });
    _mapController!.setJavaScriptMode(JavaScriptMode.unrestricted);
    _mapController!.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (String url) {
        if (_latitude != null && _longitude != null) {
          _updateMapLocation(_latitude!, _longitude!); // Update map if location already available
        }
      },
    ));

    _mapController!.addJavaScriptChannel(
      'FlutterMapChannel',
      onMessageReceived: (message) {
        setState(() {
          _address = message.message;
        });
      },
    );

    if (widget.logToEdit != null) {
      // 编辑模式下预填充表单，不保留任务关联信息
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

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
      _currentUserName = prefs.getString('userName');
    });
  }

  Future<void> _loadLogImages(List<int> fileIds) async {
    if (fileIds.isEmpty) return;

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final List<Map<String, dynamic>> fetchedFiles = await _logBusiness
          .fetchLogFiles(fileIds);
      setState(() {
        for (var fileData in fetchedFiles) {
          if (fileData['fileBytes'] != null) {
            _selectedImages.add({
              'file': null,
              'fileId': fileData['fileId'],
              'fileBytes': fileData['fileBytes'],
              'fileName': fileData['fileName'],
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载图片失败: ${e.toString()}')));
      }
      debugPrint('加载日志图片失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
        });
      }
    }
  }

  Future<void> _openTaskSelection() async {
    // 如果是编辑模式，直接返回
    if (widget.logToEdit != null) return;

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
      // 如果是已有的图片（有fileId），标记为已删除而不是直接移除
      if (_selectedImages[index]['fileId'] != null) {
        _selectedImages[index]['isDeleted'] = true;
      } else {
        // 如果是新上传的图片，直接移除
        _selectedImages.removeAt(index);
      }
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('位置权限被拒绝')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('位置权限被永久拒绝，请在设置中启用')),
          );
        }
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('定位信息获取成功！'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取定位信息失败: ${e.toString()}')),
        );
      }
      debugPrint('获取定位信息失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
          // Call updateMapLocation after getting location
          if (_latitude != null && _longitude != null) {
            _updateMapLocation(_latitude!, _longitude!);
          }
        });
      }
    }
  }

  // Function to update the map location in the WebView
  void _updateMapLocation(double latitude, double longitude) {
    _mapController?.runJavaScript(
        'updateLocation($latitude, $longitude)');
  }

  Future<void> _onSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // 仅在创建日志时检查任务关联
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
              '当前日志进度为100%，提交日志系统将删除关联此任务且未完成的日志，是否提交？',
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
      // 收集所有未被删除的有效图片ID
      final List<int> fileIdsToAttach = _selectedImages
          .where(
            (image) => image['fileId'] != null && image['isDeleted'] != true,
          )
          .map<int>((image) => image['fileId'] as int)
          .toList();

      final Log logToProcess = Log(
        logId: widget.logToEdit?.logId ?? '',
        taskId: widget.logToEdit != null
            ? widget.logToEdit!.taskId
            : (_selectedTask?.taskId != null
                  ? int.tryParse(_selectedTask!.taskId)
                  : null),
        logTitle: title,
        logContent: content,
        logStatus: _isCompleted ? 1 : 0,
        taskProgress: _progress.toInt(),
        startTime:
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        logDate: _plannedDate,
        fileIds: fileIdsToAttach, // 将图片ID列表附加到日志中
        latitude: _latitude, // Add latitude
        longitude: _longitude, // Add longitude
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
          // 如果是新建日志且成功，返回新创建的日志对象
          if (!isUpdate && result['data'] != null) {
            final newLog = Log(
              logId: result['data'].toString(), // 确保 logId 是 String 类型
              taskId: logToProcess.taskId,
              taskTitle: _selectedTask?.taskTitle, // 添加 taskTitle
              logTitle: logToProcess.logTitle,
              logContent: logToProcess.logContent,
              logStatus: logToProcess.logStatus,
              taskProgress: logToProcess.taskProgress,
              startTime: logToProcess.startTime,
              endTime: logToProcess.endTime,
              logDate: logToProcess.logDate,
              userId: int.tryParse(_currentUserId ?? ''), // 从 shared_preferences 获取并转换为 int
              userName: _currentUserName, // 从 shared_preferences 获取
              fileIds: logToProcess.fileIds,
              latitude: _latitude, // Add latitude
              longitude: _longitude, // Add longitude
            );
            Navigator.of(context).pop(newLog); // 返回新创建的日志对象
          } else {
            Navigator.of(context).pop();
          }
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
                          // 如果图片被标记为删除，则跳过显示
                          if (imageEntry['isDeleted'] == true) {
                            return const SizedBox.shrink();
                          }

                          Widget imageWidget;
                          if (imageEntry['file'] != null) {
                            imageWidget = Image.file(
                              imageEntry['file'] as File,
                              fit: BoxFit.cover,
                            );
                          } else if (imageEntry['fileBytes'] != null) {
                            imageWidget = Image.memory(
                              imageEntry['fileBytes'] as Uint8List,
                              fit: BoxFit.cover,
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
                                    '处理中...', // Processing...
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
                                    '点击上传照片', // Tap to upload photos
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '支持 jpg、png 格式', // Supports jpg, png formats
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
            // 上传定位信息卡片
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
                    '上传定位信息',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.location_on),
                      label: _isGettingLocation
                          ? const Text('获取中...')
                          : const Text('获取当前位置'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(height: 12), // Remove this
                  // Center( // Remove this block for map button
                  //   child: ElevatedButton.icon(
                  //     onPressed: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(builder: (context) => const BaiduMapPage()),
                  //       );
                  //     },
                  //     icon: const Icon(Icons.map),
                  //     label: const Text('查看地图'),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color(0xFF2196F3), // Blue color for map button
                  //       padding: const EdgeInsets.symmetric(
                  //         vertical: 12,
                  //         horizontal: 24,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 12),
                  // Baidu Map WebView Widget
                  SizedBox(
                    height: 200, // Adjust height as needed
                    child: _mapController != null
                        ? WebViewWidget(
                            controller: _mapController!,
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '经度: ${_longitude != null ? _longitude!.toStringAsFixed(6) : '未获取'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '纬度: ${_latitude != null ? _latitude!.toStringAsFixed(6) : '未获取'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '地址: ${_address ?? '未获取'}'
                  ),
                ],
              ),
            ),
            // 任务关联卡片
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
                  Row(
                    children: [
                      const Icon(Icons.assignment, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        widget.logToEdit == null ? '关联任务' : '已关联任务',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (widget.logToEdit != null &&
                      widget.logToEdit!.taskId != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2CB7B3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.task_alt,
                            color: Color(0xFF2CB7B3),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.logToEdit!.taskTitle ??
                                  '任务${widget.logToEdit!.taskId}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (widget.logToEdit == null)
                    Column(
                      children: [
                        Center(
                          child: SizedBox(
                            width: 200,
                            child: ElevatedButton.icon(
                              onPressed: widget.preSelectedTask != null
                                  ? null
                                  : _openTaskSelection,
                              icon: const Icon(Icons.list),
                              label: Text(
                                _selectedTask == null
                                    ? '选择现有任务'
                                    : '已选择: ${_selectedTask!.taskTitle}',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF000000),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.preSelectedTask == null) ...[
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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
