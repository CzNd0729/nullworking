import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nullworking/services/api/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (mounted) {
      if (userId != null && userId.isNotEmpty) {
        final statusCode = await _authService.checkHealth();
        if (statusCode == 403) {
          await _authService.logout();
          Navigator.of(context).pushReplacementNamed(
            '/login',
            arguments: {'message': '登录信息已过期'},
          );
        } else if (statusCode == 200) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Handle other error codes by logging out and going to login
          await _authService.logout();
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
