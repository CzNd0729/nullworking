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

import java.io.IOException;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private RestTemplate restTemplate;

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
    public void createNotification(Integer receiverId, String content, String relatedType, Integer relatedId) {
        Notification notification = new Notification();
        notification.setReceiverId(receiverId);
        notification.setContent(content);
        notification.setRelatedType(relatedType);
        notification.setRelatedId(relatedId);
        notification.setIsRead(false); // 默认为未读
        notification.setCreationTime(LocalDateTime.now());
        notificationRepository.save(notification);
    }

    /**
     * 发送华为推送通知
     * @param messageBody 推送的原始消息体，直接作为华为推送API的请求体
     */
    public void sendHuaweiPushNotification(Map<String, Object> messageBody) {
        try {
            String jwt = JsonWebTokenFactory.createJwt();
            String pushUrl = String.format(HUAWEI_PUSH_URL, huaweiPushAppId);

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

        List<Notification> notificationsToUpdate = new ArrayList<>();
        List<Map<String, Object>> allNotifications = new ArrayList<>();

        for (Notification notification : rawNotifications) {
            Map<String, Object> notificationData = new HashMap<>();
            notificationData.put("content", notification.getContent());
            notificationData.put("isRead", notification.getIsRead());
            notificationData.put("creationTime", notification.getCreationTime());

            if ("task".equalsIgnoreCase(notification.getRelatedType())) {
                notificationData.put("taskId", notification.getRelatedId());
            } else if ("log".equalsIgnoreCase(notification.getRelatedType())) {
                notificationData.put("logId", notification.getRelatedId());
            }

            allNotifications.add(notificationData);

            // 如果通知未读，则标记为已读并加入更新列表
            if (!notification.getIsRead()) {
                notification.setIsRead(true);
                notificationsToUpdate.add(notification);
            }
        }

        // 批量保存已更新的通知
        if (!notificationsToUpdate.isEmpty()) {
            notificationRepository.saveAll(notificationsToUpdate);
        }

        return ApiResponse.success(allNotifications);
    }
}
