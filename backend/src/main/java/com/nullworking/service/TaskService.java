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

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Task;
import com.nullworking.model.TaskExecutorRelation;
import com.nullworking.model.User;
import com.nullworking.model.dto.TaskPublishRequest;
import com.nullworking.model.dto.TaskUpdateRequest;
import com.nullworking.repository.TaskExecutorRelationRepository;
import com.nullworking.repository.TaskRepository;
import com.nullworking.repository.UserRepository;

@Service
public class TaskService {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private TaskExecutorRelationRepository taskExecutorRelationRepository;

    @Autowired
    private UserRepository userRepository;

    // @Autowired
    // private JwtUtil jwtUtil;

    @Autowired
    private LogService logService;

    // 所有的业务逻辑将在这里实现

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
            if (Byte.valueOf((byte)3).equals(task.getTaskStatus())) {
                return ApiResponse.error(208, "任务已关闭");
            }
            task.setTaskStatus((byte)3);
            taskRepository.save(task);
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

            // 验证执行者是否都存在
            for (Integer executorId : request.getExecutorIds()) {
                Optional<User> executorOpt = userRepository.findById(executorId);
                if (executorOpt.isEmpty()) {
                    return ApiResponse.error(404, "执行者ID " + executorId + " 不存在");
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
            Map<String, Object> data = new HashMap<>();
            data.put("taskId", task.getTaskId());
            return ApiResponse.success(data);

        } catch (Exception e) {
            return ApiResponse.error(500, "任务更新失败: " + e.getMessage());
        }
    }
}
