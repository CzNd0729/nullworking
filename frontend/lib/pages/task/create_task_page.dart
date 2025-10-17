import 'package:flutter/material.dart';
import '../../services/api/task_api.dart';
import '../../services/api/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/task.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _priorityController = TextEditingController();

  // 新增：输入框焦点节点（核心修复）
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  String _selectedPriority = 'P1';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isAssigned = false;
  List<Map<String, dynamic>> _selectedAssignees = [];
  List<Map<String, dynamic>> _teamMembers = [];

  final TaskApi _taskApi = TaskApi();
  final UserApi _userApi = UserApi();
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _priorityController.text = _selectedPriority;
    _loadCurrentUserId();
    _fetchTeamMembers();
    // 新增：监听焦点变化，确保切换时失焦
    _titleFocusNode.addListener(_onFocusChanged);
    _descriptionFocusNode.addListener(_onFocusChanged);
  }

  // 新增：焦点变化统一处理
  void _onFocusChanged() {
    if (!mounted) return;
    if (!_titleFocusNode.hasFocus && !_descriptionFocusNode.hasFocus) {
      FocusScope.of(context).unfocus();
    }
  }

  // 新增：强制所有输入框失焦
  void _forceUnfocus() {
    _titleFocusNode.unfocus();
    _descriptionFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  // 新增：重置表单状态（含焦点）
  void _resetFormState() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _assigneeController.clear();
      _dueDateController.clear();
      _priorityController.text = 'P1';
      _selectedPriority = 'P1';
      _selectedDate = null;
      _selectedTime = null;
      _selectedAssignees = [
        {'realName': _currentUserName ?? '当前用户', 'userId': _currentUserId ?? '-1'},
      ];
      _isAssigned = false;
      _updateAssigneeText();
    });
    _forceUnfocus();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userID') ?? '-1';
      _currentUserName = prefs.getString('realName') ?? '当前用户';
      _selectedAssignees = [
        {'realName': _currentUserName, 'userId': _currentUserId},
      ];
      _updateAssigneeText();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    _dueDateController.dispose();
    _priorityController.dispose();
    // 新增：销毁焦点节点
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    _forceUnfocus(); // 新增：点击前先失焦
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D9A3),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDueDateText();
      });
      _selectTime();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D9A3),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updateDueDateText();
      });
    }
  }

  void _updateDueDateText() {
    if (_selectedDate != null && _selectedTime != null) {
      final year = _selectedDate!.year;
      final month = _selectedDate!.month;
      final day = _selectedDate!.day;
      final hour = _selectedTime!.hour;
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');

      _dueDateController.text = '${year}年${month}月${day}日, $hour:$minute';
    }
  }

  void _selectPriority() {
    _forceUnfocus(); // 新增：点击前先失焦
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择优先级',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ...['P0', 'P1', 'P2', 'P3']
                .map(
                  (priority) => ListTile(
                    title: Text(
                      priority,
                      style: TextStyle(
                        color: priority == 'P0'
                            ? Colors.red
                            : (priority == 'P1'
                                  ? Colors.orange
                                  : (priority == 'P2'
                                        ? Colors.blue
                                        : Colors.green)),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedPriority = priority;
                        _priorityController.text = priority;
                      });
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  void _selectAssignee() {
    _forceUnfocus(); // 新增：点击前先失焦
    List<Map<String, dynamic>> tempSelected = List.from(_selectedAssignees);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (sheetContext, sheetSetState) {
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
                      '选择负责人',
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
                        itemCount: _teamMembers.length,
                        itemBuilder: (context, index) {
                          final member = _teamMembers[index];
                          bool isSelected = tempSelected.any(
                            (assignee) =>
                                assignee['userId'] == member['userId'],
                          );

                          return Card(
                            key: ValueKey(member['userId']),
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
                                sheetSetState(() {
                                  if (isSelected) {
                                    tempSelected.removeWhere(
                                      (assignee) =>
                                          assignee['userId'] ==
                                          member['userId'],
                                    );
                                  } else {
                                    tempSelected.add({
                                      'realName': member['name'],
                                      'userId': member['userId'],
                                    });
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF00D9A3),
                                      child: Text(
                                        member['name']![0],
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member['name']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            member['role'] ?? '无角色',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
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
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                '取消',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedAssignees = List.from(tempSelected);
                                  _updateAssigneeText();
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D9A3),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                '确定',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _publishTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择截止日期'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final taskData = {
        'title': _titleController.text.trim(),
        'content': _descriptionController.text.trim(),
        'priority': int.parse(_selectedPriority.substring(1)),
        'executorIDs': _selectedAssignees
            .map((e) => e['userId'].toString())
            .toList(),
        'deadline': DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        ).toIso8601String(),
      };

      final response = await _taskApi.publishTask(taskData);

      if (response.statusCode == 200) {
        if (mounted) {
          final Map<String, dynamic> responseBody = jsonDecode(response.body);
          if (responseBody['code'] == 200 && responseBody['data'] != null) {
            final taskID = responseBody['data']['taskID'].toString();
            final newTask = Task(
              taskID: taskID,
              creatorName: _currentUserName ?? "当前用户",
              taskTitle: _titleController.text.trim(),
              taskContent: _descriptionController.text.trim(),
              taskPriority: _selectedPriority.substring(1),
              taskStatus: "0",
              creationTime: DateTime.now(),
              deadline: DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              ),
              executorNames: _selectedAssignees
                  .map((assignee) => assignee['realName'].toString())
                  .toList(),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('任务发布成功！'),
                backgroundColor: Color(0xFF00D9A3),
              ),
            );
            _resetFormState(); // 新增：发布成功后重置状态
            Navigator.pop(context, newTask);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('任务发布失败: ${responseBody['message'] ?? '未知错误'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('任务发布失败: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布任务时出错: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTeamMembers() async {
    try {
      final response = await _userApi.getSubDeptUser();
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['code'] == 200 && responseBody['data'] != null) {
          setState(() {
            _teamMembers = (responseBody['data']['users'] as List)
                .map(
                  (user) => {
                    'name': user['realName'] ?? '未知用户',
                    'role': user['role'] ?? '',
                    'userId': user['userId'].toString(),
                  },
                )
                .toList();
            if (_currentUserId != null) {
              _teamMembers.insert(0, {
                'name': '我',
                'role': '当前用户',
                'userId': _currentUserId,
              });
            } else {
              _teamMembers.insert(0, {
                'name': '我',
                'role': '当前用户',
                'userId': '-1',
              });
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('获取团队成员失败: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取团队成员时出错: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _updateAssigneeText() {
    if (_selectedAssignees.isEmpty) {
      _assigneeController.text = '请选择负责人';
    } else if (_selectedAssignees.length == 1 &&
        _selectedAssignees.first['realName'] == '我') {
      _assigneeController.text = '我 (当前用户)';
    } else {
      final assigneesNames = _selectedAssignees
          .map((assignee) => assignee['realName'])
          .join(', ');
      _assigneeController.text = assigneesNames;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('新建任务', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _resetFormState(); // 新增：返回前重置状态
            Navigator.pop(context);
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: '任务详情',
                children: [
                  // 修改：传入焦点节点
                  _buildInputField(
                    label: '任务标题',
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    hintText: '请输入任务标题',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入任务标题';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // 修改：传入焦点节点
                  _buildTextArea(
                    label: '详细描述',
                    controller: _descriptionController,
                    focusNode: _descriptionFocusNode,
                    hintText: '请输入任务详细描述',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入详细描述';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '人员分配',
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _isAssigned,
                        onChanged: (value) {
                          _forceUnfocus(); // 新增：切换时失焦
                          setState(() {
                            _isAssigned = value;
                            if (!_isAssigned) {
                              _selectedAssignees = [
                                {
                                  'realName': '我',
                                  'userId': _currentUserId ?? '-1',
                                },
                              ];
                              _updateAssigneeText();
                            }
                          });
                        },
                        activeColor: const Color(0xFF00D9A3),
                      ),
                      const Text(
                        '分配给其他成员',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSelectableField(
                    label: '负责人',
                    controller: _assigneeController,
                    hintText: '我 (当前用户)',
                    icon: Icons.arrow_forward_ios,
                    onTap: _isAssigned ? _selectAssignee : null,
                    readOnly: !_isAssigned,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '计划与优先级',
                children: [
                  _buildSelectableField(
                    label: '截止日期',
                    controller: _dueDateController,
                    hintText: '请选择截止日期',
                    icon: Icons.calendar_today,
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 16),
                  _buildSelectableField(
                    label: '优先级',
                    controller: _priorityController,
                    hintText: 'P1',
                    icon: Icons.list,
                    onTap: _selectPriority,
                    readOnly: true,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publishTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '派发任务',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    IconData? icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // 修改：添加focusNode参数和失焦逻辑
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode, // 新增参数
    String? hintText,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextFormField(
          focusNode: focusNode, // 绑定焦点节点
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator: validator,
          onTapOutside: (event) {
            _forceUnfocus(); // 点击外部强制失焦
          },
        ),
      ],
    );
  }

  // 修改：添加focusNode参数和失焦逻辑
  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode, // 新增参数
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextFormField(
          focusNode: focusNode, // 绑定焦点节点
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
            alignLabelWithHint: true,
          ),
          validator: validator,
          onTapOutside: (event) {
            _forceUnfocus(); // 点击外部强制失焦
          },
        ),
      ],
    );
  }

  Widget _buildSelectableField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    IconData? icon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.text.isEmpty
                            ? (hintText ?? '')
                            : controller.text,
                        style: TextStyle(
                          color: controller.text.isEmpty
                              ? Colors.white54
                              : Colors.white,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (icon != null)
                      Icon(icon, color: Colors.white54, size: 20)
                    else
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}