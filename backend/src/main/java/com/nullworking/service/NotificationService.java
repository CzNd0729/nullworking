package com.nullworking.service;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Notification;
import com.nullworking.repository.NotificationRepository;
import com.nullworking.util.JsonWebTokenFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.lang.Nullable;

import java.io.IOException;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Collections;
import java.util.Objects; // 导入 Objects
import java.util.Optional;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private RestTemplate restTemplate;

    @Autowired
    private UserService userService; // 注入 UserService

    @Value("${huawei.push.appId}")
    private String huaweiPushAppId;

    private static final String HUAWEI_PUSH_URL = "https://push-api.cloud.huawei.com/v3/%s/messages:send";

    /**
     * 创建通知
     * @param receiverId 接收通知的用户ID
     * @param content 通知文本内容
     * @param relatedType 关联对象类型（log=日志，task=任务，comment=评论等）
     * @param relatedId 关联对象的ID
     */
    public void createNotification(Integer receiverId, String content, @Nullable String relatedType, @Nullable Integer relatedId) {
        Notification notification = new Notification();
        notification.setReceiverId(receiverId);
        notification.setContent(content);
        notification.setRelatedType(relatedType);
        notification.setRelatedId(relatedId);
        notification.setIsRead(false); // 默认为未读
        notification.setCreationTime(LocalDateTime.now());
        notificationRepository.save(notification);

        // 获取接收者的推送 token
        String pushToken = userService.getHuaweiPushTokenByUserId(receiverId);
        if (pushToken != null && !pushToken.trim().isEmpty()) {
            // 构建华为推送消息体
            Map<String, Object> messageBody = new HashMap<>();
            Map<String, Object> notificationPayload = new HashMap<>();
            notificationPayload.put("category", "WORK");
            notificationPayload.put("title", "您收到了新通知"); // 可以根据实际情况调整标题
            notificationPayload.put("body", content);
            Map<String, Object> clickAction = new HashMap<>();
            clickAction.put("actionType", 0);
            notificationPayload.put("clickAction", clickAction);
            notificationPayload.put("style", 0);

            Map<String, Object> payload = new HashMap<>();
            payload.put("notification", notificationPayload);
            
            Map<String, Object> target = new HashMap<>();
            target.put("token", Collections.singletonList(Objects.requireNonNull(pushToken))); // 确保 pushToken 非空

            messageBody.put("payload", payload);
            messageBody.put("target", target);
            
            sendHuaweiPushNotification(messageBody);
        }
    }

    /**
     * 发送华为推送通知
     * @param messageBody 推送的原始消息体，直接作为华为推送API的请求体
     */
    public void sendHuaweiPushNotification(Map<String, Object> messageBody) {
        try {
            String jwt = Objects.requireNonNull(JsonWebTokenFactory.createJwt(), "JWT token must not be null");
            String pushUrl = Objects.requireNonNull(String.format(HUAWEI_PUSH_URL, huaweiPushAppId), "Push URL must not be null");

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(jwt);
            headers.set("Push-Type", "0");

            ObjectMapper objectMapper = new ObjectMapper();
            HttpEntity<String> request = new HttpEntity<>(objectMapper.writeValueAsString(messageBody), headers);

            ResponseEntity<String> response = restTemplate.postForEntity(pushUrl, request, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                System.out.println("Huawei Push Notification sent successfully: " + response.getBody());
            } else {
                System.err.println("Failed to send Huawei Push Notification: " + response.getStatusCode() + " - " + response.getBody());
                throw new RuntimeException("Failed to send Huawei Push Notification: " + response.getBody());
            }

        } catch (NoSuchAlgorithmException | InvalidKeySpecException | IOException | NullPointerException e) {
            System.err.println("Error creating JWT or sending Huawei Push Notification: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Error creating JWT or sending Huawei Push Notification: " + e.getMessage(), e);
        }
    }

    /**
     * 获取用户所有通知，并根据已读状态分类，按时间从近到远排序。
     * 查询后将所有通知标记为已读。
     * @param userId 用户ID
     * @return 包含所有通知的列表
     */
    @Transactional
    public ApiResponse<List<Map<String, Object>>> getUserNotifications(Integer userId) {
        List<Notification> rawNotifications = notificationRepository.findByReceiverIdOrderByCreationTimeDesc(userId);

        List<Map<String, Object>> allNotifications = new ArrayList<>();

        for (Notification notification : rawNotifications) {
            Map<String, Object> notificationData = new HashMap<>();
            notificationData.put("notificationId",notification.getId());
            notificationData.put("content", notification.getContent());
            notificationData.put("isRead", notification.getIsRead());
            notificationData.put("creationTime", notification.getCreationTime());

            if ("task".equalsIgnoreCase(notification.getRelatedType())) {
                notificationData.put("taskId", notification.getRelatedId());
            } else if ("log".equalsIgnoreCase(notification.getRelatedType())) {
                notificationData.put("logId", notification.getRelatedId());
            }

            allNotifications.add(notificationData);
        }
        return ApiResponse.success(allNotifications);
    }

    /**
     * 将指定通知标记为已读
     * @param notificationId 通知ID
     * @param userId 当前用户ID，用于权限校验
     * @return 操作结果
     */
    @Transactional
    public ApiResponse<Void> markNotificationAsRead(Integer notificationId, Integer userId) {
        // 查找通知
        Optional<Notification> notificationOptional = notificationRepository.findById(Objects.requireNonNull(notificationId));
        if (notificationOptional.isEmpty()) {
            return ApiResponse.error(404, "通知未找到");
        }

        Notification notification = notificationOptional.get();

        // 检查用户是否有权限修改该通知
        if (!Objects.requireNonNull(notification.getReceiverId()).equals(userId)) {
            return ApiResponse.error(403, "无权限修改该通知");
        }

        // 标记为已读
        notification.setIsRead(true);
        notificationRepository.save(notification);

        return ApiResponse.success();
    }

    /**
     * 查询当前用户是否有未读通知
     * @param userId 用户ID
     * @return 包含是否有未读通知的响应
     */
    public ApiResponse<Map<String, Boolean>> hasUnreadNotifications(Integer userId) {
        Map<String, Boolean> data = new HashMap<>();
        boolean hasUnread = notificationRepository.existsByReceiverIdAndIsReadFalse(Objects.requireNonNull(userId));
        data.put("hasUnread", hasUnread);
        return ApiResponse.success(data);
    }
}
