import 'package:flutter/foundation.dart';
import 'package:nullworking/services/business/notification_business.dart';

class UnreadNotificationService {
  static final UnreadNotificationService _instance = UnreadNotificationService._internal();

  factory UnreadNotificationService() {
    return _instance;
  }

  UnreadNotificationService._internal();

  final NotificationBusiness _notificationBusiness = NotificationBusiness();
  final ValueNotifier<bool> hasUnread = ValueNotifier<bool>(false);

  Future<void> refreshUnreadStatus() async {
    final bool currentStatus = await _notificationBusiness.hasUnreadNotifications();
    if (hasUnread.value != currentStatus) {
      hasUnread.value = currentStatus;
    }
  }
}
