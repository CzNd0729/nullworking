import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/business/user_business.dart';

class UserDetailPage extends StatefulWidget {
  final User user;

  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final UserBusiness _userBusiness = UserBusiness();

  late User _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  // 刷新用户数据
  Future<void> _refreshUserData() async {
    try {
      final user = await _userBusiness.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('刷新数据失败');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 编辑字段通用方法
  Future<void> _editField(
    String title,
    String currentValue,
    String fieldName,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: currentValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑$title'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: title,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            keyboardType: fieldName == 'phoneNumber'
                ? TextInputType.phone
                : (fieldName == 'email'
                      ? TextInputType.emailAddress
                      : TextInputType.text),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入$title';
              }

              // 邮箱格式校验
              if (fieldName == 'email') {
                if (!value.contains('@')) {
                  return '邮箱格式不正确，必须包含@';
                }
                // 检查是否包含常见邮箱后缀
                final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                if (!emailRegex.hasMatch(value)) {
                  return '邮箱格式不正确';
                }
              }

              // 电话号码校验
              if (fieldName == 'phoneNumber') {
                if (value.length != 11) {
                  return '电话号码必须为11位';
                }
                if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                  return '请输入有效的手机号码';
                }
              }

              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentValue) {
      await _updateUserField(fieldName, result);
    }
  }

  // 更新用户字段
  Future<void> _updateUserField(String fieldName, String value) async {
    setState(() => _isLoading = true);

    try {
      Map<String, String?> updatedData = {
        'realName': _currentUser.realName,
        'email': _currentUser.email,
        'phoneNumber': _currentUser.phoneNumber,
      };
      updatedData[fieldName] = value;

      Map<String, String> payload = {
        'realName': updatedData['realName'] ?? '',
        'phoneNumber': updatedData['phoneNumber'] ?? '',
        'email': updatedData['email'] ?? '',
      };

      final success = await _userBusiness.updateUserInfo(payload);

      if (mounted) {
        if (success) {
          _showSnackBar('更新成功');
          await _refreshUserData();
        } else {
          _showSnackBar('更新失败');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('更新失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 修改密码
  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('修改密码'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 原密码
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: obscureOld,
                    decoration: InputDecoration(
                      labelText: '原密码',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureOld ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() => obscureOld = !obscureOld);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入原密码';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 新密码
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() => obscureNew = !obscureNew);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入新密码';
                      }
                      if (value.length < 6) {
                        return '密码至少6位';
                      }
                      if (value == oldPasswordController.text) {
                        return '新密码不能与原密码相同';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 确认新密码
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: '确认新密码',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          );
                        },
                      ),
                    ),
                    onChanged: (value) {
                      // 实时校验确认密码
                      setDialogState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请再次输入新密码';
                      }
                      if (value != newPasswordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _performPasswordChange(
        oldPasswordController.text,
        newPasswordController.text,
      );
    }
  }

  // 执行密码修改
  Future<void> _performPasswordChange(
    String oldPassword,
    String newPassword,
  ) async {
    setState(() => _isLoading = true);

    try {
      final result = await _userBusiness.changePassword(
        oldPassword,
        newPassword,
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSnackBar(result['message'] ?? '密码修改成功');
        } else {
          _showSnackBar(result['message'] ?? '密码修改失败');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('密码修改失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 头像
                  _buildAvatar(),
                  const SizedBox(height: 24),

                  // 信息列表
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    final initial = _getInitial(_currentUser);
    return CircleAvatar(
      radius: 50,
      backgroundColor: const Color(0xFF00D9A3),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getInitial(User user) {
    final name = user.realName?.trim().isNotEmpty == true
        ? user.realName!.trim()
        : (user.userName?.trim().isNotEmpty == true
              ? user.userName!.trim()
              : '');
    return name.isNotEmpty ? name[0].toUpperCase() : '用';
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildInfoItem(
            icon: Icons.badge,
            title: '姓名',
            value: _currentUser.realName ?? '未设置',
            onTap: () =>
                _editField('姓名', _currentUser.realName ?? '', 'realName'),
          ),
          const Divider(height: 1),

          _buildInfoItem(
            icon: Icons.email,
            title: '邮箱',
            value: _currentUser.email ?? '未设置',
            onTap: () => _editField('邮箱', _currentUser.email ?? '', 'email'),
          ),
          const Divider(height: 1),

          _buildInfoItem(
            icon: Icons.phone,
            title: '电话号码',
            value: _currentUser.phoneNumber ?? '未设置',
            onTap: () => _editField(
              '电话号码',
              _currentUser.phoneNumber ?? '',
              'phoneNumber',
            ),
          ),
          const Divider(height: 1),

          _buildInfoItem(
            icon: Icons.business,
            title: '所属部门',
            value: _currentUser.deptName ?? '未设置',
            onTap: null, // 部门不可编辑
          ),
          const Divider(height: 1),

          _buildInfoItem(
            icon: Icons.lock,
            title: '密码',
            value: '********',
            onTap: _changePassword,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade300),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.edit, color: Colors.grey.shade400, size: 20)
          : null,
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
