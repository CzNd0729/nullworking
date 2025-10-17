package com.nullworking.controller;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

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
import com.nullworking.model.Task;
import com.nullworking.model.TaskExecutorRelation;
import com.nullworking.model.User;
import com.nullworking.repository.TaskExecutorRelationRepository;
import com.nullworking.repository.TaskRepository;
import com.nullworking.repository.UserRepository;
import com.nullworking.util.JwtUtil;

import io.swagger.v3.oas.annotations.Operation;

@RestController
@RequestMapping("/api/task")
public class TaskController {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private TaskExecutorRelationRepository taskExecutorRelationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

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

        Optional<Task> taskOpt = taskRepository.findById(taskId);
        if (taskOpt.isEmpty()) {
            return ApiResponse.error(404, "任务不存在");
        }
        try {
            Task task = taskOpt.get();
            // 仅任务创建者可删除（关闭）
            if (task.getCreator() == null || task.getCreator().getUserId() == null || !task.getCreator().getUserId().equals(userId)) {
                return ApiResponse.error(403, "无权限删除此任务");
            }
            if (Byte.valueOf((byte)3).equals(task.getTaskStatus())) {
                // 已经是关闭状态
                return ApiResponse.error(208, "任务已关闭");
            }
            task.setTaskStatus((byte)3);
            taskRepository.save(task);

            return ApiResponse.success("任务删除成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "任务删除失败: " + e.getMessage());
        }
    }

    @Operation(summary = "查看任务", description = "返回当前用户创建与参与的未删除任务列表，完成任务包含finishTime")
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

        final Integer finalUserId = userId;

        List<Task> createdTasks = taskRepository.findByCreator_UserIdAndTaskStatusNot(userId, (byte)3);
        List<Integer> executingTaskIds = taskExecutorRelationRepository.findActiveTaskIdsByExecutor(userId);
        Set<Integer> executingIdSet = new HashSet<>(executingTaskIds);
        List<Task> executingTasks = executingIdSet.isEmpty() ? Collections.emptyList()
                : taskRepository.findAllById(executingIdSet).stream()
                .filter(t -> t.getTaskStatus() != null && t.getTaskStatus() != (byte)3)
                .filter(t -> t.getCreator() == null || t.getCreator().getUserId() == null || !t.getCreator().getUserId().equals(finalUserId)) // 排除自己创建的任务
                .collect(Collectors.toList());

        Map<String, Object> data = new HashMap<>();
        data.put("created", createdTasks.stream().map(this::toDtoWithExecutors).collect(Collectors.toList()));
        data.put("participated", executingTasks.stream().map(this::toDtoWithExecutors).collect(Collectors.toList()));

        return ApiResponse.success(data);
    }

    private Map<String, Object> toDto(Task t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("taskID", String.valueOf(t.getTaskId()));
        m.put("creatorName", t.getCreator() != null ? t.getCreator().getRealName() : null);
        m.put("taskTitle", t.getTaskTitle());
        m.put("taskContent", t.getTaskContent());
        m.put("taskPriority", String.valueOf(t.getPriority()));
        m.put("taskStatus", String.valueOf(t.getTaskStatus()));
        m.put("creationTime", t.getCreationTime() != null ? t.getCreationTime().toString() : null);
        m.put("deadline", t.getDeadline() != null ? t.getDeadline().toString() : null);
        if (Byte.valueOf((byte)2).equals(t.getTaskStatus())) {
            m.put("finishTime", t.getFinishTime() != null ? t.getFinishTime().toString() : null);
        }
        return m;
    }

    private Map<String, Object> toDtoWithExecutors(Task t) {
        Map<String, Object> m = toDto(t);
        List<String> executorNames = taskExecutorRelationRepository
                .findActiveExecutorIdsByTaskId(t.getTaskId())
                .stream()
                .map(id -> {
                    return userRepository.findById(id).map(User::getRealName).orElse(null);
                })
                .filter(n -> n != null)
                .filter(name -> !name.equals(t.getCreator() != null ? t.getCreator().getRealName() : null)) // 排除创建者
                .collect(Collectors.toList());
        m.put("executorNames", executorNames);
        return m;
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

        try {
            // 验证优先级范围 (0-3)
            if (priority < 0 || priority > 3) {
                return ApiResponse.error(400, "优先级必须在0-3之间");
            }

            // 验证创建者是否存在
            Optional<User> creatorOpt = userRepository.findById(creatorID);
            if (creatorOpt.isEmpty()) {
                return ApiResponse.error(404, "创建者不存在");
            }

            // 验证执行者是否都存在
            for (Integer executorID : executorIDs) {
                Optional<User> executorOpt = userRepository.findById(executorID);
                if (executorOpt.isEmpty()) {
                    return ApiResponse.error(404, "执行者ID " + executorID + " 不存在");
                }
            }

            // 创建任务
            Task task = new Task();
            task.setCreator(creatorOpt.get());
            task.setTaskTitle(title);
            task.setTaskContent(content);
            task.setPriority(priority.byteValue());
            task.setTaskStatus((byte) 0); // 0-待开始
            task.setCreationTime(LocalDateTime.now());
            task.setDeadline(deadline);

            // 保存任务
            Task savedTask = taskRepository.save(task);

            // 创建执行者关联关系
            for (Integer executorID : executorIDs) {
                User executor = userRepository.findById(executorID).get();
                TaskExecutorRelation relation = new TaskExecutorRelation();
                relation.setTask(savedTask);
                relation.setExecutor(executor);
                taskExecutorRelationRepository.save(relation);
            }
            Map<String, Object> data = new HashMap<>();
            data.put("taskID", savedTask.getTaskId());
            return ApiResponse.success(data);

        } catch (Exception e) {
            return ApiResponse.error(500, "任务发布失败: " + e.getMessage());
        }
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

        try {
            // 验证优先级范围 (0-3)
            if (priority < 0 || priority > 3) {
                return ApiResponse.error(400, "优先级必须在0-3之间");
            }

            // 查找任务
            Optional<Task> taskOpt = taskRepository.findById(taskID);
            if (taskOpt.isEmpty()) {
                return ApiResponse.error(404, "任务不存在");
            }

            Task task = taskOpt.get();

            // 仅创建者可更新
            if (task.getCreator() == null || task.getCreator().getUserId() == null || !task.getCreator().getUserId().equals(userId)) {
                return ApiResponse.error(403, "无权限更新此任务");
            }

            // 检查任务是否已关闭
            if (Byte.valueOf((byte)3).equals(task.getTaskStatus())) {
                return ApiResponse.error(404, "任务已关闭");
            }

            // 更新任务信息
            task.setTaskTitle(title);
            task.setTaskContent(content);
            task.setPriority(priority.byteValue());
            task.setDeadline(deadline);

            // 保存更新后的任务
            taskRepository.save(task);
            Map<String, Object> data = new HashMap<>();
            data.put("taskID", task.getTaskId());
            return ApiResponse.success(data);

        } catch (Exception e) {
            return ApiResponse.error(500, "任务更新失败: " + e.getMessage());
        }
    }
}
