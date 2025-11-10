import 'package:flutter/material.dart';
import '../../models/user.dart';

class SubordinateDetailPage extends StatelessWidget {
  final User user;

  const SubordinateDetailPage({super.key, required this.user});

  String _getInitial(User user) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 头像
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade200,
              child: Text(
                _getInitial(user),
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
                    icon: Icons.person,
                    title: '用户名',
                    value: user.userName ?? '未设置',
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    icon: Icons.badge,
                    title: '真实姓名',
                    value: user.realName ?? '未设置',
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    icon: Icons.email,
                    title: '邮箱',
                    value: user.email ?? '未设置',
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    icon: Icons.phone,
                    title: '电话号码',
                    value: user.phoneNumber ?? '未设置',
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    icon: Icons.business,
                    title: '所属部门',
                    value: user.deptName ?? '未设置',
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
