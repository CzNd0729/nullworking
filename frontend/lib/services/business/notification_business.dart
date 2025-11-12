import 'dart:convert';
import 'package:nullworking/models/notification.dart';
import 'package:nullworking/services/api/notification_api.dart';

class NotificationBusiness {
  final NotificationApi _notificationApi = NotificationApi();

  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      final response = await _notificationApi.getNotifications();
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final List<dynamic> notificationsJson = responseData['data'] as List<dynamic>;
          return notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              // .where((notification) => !notification.isRead) // 筛选未读通知
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('获取未读通知异常: $e');
      return [];
    }
  }

  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final response = await _notificationApi.getNotifications();
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final List<dynamic> notificationsJson = responseData['data'] as List<dynamic>;
          return notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('获取所有通知异常: $e');
      return [];
    }
  }
}
