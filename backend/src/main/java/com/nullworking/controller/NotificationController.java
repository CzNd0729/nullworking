package com.nullworking.controller;

import com.nullworking.common.ApiResponse;
import com.nullworking.service.NotificationService;
import com.nullworking.util.JwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
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
}
