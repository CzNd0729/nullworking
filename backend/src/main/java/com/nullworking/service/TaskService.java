package com.nullworking.service;

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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.scheduling.annotation.Scheduled; 

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Task;
import com.nullworking.model.TaskExecutorRelation;
import com.nullworking.model.User;
import com.nullworking.model.dto.TaskPublishRequest;
import com.nullworking.model.dto.TaskUpdateRequest;
import com.nullworking.repository.TaskExecutorRelationRepository;
import com.nullworking.repository.TaskRepository;
import com.nullworking.repository.UserRepository;
import com.nullworking.service.PermissionService;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit; 
import com.nullworking.model.Log;
import com.nullworking.repository.LogRepository;
import com.nullworking.service.NotificationService;

@Service
public class TaskService {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private TaskExecutorRelationRepository taskExecutorRelationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private LogService logService;
    
    @Autowired
    private LogRepository logRepository;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private PermissionService permissionService;

    // 所有的业务逻辑将在这里实现

    @Scheduled(fixedRate = 60000) 
    @Transactional
    public void scheduleDeadlineNotifications() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime oneHourLater = now.plus(1, ChronoUnit.HOURS);

        List<Task> approachingDeadlineTasks = taskRepository.findByDeadlineBetweenAndIsDeadlineNotifiedFalseAndTaskStatusNot(
            now, oneHourLater, (byte) 3
        );

