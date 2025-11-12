package com.nullworking.service;

import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Comment;
import com.nullworking.model.Log;
import com.nullworking.model.dto.CommentCreateRequest;
import com.nullworking.model.dto.CommentUpdateRequest;
import com.nullworking.repository.CommentRepository;
import com.nullworking.repository.LogRepository;
import com.nullworking.repository.UserRepository; // 导入 UserRepository

import jakarta.transaction.Transactional;
import java.util.Objects;

@Service
public class CommentService {

    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private LogRepository logRepository;

    @Autowired
    private UserRepository userRepository; // 注入 UserRepository

    @Autowired
    private NotificationService notificationService; // 注入 NotificationService

    @Transactional
    @SuppressWarnings("null") // 抑制空类型安全警告
    public ApiResponse<Integer> createComment(CommentCreateRequest request, Integer userId) {
        // verify log exists
        Optional<Log> logOptional = logRepository.findById(request.getLogId());
        if (logOptional.isEmpty()) {
            return ApiResponse.error(404, "日志未找到");
        }

        Comment c = new Comment();
        c.setLogId(request.getLogId());
        c.setContent(request.getContent());
        c.setUserId(userId);
        c.setCreatedAt(LocalDateTime.now());
        c.setIsDeleted(0);

        commentRepository.save(c);

        // 获取被评论日志的拥有者 ID
        Integer logOwnerId = logOptional.get().getUser().getUserId();

        // 如果评论者不是日志拥有者，则发送通知
        if (!logOwnerId.equals(userId)) {
            String notificationContent = String.format("您的日志‘%s’收到了新评论：‘%s’", logOptional.get().getLogTitle(), request.getContent());
            notificationService.createNotification(Objects.requireNonNull(logOwnerId), notificationContent, "log", Objects.requireNonNull(c.getLogId())); // relatedType 应为 log，relatedId 为 logId
        }

        return ApiResponse.success((Integer) Objects.requireNonNull(c.getId()));
    }

    @Transactional
    public ApiResponse<Void> updateComment(Integer commentId, CommentUpdateRequest request, Integer userId) {
        Optional<Comment> commentOptional = commentRepository.findByIdAndUserIdAndIsDeletedFalse(commentId, userId);
        if (commentOptional.isEmpty()) {
            return ApiResponse.error(404, "评论未找到或无权限");
        }

        Comment c = commentOptional.get();
        if (request.getContent() != null) {
            c.setContent(request.getContent());
        }
        c.setUpdatedAt(LocalDateTime.now());
        commentRepository.save(c);
        return ApiResponse.success();
    }

    @Transactional
    public ApiResponse<Void> deleteComment(Integer commentId, Integer userId) {
        Optional<Comment> commentOptional = commentRepository.findByIdAndUserIdAndIsDeletedFalse(commentId, userId);
        if (commentOptional.isEmpty()) {
            return ApiResponse.error(404, "评论未找到或无权限");
        }

        Comment c = commentOptional.get();
        // 软删除：设置 isDeleted = 1 并更新更新时间
        c.setIsDeleted(1);
        c.setUpdatedAt(LocalDateTime.now());
        commentRepository.save(c);
        return ApiResponse.success();
    }

    public ApiResponse<java.util.Map<String, Object>> listComments(Integer logId) {
        java.util.List<Comment> list = commentRepository.findByLogIdAndIsDeletedFalseOrderByLatest(logId);

        java.util.List<java.util.Map<String, Object>> items = new java.util.ArrayList<>();
        for (Comment c : list) {
            java.util.Map<String, Object> m = new java.util.HashMap<>();
            m.put("id", c.getId());
            m.put("userId", c.getUserId());
            // 根据 userId 获取用户的 realName
            if (c.getUserId() != null) {
                userRepository.findById(c.getUserId()).ifPresent(user -> m.put("userName", user.getRealName()));
            }
            m.put("content", c.getContent());
            m.put("createdAt", c.getCreatedAt() != null ? c.getCreatedAt().toString() : null);
            m.put("updatedAt", c.getUpdatedAt() != null ? c.getUpdatedAt().toString() : null);
            items.add(m);
        }

        java.util.Map<String, Object> data = new java.util.HashMap<>();
        data.put("comments", items);

        return ApiResponse.success(data);
    }
}
