import 'package:http/http.dart' as http;
import 'base_api.dart';

class NotificationApi {
  final BaseApi _baseApi = BaseApi();

  Future<http.Response> getNotifications() async {
    return await _baseApi.get('api/notification');
  }

  Future<http.Response> markNotificationAsRead(String notificationId) async {
    return await _baseApi.put('api/notification/$notificationId/read');
  }

  Future<http.Response> getUnreadStatus() async {
    return await _baseApi.get('api/notification/unreadStatus');
  }
}
