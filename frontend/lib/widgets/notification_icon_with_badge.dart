import 'package:flutter/material.dart';
import 'package:nullworking/pages/notification/notification_list_page.dart';
import 'package:nullworking/services/business/notification_business.dart';
import 'package:nullworking/services/notification_services/unread_notification_service.dart'; // Import the new service

class NotificationIconWithBadge extends StatefulWidget {
  const NotificationIconWithBadge({super.key});

  @override
  State<NotificationIconWithBadge> createState() => _NotificationIconWithBadgeState();
}

class _NotificationIconWithBadgeState extends State<NotificationIconWithBadge> {
  // final NotificationBusiness _notificationBusiness = NotificationBusiness(); // No longer needed directly
  // bool _hasUnreadNotifications = false; // No longer needed, managed by service
  final UnreadNotificationService _unreadNotificationService = UnreadNotificationService(); // Get service instance

  @override
  void initState() {
    super.initState();
    _unreadNotificationService.refreshUnreadStatus(); // Initial refresh
  }

  // _checkUnreadStatus is now handled by the service and its ValueNotifier
  // Future<void> _checkUnreadStatus() async {
  //   final hasUnread = await _notificationBusiness.hasUnreadNotifications();
  //   if (mounted) {
  //     setState(() {
  //       _hasUnreadNotifications = hasUnread;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _unreadNotificationService.hasUnread,
      builder: (context, hasUnread, child) {
        return Stack(
          children: [
            IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationListPage(),
                  ),
                );
                _unreadNotificationService.refreshUnreadStatus(); // Refresh status when returning from notification list
              },
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            if (hasUnread)
              const Positioned(
                right: 11,
                top: 11,
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
          ],
        );
      },
    );
  }
}
