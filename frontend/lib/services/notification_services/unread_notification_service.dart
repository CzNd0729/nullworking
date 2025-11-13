import 'package:flutter/foundation.dart';
import 'package:nullworking/services/business/notification_business.dart';
import 'package:nullworking/services/notification_services/notification_service.dart';
import 'dart:async';

class UnreadNotificationService {
  static final UnreadNotificationService _instance = UnreadNotificationService._internal();

  factory UnreadNotificationService() {
    return _instance;
  }

  UnreadNotificationService._internal() {
    // Start the timer to refresh unread status every 3 seconds
    Timer.periodic(const Duration(seconds: 3), (timer) {
      refreshUnreadStatus();
    });
  }

  final NotificationBusiness _notificationBusiness = NotificationBusiness();
  final NotificationService _notificationService = NotificationService();
  final ValueNotifier<bool> hasUnread = ValueNotifier<bool>(false);

  Future<void> refreshUnreadStatus() async {
    final latestNotification = await _notificationBusiness.getLatestUnreadNotification();
    final bool currentStatus = latestNotification != null;

    if (hasUnread.value != currentStatus) {
      hasUnread.value = currentStatus;
    }

    if (currentStatus) {
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(latestNotification.creationTime);

      if (difference.inSeconds <= 3) {
        _notificationService.showNotification('您收到了新通知', latestNotification.content);
      }
    }
  }
}