        for (Task task : approachingDeadlineTasks) {
            List<Integer> executorIds = taskExecutorRelationRepository.findAllExecutorIdsByTaskId(task.getTaskId());
            Set<Integer> notifiedUsers = new HashSet<>();

            for (Integer executorId : executorIds) {
                if (!notifiedUsers.contains(executorId)) {
                    String notificationContent = String.format("您参与的任务\"%s\"距离截止时间不足一小时，请尽快处理。", task.getTaskTitle());
                    notificationService.createNotification(
                        executorId,
                        notificationContent,
                        "task",
                        task.getTaskId()
                    );
                    notifiedUsers.add(executorId);
                }
            }
            task.setIsDeadlineNotified(true);
            taskRepository.save(task);
        }
    }

    @Transactional
    public ApiResponse<String> deleteTask(Integer taskId, Integer userId) {
        Optional<Task> taskOpt = taskRepository.findById(taskId);
        if (taskOpt.isEmpty()) {
            return ApiResponse.error(404, "任务不存在");
        }
        try {
            Task task = taskOpt.get();
            if (task.getCreator() == null || task.getCreator().getUserId() == null || !task.getCreator().getUserId().equals(userId)) {
                return ApiResponse.error(403, "无权限删除此任务");
            }
            if (Byte.valueOf((byte)2).equals(task.getTaskStatus())) {
                return ApiResponse.error(403, "已完成的任务无法删除");
            }
            if (Byte.valueOf((byte)3).equals(task.getTaskStatus())) {
                return ApiResponse.error(208, "任务已关闭");
            }
            task.setTaskStatus((byte)3);
            taskRepository.save(task);

            // 获取所有执行者并发送通知
            List<Integer> executorIds = taskExecutorRelationRepository.findAllExecutorIdsByTaskId(taskId);
            Set<Integer> notifiedUsers = new HashSet<>();
            // 通知所有执行者
            for (Integer executorId : executorIds) {
                if (!notifiedUsers.contains(executorId)) { // 避免重复通知创建者
                    String notificationContent = String.format("您参与的任务\"%s\"已被关闭。", task.getTaskTitle());
                    notificationService.createNotification(
                        executorId,
                        notificationContent,
                        "task",
                        task.getTaskId()
                    );
                    notifiedUsers.add(executorId);
                }
            }

            return ApiResponse.success("任务删除成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "任务删除失败: " + e.getMessage());
        }
    }

    public ApiResponse<Map<String, Object>> listUserTasks(Integer userId, Byte taskStatus, String participantType) {

        List<Task> createdTasks = Collections.emptyList();
        List<Task> executingTasks = Collections.emptyList();

        if (participantType == null || "creator".equals(participantType)) {
            List<Task> tasks = taskRepository.findByCreator_UserIdAndTaskStatusNot(userId, (byte) 3);
            if (taskStatus != null) {
                tasks = tasks.stream()
                        .filter(task -> task.getTaskStatus().equals(taskStatus))
                        .collect(Collectors.toList());
            }
            createdTasks = tasks;
        }

        if (participantType == null || "executor".equals(participantType)) {
            List<Integer> executingTaskIds = taskExecutorRelationRepository.findActiveTaskIdsByExecutor(userId);
            Set<Integer> executingIdSet = new HashSet<>(executingTaskIds);
            List<Task> tasks = executingIdSet.isEmpty() ? Collections.emptyList()
                    : taskRepository.findAllById(executingIdSet).stream()
                    .collect(Collectors.toList());
            if (taskStatus != null) {
                tasks = tasks.stream()
                        .filter(task -> task.getTaskStatus().equals(taskStatus))
                        .collect(Collectors.toList());
            }
            
            // 当participantType为null时，需要过滤掉创建者和执行者相同的任务
            if (participantType == null) {
                tasks = tasks.stream()
                        .filter(task -> !task.getCreator().getUserId().equals(userId))
                        .collect(Collectors.toList());
            }
            
            executingTasks = tasks;
        }

        Map<String, Object> data = new HashMap<>();
        data.put("created", createdTasks.stream().map(this::toDtoWithExecutors).collect(Collectors.toList()));
        data.put("participated", executingTasks.stream().map(this::toDtoWithExecutors).collect(Collectors.toList()));

        return ApiResponse.success(data);
    }

    public ApiResponse<Map<String, Object>> getTaskById(Integer taskId, Integer userId) {
        Optional<Task> taskOpt = taskRepository.findById(taskId);
        if (taskOpt.isEmpty()) {
            return ApiResponse.error(404, "任务不存在");
        }
        Task task = taskOpt.get();

        // 检查用户是否有权限查看任务（创建者或执行者）
        if (!task.getCreator().getUserId().equals(userId) &&
            !taskExecutorRelationRepository.existsByTask_TaskIdAndExecutor_UserId(taskId, userId)) {
            return ApiResponse.error(403, "无权限查看此任务");
        }

        Map<String, Object> data = toDtoWithExecutors(task);
        return ApiResponse.success(data);
    }

    private Map<String, Object> toDto(Task t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("taskId", String.valueOf(t.getTaskId()));
        m.put("creatorName", t.getCreator() != null ? t.getCreator().getRealName() : null);
        m.put("taskTitle", t.getTaskTitle());
        m.put("taskContent", t.getTaskContent());
        m.put("taskPriority", String.valueOf(t.getPriority()));
        m.put("taskStatus", String.valueOf(t.getTaskStatus()));
        m.put("creationTime", t.getCreationTime() != null ? t.getCreationTime().toString() : null);
        m.put("deadline", t.getDeadline() != null ? t.getDeadline().toString() : null);
        if (Byte.valueOf((byte)2).equals(t.getTaskStatus())) {
            m.put("completionTime", t.getCompletionTime() != null ? t.getCompletionTime().toString() : null);
        }
        return m;
    }

    private Map<String, Object> toDtoWithExecutors(Task t) {
        Map<String, Object> m = toDto(t);
        List<String> executorNames = taskExecutorRelationRepository
                .findAllExecutorIdsByTaskId(t.getTaskId())
                .stream()
                .map(id -> {
                    return userRepository.findById(id).map(User::getRealName).orElse(null);
                })
                .filter(n -> n != null)
                .collect(Collectors.toList());
        m.put("executorNames", executorNames);
        m.put("taskProgress", logService.getMaxCompletedTaskProgress(t.getTaskId())); // Add task progress
        return m;
    }

    @Transactional
    public ApiResponse<Map<String, Object>> publishTask(
            Integer creatorId,
            TaskPublishRequest request) {

        try {
            // 验证优先级范围 (0-3)
            if (request.getPriority() < 0 || request.getPriority() > 3) {
                return ApiResponse.error(400, "优先级必须在0-3之间");
            }

            // 验证创建者是否存在
            Optional<User> creatorOpt = userRepository.findById(creatorId);
            if (creatorOpt.isEmpty()) {
                return ApiResponse.error(404, "创建者不存在");
            }

            List<Integer> executorIds = request.getExecutorIds();
            if (executorIds.size() > 1 && executorIds.contains(creatorId)) {
                return ApiResponse.error(400, "不能上下级同时执行任务");
            }

            boolean selfAssignOnly = executorIds.size() == 1 && executorIds.get(0).equals(creatorId);

            // 验证执行者是否都存在
            for (Integer executorId : request.getExecutorIds()) {
                Optional<User> executorOpt = userRepository.findById(executorId);
                if (executorOpt.isEmpty()) {
                    return ApiResponse.error(404, "执行者ID " + executorId + " 不存在");
                }
                if (!selfAssignOnly && !permissionService.canAssignTaskToUser(creatorId, executorOpt.get())) {
                    return ApiResponse.error(403, "无权限分配任务给 " + executorOpt.get().getRealName());
                }
            }

            // 创建任务
            Task task = new Task();
            task.setCreator(creatorOpt.get());
            task.setTaskTitle(request.getTitle());
            task.setTaskContent(request.getContent());
            task.setPriority(request.getPriority().byteValue());
            task.setTaskStatus((byte) 0); // 0-待开始
            task.setCreationTime(LocalDateTime.now());
            task.setDeadline(request.getDeadline());

            // 保存任务
            Task savedTask = taskRepository.save(task);

            // 创建执行者关联关系
            for (Integer executorId : request.getExecutorIds()) {
                User executor = userRepository.findById(executorId).get();
                TaskExecutorRelation relation = new TaskExecutorRelation();
                relation.setTask(savedTask);
                relation.setExecutor(executor);
                taskExecutorRelationRepository.save(relation);

                // 如果执行者不是创建者，则创建通知
                if (!executorId.equals(creatorId)) {
                    String notificationContent = String.format("您收到了新任务：\"%s\"", savedTask.getTaskTitle());
                    notificationService.createNotification(
                        executorId,
                        notificationContent,
                        "task",
                        savedTask.getTaskId()
                    );
                }
            }
            
            Map<String, Object> data = new HashMap<>();
            data.put("taskId", savedTask.getTaskId());
            return ApiResponse.success(data);

        } catch (Exception e) {
            return ApiResponse.error(500, "任务发布失败: " + e.getMessage());
        }
    }

    @Transactional
    public ApiResponse<Map<String, Object>> updateTask(
            Integer taskId,
            Integer userId,
            TaskUpdateRequest request) {

        try {
            // 验证优先级范围 (0-3)
            if (request.getPriority() < 0 || request.getPriority() > 3) {
                return ApiResponse.error(400, "优先级必须在0-3之间");
            }

            // 查找任务
            Optional<Task> taskOpt = taskRepository.findById(taskId);
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
            task.setTaskTitle(request.getTitle());
            task.setTaskContent(request.getContent());
            task.setPriority(request.getPriority().byteValue());
            task.setDeadline(request.getDeadline());

            // 保存更新后的任务
            taskRepository.save(task);

            // 获取所有执行者并发送通知
            List<Integer> executorIds = taskExecutorRelationRepository.findAllExecutorIdsByTaskId(taskId);
            for (Integer executorId : executorIds) {
                if (!executorId.equals(userId)) { // 不通知更新任务的本人
                    String notificationContent = String.format("您参与的任务\"%s\"已被更新。", task.getTaskTitle());
                    notificationService.createNotification(
                        executorId,
                        notificationContent,
                        "task",
                        task.getTaskId()
                    );
                }
            }

            Map<String, Object> data = new HashMap<>();
            data.put("taskId", task.getTaskId());
            return ApiResponse.success(data);

        } catch (Exception e) {
            return ApiResponse.error(500, "任务更新失败: " + e.getMessage());
        }
    }
}