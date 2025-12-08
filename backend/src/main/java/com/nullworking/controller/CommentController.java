package com.nullworking.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.CommentCreateRequest;
import com.nullworking.model.dto.CommentUpdateRequest;
import com.nullworking.service.CommentService;
import com.nullworking.util.JwtUtil;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/comments")
public class CommentController {

    @Autowired
    private CommentService commentService;

    @Autowired
    private JwtUtil jwtUtil;

    @PostMapping("")
    public ResponseEntity<ApiResponse<Integer>> createComment(@RequestBody CommentCreateRequest request, HttpServletRequest httpRequest) {
        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ResponseEntity.status(401).body(new ApiResponse<>(401, "Unauthorized", null));
        }

        ApiResponse<Integer> response = commentService.createComment(request, userId);
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else if (response.getCode() == 404) {
            return ResponseEntity.status(404).body(response);
        } else {
            return ResponseEntity.status(500).body(response);
        }
    }

    @Deprecated
    @PutMapping("/{commentId}")
    public ResponseEntity<ApiResponse<Void>> updateComment(@PathVariable("commentId") Integer commentId, @RequestBody CommentUpdateRequest request, HttpServletRequest httpRequest) {
        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ResponseEntity.status(401).body(new ApiResponse<>(401, "Unauthorized", null));
        }

        ApiResponse<Void> response = commentService.updateComment(commentId, request, userId);
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else if (response.getCode() == 404) {
            return ResponseEntity.status(404).body(response);
        } else {
            return ResponseEntity.status(500).body(response);
        }
    }

    @DeleteMapping("/{commentId}")
    public ResponseEntity<ApiResponse<Void>> deleteComment(@PathVariable("commentId") Integer commentId, HttpServletRequest httpRequest) {
        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ResponseEntity.status(401).body(new ApiResponse<>(401, "Unauthorized", null));
        }

        ApiResponse<Void> response = commentService.deleteComment(commentId, userId);
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else if (response.getCode() == 404) {
            return ResponseEntity.status(404).body(response);
        } else {
            return ResponseEntity.status(500).body(response);
        }
    }

    @GetMapping("/{logId}")
    public ApiResponse<java.util.Map<String, Object>> listComments(
            @PathVariable("logId") Integer logId,
            HttpServletRequest httpRequest) {

        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "Unauthorized: 无效的token或用户ID");
        }

        return commentService.listComments(logId);
    }
}
