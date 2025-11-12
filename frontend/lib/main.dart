import 'package:flutter/material.dart';
import 'pages/log/log_page.dart';
import 'pages/task/tasks_page.dart';
import 'pages/mindmap/mindmap_page.dart';
import 'pages/ai_analysis/ai_analysis_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/login/login_page.dart';
import 'pages/splash_page.dart';
import 'services/notification_service.dart';
import 'services/business/notification_business.dart'; // 新增导入
import 'dart:async'; // 新增导入

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NullWorking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1E1E1E),
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D9A3),
          secondary: Color(0xFF00D9A3),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF000000),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF000000),
          selectedItemColor: Color(0xFF00D9A3),
          unselectedItemColor: Color(0xFF666666),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainPage(),
      },
      home: const SplashPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 2;
  final NotificationBusiness _notificationBusiness = NotificationBusiness(); // 新增
  Timer? _notificationTimer; // 新增

  @override
  void initState() {
    super.initState();
    _startNotificationPolling(); // 启动通知轮询
  }

  @override
  void dispose() {
    _notificationTimer?.cancel(); // 取消定时器
    super.dispose();
  }

  void _startNotificationPolling() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final unreadNotifications = await _notificationBusiness.getUnreadNotifications();
        for (var notification in unreadNotifications) {
          NotificationService().showNotification(
            '新通知',
            notification.content,
            payload: notification.taskId != null ? notification.taskId.toString() : null,
          );
        }
      } catch (e) {
        print('获取通知失败: $e');
      }
    });
  }

  final List<Widget> _pages = [
    const LogPage(),
    const TasksPage(),
    const MindMapPage(),
    const AIAnalysisPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: '日志',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: '任务',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: '导图',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'AI分析',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
