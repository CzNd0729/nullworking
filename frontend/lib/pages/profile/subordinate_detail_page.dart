import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/business/user_business.dart';

class SubordinateDetailPage extends StatefulWidget {
  final String userId;

  const SubordinateDetailPage({super.key, required this.userId});

  @override
  State<SubordinateDetailPage> createState() => _SubordinateDetailPageState();
}

class _SubordinateDetailPageState extends State<SubordinateDetailPage> {
  User? _subordinateUser;
  bool _isLoading = true;
  final UserBusiness _userBusiness = UserBusiness();

  @override
  void initState() {
    super.initState();
    _loadSubordinateUser();
  }

  Future<void> _loadSubordinateUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _userBusiness.getCurrentUserById(widget.userId);
      setState(() {
        _subordinateUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载员工信息失败: $e')));
      }
    }
  }

  String _getInitial(User? user) {
    if (user == null) return '?';
    final name = user.realName?.trim().isNotEmpty == true
        ? user.realName!.trim()
        : (user.userName?.trim().isNotEmpty == true
              ? user.userName!.trim()
              : '');
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('员工信息'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subordinateUser == null
          ? const Center(child: Text('未能加载员工信息'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 头像
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade200,
                    child: Text(
                      _getInitial(_subordinateUser),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 信息卡片
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoItem(
                          icon: Icons.badge,
                          title: '姓名',
                          value: _subordinateUser?.realName ?? '未设置',
                        ),
                        const Divider(height: 1),
                        _buildInfoItem(
                          icon: Icons.email,
                          title: '邮箱',
                          value: _subordinateUser?.email ?? '未设置',
                        ),
                        const Divider(height: 1),
                        _buildInfoItem(
                          icon: Icons.phone,
                          title: '电话号码',
                          value: _subordinateUser?.phoneNumber ?? '未设置',
                        ),
                        const Divider(height: 1),
                        _buildInfoItem(
                          icon: Icons.business,
                          title: '所属部门',
                          value: _subordinateUser?.deptName ?? '未设置',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
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
    );
  }
}
