import 'package:flutter/material.dart';
import 'package:huawei_push/huawei_push.dart';
import 'package:nullworking/services/api/user_api.dart';

class PushNotificationService {
  final UserApi _userApi = UserApi();

  Future<void> init() async {
    await Push.turnOnPush();
    // 注册 token 监听
    Push.getTokenStream.listen(_onTokenEvent, onError: _onTokenError);
    // 触发 token 获取
    Push.getToken("");
  }

  void _onTokenEvent(String token) {
    debugPrint("Push Token: $token");

    _userApi.updatePushToken(token).then((response) {
      if (response.statusCode == 200) {
        debugPrint("Push token updated successfully.");
      } else {
        debugPrint("Failed to update push token: ${response.statusCode} ${response.body}");
      }
    }).catchError((error) {
      debugPrint("Error updating push token: $error");
    });
  }

  void _onTokenError(Object error) {
    debugPrint("Push Token Error: $error");
  }

  static void backgroundMessageCallback(RemoteMessage remoteMessage) async {
    debugPrint('backgroundMessageCallback: ${remoteMessage.messageId}');
  }

  Future<void> deleteToken() async {
    try {
      await Push.deleteToken("");
      debugPrint("Push token deleted from Huawei Push service.");

      // Call the API to update the push token to an empty string
      final response = await _userApi.updatePushToken('');
      if (response.statusCode == 200) {
        debugPrint("Push token successfully removed from backend.");
      } else {
        debugPrint(
            "Failed to remove push token from backend: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("Error deleting push token: $e");
    }
  }
}
