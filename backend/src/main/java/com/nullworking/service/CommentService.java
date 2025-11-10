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

import jakarta.transaction.Transactional;

@Service
public class CommentService {

    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private LogRepository logRepository;

    @Transactional
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
        return ApiResponse.success(c.getId());
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
