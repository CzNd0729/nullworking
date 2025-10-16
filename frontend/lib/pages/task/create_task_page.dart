import 'package:flutter/material.dart';
import '../../services/api/task_api.dart';
import '../../services/api/user_api.dart'; // Added for UserApi
import 'dart:convert'; // Added for jsonDecode
import '../../models/task.dart'; // Added for Task model

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

  String _selectedPriority = 'P1';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isAssigned = false; // 人员分配勾选状态
  String _selectedAssignee = '我'; // 选中的负责人
  List<Map<String, dynamic>> _selectedAssignees = []; // 新增：选中的负责人列表
  List<Map<String, dynamic>> _teamMembers = []; // 替换模拟团队成员列表为可变列表

  final TaskApi _taskApi = TaskApi();
  final UserApi _userApi = UserApi(); // Added UserApi initialization

  @override
  void initState() {
    super.initState();
    _priorityController.text = _selectedPriority;
    _assigneeController.text = '我 (当前用户)';
    _selectedAssignees.add({'realName': '我', 'userId': -1}); // 默认添加“我”作为选中负责人，-1表示当前用户
    _fetchTeamMembers(); // 调用API获取团队成员
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    _dueDateController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
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
      // 选择日期后自动选择时间
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
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
                      final bool isSelected = _selectedAssignees.any((assignee) => assignee['userId'] == member['userId']);
                      return Card(
                        color: isSelected ? const Color(0xFF00D9A3).withOpacity(0.3) : const Color(0xFF2A2A2A),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedAssignees.removeWhere((assignee) => assignee['userId'] == member['userId']);
                              } else {
                                _selectedAssignees.add({'realName': member['name'], 'userId': member['userId']});
                              }
                              _updateAssigneeText(); // 更新显示文本
                            });
                            // Navigator.pop(context); // 不再自动关闭，支持多选
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF00D9A3),
                                  child: Text(
                                    member['name']![0],
                                    style: const TextStyle(color: Colors.black),
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
                                        member['role']!,
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
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateAssigneeText(); // 确保在关闭时更新文本
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9A3), // 确定按钮的颜色
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
        'executorIDs': _isAssigned
            ? _selectedAssignees.map((e) => e['userId']).toList() // 如果分配，则发送选中的所有用户ID
            : [-1], // 否则发送当前用户ID，-1表示当前用户
        'deadline': _selectedDate!.toIso8601String(),
      };

      final response = await _taskApi.publishTask(taskData);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('任务发布成功！'),
              backgroundColor: Color(0xFF00D9A3),
            ),
          );
          final Map<String, dynamic> responseBody = jsonDecode(response.body);
          if (responseBody['code'] == 200 && responseBody['data'] != null) {
            final taskID = responseBody['data']['taskID'].toString();
            final newTask = Task(
              taskID: taskID,
              creatorName: "当前用户", // 示例值，实际应从用户认证信息中获取
              taskTitle: _titleController.text.trim(),
              taskContent: _descriptionController.text.trim(),
              taskPriority: _selectedPriority.substring(1), // 示例值
              taskStatus: "0", // 示例值
              creationTime: DateTime.now(), // 示例值
              deadline: DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              ),
              executorNames: _selectedAssignees.map((assignee) => assignee['realName'].toString()).toList(),
            );
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
                .map((user) => {'name': user['realName'], 'role': '', 'userId': user['userId']})
                .toList();
            // 添加“我”到团队成员列表的开头
            _teamMembers.insert(0, {'name': '我', 'role': '当前用户', 'userId': -1});
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('获取团队成员失败: ${response.statusCode}'), backgroundColor: Colors.red),
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
    if (_selectedAssignees.length == 1 && _selectedAssignees.first['userId'] == -1) {
      _assigneeController.text = '我 (当前用户)';
    } else if (_selectedAssignees.isNotEmpty) {
      final assigneesNames = _selectedAssignees.map((assignee) => assignee['realName']).join(', ');
      _assigneeController.text = assigneesNames;
    } else {
      _assigneeController.text = '我 (当前用户)';
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            32.0,
          ), // 增加底部padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 任务详情部分
              _buildSectionCard(
                title: '任务详情',
                children: [
                  _buildInputField(
                    label: '任务标题',
                    controller: _titleController,
                    hintText: '请输入任务标题',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入任务标题';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextArea(
                    label: '详细描述',
                    controller: _descriptionController,
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

              // 人员分配部分
              _buildSectionCard(
                title: '人员分配',
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _isAssigned,
                        onChanged: (value) {
                          setState(() {
                            _isAssigned = value;
                            if (!_isAssigned) {
                              // 如果不选择人员分配，只能选择自己
                              _selectedAssignee = '我';
                              _assigneeController.text = '我 (当前用户)';
                              _selectedAssignees.clear();
                              _selectedAssignees.add({'realName': '我', 'userId': -1});
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

              // 计划与优先级部分
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

              // 派发任务按钮
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
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
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
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
                        overflow: TextOverflow.ellipsis, // 添加文本溢出处理
                        maxLines: 1, // 限制为单行
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
