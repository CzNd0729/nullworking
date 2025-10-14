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

import com.nullworking.model.Task;
import com.nullworking.model.TaskExecutorRelation;
import com.nullworking.model.User;
import com.nullworking.repository.LogRepository;
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
    private LogRepository logRepository;

    @Autowired
    private TaskExecutorRelationRepository taskExecutorRelationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @Operation(summary = "删除任务(软删除)", description = "根据任务ID将任务标记为已删除，返回code：200成功，208已删除，404不存在，500失败")
    @DeleteMapping("/deleteTask")
    @Transactional
    public Map<String, Object> deleteTask(@RequestParam("taskID") Integer taskId) {
        Map<String, Object> result = new HashMap<>();
        Optional<Task> taskOpt = taskRepository.findById(taskId);
        if (taskOpt.isEmpty()) {
            result.put("code", 404);
            return result;
        }
        try {
            Task task = taskOpt.get();
            if (Boolean.TRUE.equals(task.getIsDeleted())) {
                // 已经是删除状态，返回已删除标识码
                result.put("code", 208);
                return result;
            }
            task.setIsDeleted(true);
            task.setDeletedTime(LocalDateTime.now());
            taskRepository.save(task);

            // 同步镜像标记到日志与负责人关联表
            logRepository.markTaskDeleted(taskId);
            taskExecutorRelationRepository.markTaskDeleted(taskId);

            result.put("code", 200);
        } catch (Exception e) {
            result.put("code", 500);
        }
        return result;
    }

    @Operation(summary = "查看任务", description = "返回当前用户创建与参与的未删除任务列表，完成任务包含finishTime")
    @GetMapping("/ListUserTasks")
    public Map<String, Object> listUserTasks(HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        String authorizationHeader = request.getHeader("Authorization");
        String jwt = null;
        Integer userId = null;

        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            jwt = authorizationHeader.substring(7);
            userId = jwtUtil.extractUserId(jwt);
        }

        if (userId == null) {
            result.put("code", 401);
            result.put("message", "未授权或Token无效");
            return result;
        }

        List<Task> createdTasks = taskRepository.findByCreator_UserIdAndIsDeletedFalse(userId);
        List<Integer> executingTaskIds = taskExecutorRelationRepository.findActiveTaskIdsByExecutor(userId);
        Set<Integer> executingIdSet = new HashSet<>(executingTaskIds);
        List<Task> executingTasks = executingIdSet.isEmpty() ? Collections.emptyList()
                : taskRepository.findAllById(executingIdSet).stream()
                .filter(t -> Boolean.FALSE.equals(t.getIsDeleted()))
                .collect(Collectors.toList());

        Map<String, Object> data = new HashMap<>();
        data.put("created", createdTasks.stream().map(this::toDtoWithExecutors).collect(Collectors.toList()));
        data.put("participated", executingTasks.stream().map(this::toDtoWithExecutors).collect(Collectors.toList()));

        result.put("code", 200);
        result.put("data", data);
        return result;
    }

    private Map<String, Object> toDto(Task t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("taskID", String.valueOf(t.getTaskId()));
        m.put("creatorID", t.getCreator() != null ? String.valueOf(t.getCreator().getUserId()) : null);
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
        List<String> executorIds = taskExecutorRelationRepository
                .findActiveExecutorIdsByTaskId(t.getTaskId())
                .stream()
                .map(String::valueOf)
                .collect(Collectors.toList());
        m.put("executorIDs", executorIds);
        return m;
    }

    @Operation(summary = "发布任务", description = "创建新任务并分配多个执行者，优先级0-3，创建者从Token获取，返回code：200成功，400参数错误，404创建者不存在，500失败")
    @PostMapping("/publishTask")
    public Map<String, Object> publishTask(
            HttpServletRequest request,
            @RequestParam("title") String title,
            @RequestParam("content") String content,
            @RequestParam("priority") Integer priority,
            @RequestParam("executorIDs") List<Integer> executorIDs,
            @RequestParam("deadline") LocalDateTime deadline) {

        Map<String, Object> result = new HashMap<>();
        String authorizationHeader = request.getHeader("Authorization");
        String jwt = null;
        Integer creatorID = null;

        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            jwt = authorizationHeader.substring(7);
            creatorID = jwtUtil.extractUserId(jwt);
        }

        if (creatorID == null) {
            result.put("code", 401);
            result.put("message", "未授权或Token无效");
            return result;
        }

        try {
            // 验证优先级范围 (0-3)
            if (priority < 0 || priority > 3) {
                result.put("code", 400);
                result.put("message", "优先级必须在0-3之间");
                return result;
            }

            // 验证创建者是否存在
            Optional<User> creatorOpt = userRepository.findById(creatorID);
            if (creatorOpt.isEmpty()) {
                result.put("code", 404);
                result.put("message", "创建者不存在");
                return result;
            }

            // 验证执行者是否都存在
            for (Integer executorID : executorIDs) {
                Optional<User> executorOpt = userRepository.findById(executorID);
                if (executorOpt.isEmpty()) {
                    result.put("code", 404);
                    result.put("message", "执行者ID " + executorID + " 不存在");
                    return result;
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
            task.setIsDeleted(false);

            // 保存任务
            Task savedTask = taskRepository.save(task);

            // 创建执行者关联关系
            for (Integer executorID : executorIDs) {
                User executor = userRepository.findById(executorID).get();
                TaskExecutorRelation relation = new TaskExecutorRelation();
                relation.setTask(savedTask);
                relation.setExecutor(executor);
                relation.setTaskIsDeleted(false);
                taskExecutorRelationRepository.save(relation);
            }

            result.put("code", 200);
            result.put("message", "任务发布成功");
            result.put("taskID", savedTask.getTaskId());

        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "任务发布失败: " + e.getMessage());
        }

        return result;
    }

    @Operation(summary = "更新任务", description = "更新任务信息，优先级0-3，返回code：200成功，400参数错误，404任务不存在，500失败")
    @PutMapping("/updateTask")
    public Map<String, Object> updateTask(
            @RequestParam("taskID") Integer taskID,
            @RequestParam("title") String title,
            @RequestParam("content") String content,
            @RequestParam("priority") Integer priority,
            @RequestParam("deadline") LocalDateTime deadline) {

        Map<String, Object> result = new HashMap<>();

        try {
            // 验证优先级范围 (0-3)
            if (priority < 0 || priority > 3) {
                result.put("code", 400);
                result.put("message", "优先级必须在0-3之间");
                return result;
            }

            // 查找任务
            Optional<Task> taskOpt = taskRepository.findById(taskID);
            if (taskOpt.isEmpty()) {
                result.put("code", 404);
                result.put("message", "任务不存在");
                return result;
            }

            Task task = taskOpt.get();

            // 检查任务是否已被删除
            if (Boolean.TRUE.equals(task.getIsDeleted())) {
                result.put("code", 404);
                result.put("message", "任务已被删除");
                return result;
            }

            // 更新任务信息
            task.setTaskTitle(title);
            task.setTaskContent(content);
            task.setPriority(priority.byteValue());
            task.setDeadline(deadline);

            // 保存更新后的任务
            taskRepository.save(task);

            result.put("code", 200);
            result.put("message", "任务更新成功");
            result.put("taskID", task.getTaskId());

        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "任务更新失败: " + e.getMessage());
        }

        return result;
    }
}
