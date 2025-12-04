package com.nullworking.controller;

import com.nullworking.common.ApiResponse;
import com.nullworking.service.NotificationService;
import com.nullworking.util.JwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notification")
public class NotificationController {

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private NotificationService notificationService;

    @Operation(summary = "获取用户所有通知", description = "从token解析用户ID，查询该用户所有通知，并依靠isRead字段来判别已读状态，按时间从近到远排序")
    @GetMapping("")
    public ApiResponse<List<Map<String, Object>>> getUserNotifications(HttpServletRequest request) {
        Integer userId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权，请登录");
        }
        try {
            return notificationService.getUserNotifications(userId);
        } catch (Exception e) {
            return ApiResponse.error(500, "服务器错误: " + e.getMessage());
        }
    }

    @Deprecated
    @Operation(summary = "发送华为推送通知示例", description = "接收华为推送标准JSON消息体，并调用华为推送服务发送通知")
    @PostMapping("/send-huawei-push-example")
    public ApiResponse<String> sendPushNotificationExample(@RequestBody Map<String, Object> huaweiPushPayload) {
        try {
            notificationService.sendHuaweiPushNotification(huaweiPushPayload);
            return ApiResponse.success("华为推送通知已发送");
        } catch (Exception e) {
            return ApiResponse.error(500, "发送华为推送通知失败: " + e.getMessage());
        }
    }

    @Operation(summary = "将通知标记为已读", description = "从token解析用户ID，将指定ID的通知标记为已读")
    @PutMapping("/{notificationId}/read")
    public ApiResponse<Void> markNotificationAsRead(
            @PathVariable("notificationId") Integer notificationId,
            HttpServletRequest request) {
        Integer userId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权，请登录");
        }
        try {
            return notificationService.markNotificationAsRead(notificationId, userId);
        } catch (Exception e) {
            return ApiResponse.error(500, "服务器错误: " + e.getMessage());
        }
    }

    @Operation(summary = "查询用户是否有未读通知", description = "从token解析用户ID，查询该用户是否有未读通知")
    @GetMapping("/unreadStatus")
    public ApiResponse<Map<String, Boolean>> hasUnreadNotifications(HttpServletRequest request) {
        Integer userId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权，请登录");
        }
        try {
            return notificationService.hasUnreadNotifications(userId);
        } catch (Exception e) {
            return ApiResponse.error(500, "服务器错误: " + e.getMessage());
        }
    }
}
