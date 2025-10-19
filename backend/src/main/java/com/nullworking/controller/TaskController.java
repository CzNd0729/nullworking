package com.nullworking.controller;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import jakarta.servlet.http.HttpServletRequest;

import com.nullworking.common.ApiResponse;
import com.nullworking.service.TaskService;
import com.nullworking.util.JwtUtil;

import io.swagger.v3.oas.annotations.Operation;

@RestController
@RequestMapping("/api/task")
public class TaskController {

    // @Autowired
    // private TaskRepository taskRepository;

    // @Autowired
    // private TaskExecutorRelationRepository taskExecutorRelationRepository;

    // @Autowired
    // private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private TaskService taskService;

    @Operation(summary = "删除任务(关闭)", description = "根据任务ID将任务状态置为3=已关闭，仅创建者可操作，返回code：200成功，208已关闭，401未授权，403无权限，404不存在，500失败")
    @DeleteMapping("/deleteTask")
    @Transactional
    public ApiResponse<String> deleteTask(@RequestParam("taskID") Integer taskId, HttpServletRequest request) {
        // 从Token解析当前用户
        String authorizationHeader = request.getHeader("Authorization");
        String jwt;
        Integer userId = null;
        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            jwt = authorizationHeader.substring(7);
            userId = jwtUtil.extractUserId(jwt);
        }
        if (userId == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }
        return taskService.deleteTask(taskId, userId);
    }

    @Operation(summary = "查看任务", description = "返回当前用户创建与参与的任务列表（默认包含已删除任务），完成任务包含finishTime")
    @GetMapping("/listUserTasks")
    public ApiResponse<Map<String, Object>> listUserTasks(HttpServletRequest request) {
        String authorizationHeader = request.getHeader("Authorization");
        String jwt;
        Integer userId = null;

        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            jwt = authorizationHeader.substring(7);
            userId = jwtUtil.extractUserId(jwt);
        }

        if (userId == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }

        return taskService.listUserTasks(userId);
    }

    @Operation(summary = "发布任务", description = "创建新任务并分配多个执行者，优先级0-3，创建者从Token获取，返回code：200成功，400参数错误，404创建者不存在，500失败")
    @PostMapping("/publishTask")
    public ApiResponse<Map<String, Object>> publishTask(
            HttpServletRequest request,
            @RequestParam("title") String title,
            @RequestParam("content") String content,
            @RequestParam("priority") Integer priority,
            @RequestParam("executorIDs") List<Integer> executorIDs,
            @RequestParam("deadline") LocalDateTime deadline) {

        String authorizationHeader = request.getHeader("Authorization");
        String jwt;
        Integer creatorID = null;

        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            jwt = authorizationHeader.substring(7);
            creatorID = jwtUtil.extractUserId(jwt);
        }

        if (creatorID == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }
        return taskService.publishTask(creatorID, title, content, priority, executorIDs, deadline);
    }

    @Operation(summary = "更新任务", description = "仅创建者可更新任务信息，优先级0-3，返回code：200成功，400参数错误，401未授权，403无权限，404任务不存在，500失败")
    @PutMapping("/updateTask")
    public ApiResponse<Map<String, Object>> updateTask(
            HttpServletRequest request,
            @RequestParam("taskID") Integer taskID,
            @RequestParam("title") String title,
            @RequestParam("content") String content,
            @RequestParam("priority") Integer priority,
            @RequestParam("deadline") LocalDateTime deadline) {

        // 从Token解析当前用户
        String authorizationHeader = request.getHeader("Authorization");
        String jwt;
        Integer userId = null;
        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            jwt = authorizationHeader.substring(7);
            userId = jwtUtil.extractUserId(jwt);
        }
        if (userId == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }
        return taskService.updateTask(taskID, title, content, priority, deadline, userId);
    }
}
