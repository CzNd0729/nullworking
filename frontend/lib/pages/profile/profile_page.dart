import 'package:flutter/material.dart';
import '../login/login_page.dart'; // 导入登录页面
import 'package:shared_preferences/shared_preferences.dart'; // 导入shared_preferences 用于清除用户ID

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
              // 清除本地存储的用户信息和token
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('userID');
              await prefs.remove('token'); // 假设token也存储在SharedPreferences中

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
      body: const Center(
        child: Text(
          '我的页面',
          style: TextStyle(fontSize: 24, color: Colors.white70),
        ),
      ),
    );
  }
}
