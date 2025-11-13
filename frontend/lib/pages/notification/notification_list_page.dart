import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nullworking/models/notification.dart';
import 'package:nullworking/models/task.dart';
import 'package:nullworking/pages/log/log_detail_page.dart';
import 'package:nullworking/pages/task/task_detail_page.dart';
import 'package:nullworking/services/business/notification_business.dart';
import 'package:nullworking/services/business/task_business.dart';
import 'package:nullworking/services/notification_services/unread_notification_service.dart'; // 新增导入

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final NotificationBusiness _notificationBusiness = NotificationBusiness();
  final TaskBusiness _taskBusiness = TaskBusiness();
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _notificationBusiness.getAllNotifications();
  }

  Future<void> _navigateToDetail(NotificationModel notification) async {
    if (notification.taskId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final Task? task =
          await _taskBusiness.getTaskById(notification.taskId!.toString());

      Navigator.pop(context); // Dismiss loading dialog

      if (task != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(task: task),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法加载任务详情')),
        );
      }
    } else if (notification.logId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LogDetailPage(logId: notification.logId!.toString()),
        ),
      );
    }

    if (!notification.isRead) {
      await _notificationBusiness.markNotificationAsRead(notification.notificationId.toString());
      setState(() {
        notification.isRead = true;
      });
      // Refresh global unread status after marking a notification as read
      UnreadNotificationService().refreshUnreadStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知列表'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('没有通知'));
          } else {
            final notifications = snapshot.data!;
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(notification.content),
                    subtitle: Text(DateFormat('yyyy-MM-dd HH:mm')
                        .format(notification.creationTime)),
                    trailing: notification.isRead
                        ? null
                        : const Icon(Icons.circle,
                            color: Colors.blue, size: 12),
                    onTap: () => _navigateToDetail(notification),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
