import 'package:flutter/material.dart';
import '../login/login_page.dart';
import 'user_detail_page.dart';
import 'subordinate_detail_page.dart';
import '../../services/business/auth_business.dart';
import '../../services/business/user_business.dart';
import '../../models/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthBusiness _authBusiness = AuthBusiness();
  final UserBusiness _userBusiness = UserBusiness();

  User? _currentUser;
  List<User> _subDeptUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userBusiness.getCurrentUser();
      final subUsers = await _userBusiness.getSubordinateUsers();

      setState(() {
        _currentUser = user;
        _subDeptUsers = subUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载数据失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await _authBusiness.logout();

              // 跳转到登录页面并移除所有之前的路由
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 用户信息卡片
                    _buildUserInfoCard(),
                    const SizedBox(height: 24),

                    // 下级员工列表
                    _buildSubDeptUsersSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (_currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetailPage(user: _currentUser!),
              ),
            ).then((_) => _loadData()); // 返回时刷新数据
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 头像
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade200,
                child: Text(
                  _currentUser?.realName?.substring(0, 1) ??
                      _currentUser?.userName?.substring(0, 1).toUpperCase() ??
                      '用',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 用户名
              Text(
                _currentUser?.realName ?? '未登录',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // 其他信息
              if (_currentUser?.phoneNumber != null)
                _buildInfoRow(Icons.phone, _currentUser!.phoneNumber!),
              if (_currentUser?.email != null)
                _buildInfoRow(Icons.email, _currentUser!.email!),
              if (_currentUser?.deptName != null)
                _buildInfoRow(Icons.business, _currentUser!.deptName!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildSubDeptUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              '我的下属 (${_subDeptUsers.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_subDeptUsers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  '暂无下级员工',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subDeptUsers.length,
            itemBuilder: (context, index) {
              final user = _subDeptUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubordinateDetailPage(userId: user.userId.toString()),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade200,
                      child: Text(
                        user.realName?.substring(0, 1) ??
                            user.userName?.substring(0, 1).toUpperCase() ??
                            '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(
                      user.realName ?? user.userName ?? '未知用户',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.deptName != null)
                          Text(
                            '部门: ${user.deptName}',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (user.phoneNumber != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.phoneNumber!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
