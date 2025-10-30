package com.nullworking.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Log;
import com.nullworking.model.LogFile;
import com.nullworking.model.Task;
import com.nullworking.model.User;
import com.nullworking.model.dto.LogCreateRequest;
import com.nullworking.model.dto.LogUpdateRequest;
import com.nullworking.repository.LogRepository;
import com.nullworking.repository.TaskExecutorRelationRepository;
import com.nullworking.repository.TaskRepository;
import com.nullworking.repository.UserRepository;

import jakarta.transaction.Transactional;

@Service
public class LogService {

    @Autowired
    private LogRepository logRepository;

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private LogFileService logFileService;

    @Autowired
    private TaskExecutorRelationRepository taskExecutorRelationRepository;

    public ApiResponse<Map<String, Object>> listLogs(Integer userId, LocalDate startDate, LocalDate endDate) {
        List<Log> logs = logRepository.findByUserUserIdAndLogDateBetween(userId, startDate, endDate);

        List<Map<String, Object>> items = new ArrayList<>();
        for (Log l : logs) {
            Map<String, Object> item = new HashMap<>();
            item.put("logId", l.getLogId());
            item.put("taskId", l.getTask() != null ? l.getTask().getTaskId() : null);
            item.put("taskTitle",l.getTask().getTaskTitle());
            item.put("logTitle", l.getLogTitle());
            item.put("logContent", l.getLogContent());
            item.put("logDate", l.getLogDate());
            item.put("logStatus", l.getLogStatus());
            item.put("startTime", l.getStartTime().format(DateTimeFormatter.ofPattern("HH:mm")));
            item.put("endTime", l.getEndTime().format(DateTimeFormatter.ofPattern("HH:mm")));
            items.add(item);
        }

        Map<String, Object> data = new HashMap<>();
        data.put("total", items.size());
        data.put("logs", items);

        return ApiResponse.success(data);
    }

    @Transactional
    public ApiResponse<Void> createLog(LogCreateRequest request, Integer userId) {
        List<Integer> fileIds=request.getFileIds();
        Optional<User> userOptional = userRepository.findById(userId);
        if (userOptional.isEmpty()) {
            return ApiResponse.error(404, "用户未找到");
        }
        User user = userOptional.get();

        Optional<Task> taskOptional = taskRepository.findById(request.getTaskId());
        if (taskOptional.isEmpty()) {
            return ApiResponse.error(404, "任务未找到");
        }
        Task task = taskOptional.get();

        Log log = new Log();
        log.setUser(user);
        log.setTask(task);
        log.setLogContent(request.getLogContent());
        log.setLogTitle(request.getLogTitle());
        log.setLogStatus(request.getLogStatus());
        log.setTaskProgress(request.getTaskProgress());

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm");
        log.setStartTime(LocalTime.parse(request.getStartTime(), formatter));
        log.setEndTime(LocalTime.parse(request.getEndTime(), formatter));
        
        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        log.setLogDate(LocalDate.parse(request.getLogDate(), dateFormatter));
        log.setCreationTime(LocalDateTime.now());
        log.setUpdateTime(LocalDateTime.now());

        logRepository.save(log);

        if (fileIds != null && !fileIds.isEmpty()) {
            logFileService.updateLogIdForFiles(fileIds, log.getLogId());
        }

        // If task progress is 100% and log status is 1 (completed)
        if (request.getTaskProgress() == 100 && request.getLogStatus() == 1) {
            task.setCompletionTime(LocalDateTime.now());    
            task.setTaskStatus((byte)2);
            taskRepository.save(task);

            // Clear all pending logs associated with this task
            logRepository.deleteByTaskTaskIdAndLogStatus(request.getTaskId(), 0); // 0 for pending
        }

        return ApiResponse.success();
    }

    @Transactional
    public ApiResponse<Void> updateLog(Integer logId, LogUpdateRequest request, Integer userId) {
        // 查找日志并验证所有权
        Optional<Log> logOptional = logRepository.findByLogIdAndUserUserId(logId, userId);
        if (logOptional.isEmpty()) {
            return ApiResponse.error(404, "日志未找到或无权限访问");
        }
        
        Log log = logOptional.get();
        
        // 更新日志字段
        if (request.getLogTitle() != null) {
            log.setLogTitle(request.getLogTitle());
        }
        if (request.getLogContent() != null) {
            log.setLogContent(request.getLogContent());
        }
        if (request.getLogStatus() != null) {
            log.setLogStatus(request.getLogStatus());
        }
        if (request.getTaskProgress() != null) {
            log.setTaskProgress(request.getTaskProgress());
        }
        if (request.getStartTime() != null) {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm");
            log.setStartTime(LocalTime.parse(request.getStartTime(), formatter));
        }
        if (request.getEndTime() != null) {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm");
            log.setEndTime(LocalTime.parse(request.getEndTime(), formatter));
        }
        if (request.getLogDate() != null) {
            DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
            log.setLogDate(LocalDate.parse(request.getLogDate(), dateFormatter));
        }
        
        // 更新修改时间
        log.setUpdateTime(LocalDateTime.now());
        
        // 保存日志
        logRepository.save(log);
        
        // 处理文件关联
        if (request.getFileIds() != null) {
            logFileService.updateLogIdForFiles(request.getFileIds(), log.getLogId());
        } 
        
        // 如果任务进度为100%且日志状态为已完成，更新任务状态
        if (request.getTaskProgress() != null && request.getLogStatus() != null &&
            request.getTaskProgress() == 100 && request.getLogStatus() == 1) {
            Task task = log.getTask();
            task.setCompletionTime(LocalDateTime.now());
            task.setTaskStatus((byte)2);
            taskRepository.save(task);
            
            // 清除该任务的所有待处理日志
            logRepository.deleteByTaskTaskIdAndLogStatus(task.getTaskId(), 0);
        }
        
        return ApiResponse.success();
    }

    @Transactional
    public ApiResponse<Void> deleteLog(Integer logId, Integer userId) {
        // 查找日志并验证所有权
        Optional<Log> logOptional = logRepository.findByLogIdAndUserUserId(logId, userId);
        if (logOptional.isEmpty()) {
            return ApiResponse.error(404, "日志未找到或无权限访问");
        }
        
        Log log = logOptional.get();
        
        // 删除日志
        logRepository.delete(log);
        
        return ApiResponse.success();
    }
        public ApiResponse<Map<String, Object>> taskDetails(Integer taskId, Integer userId) {
        // 检查任务是否存在
        Optional<Task> taskOptional = taskRepository.findById(taskId);
        if (taskOptional.isEmpty()) {
            return ApiResponse.error(404, "任务未找到");
        }
        Task task = taskOptional.get();

        // 检查用户是否有权限查看该任务（创建者或执行者）
        boolean isCreator = task.getCreator().getUserId().equals(userId);
        boolean isExecutor = taskExecutorRelationRepository.existsByTask_TaskIdAndExecutor_UserId(taskId, userId);
        
        if (!isCreator && !isExecutor) {
            return ApiResponse.error(403, "无权限查看该任务的日志");
        }

        List<Log> logs = logRepository.findByTaskTaskIdOrderByTaskProgressAsc(taskId);

        // 返回所有与任务关联的日志，不再过滤只返回当前用户的日志
        List<Log> allLogs = new ArrayList<>();
        for (Log log : logs) {
            allLogs.add(log);
        }

        // 找到已完成日志的最新进度
        int maxCompletedProgress = 0;
        for (Log log : allLogs) {
            if (log.getLogStatus() == 1) { // 已完成
                maxCompletedProgress = Math.max(maxCompletedProgress, log.getTaskProgress());
            }
        }

        List<Map<String, Object>> items = new ArrayList<>();
        for (Log l : allLogs) {
            // 如果是待完成日志且进度落后于已完成日志的最新进度，则跳过
            if (l.getLogStatus() == 0 && l.getTaskProgress() <= maxCompletedProgress) {
                continue;
            }

            Map<String, Object> item = new HashMap<>();
            item.put("logId", l.getLogId());
            item.put("logTitle", l.getLogTitle());
            item.put("logContent", l.getLogContent());
            item.put("taskProgress", l.getTaskProgress() + "%");
            item.put("logStatus", l.getLogStatus().toString());
            item.put("userId", l.getUser().getUserId()); // 添加用户ID信息
            item.put("userName", l.getUser().getRealName()); // 添加用户姓名信息
            
            // 格式化时间：yyyy-MM-dd-HH:mm
            String endTime = l.getLogDate().toString() + " " + l.getEndTime().toString().substring(0, 5);
            item.put("endTime", endTime);
            
            items.add(item);
        }

        Map<String, Object> data = new HashMap<>();
        data.put("logs", items);

        return ApiResponse.success(data);
    }

    public Integer getMaxCompletedTaskProgress(Integer taskId) {
        Optional<Log> latestCompletedLog = logRepository.findTopByTaskTaskIdAndLogStatusOrderByTaskProgressDesc(taskId, 1); // 1 for completed
        return latestCompletedLog.map(Log::getTaskProgress).orElse(0);
    }

    public ApiResponse<Map<String, Object>> logDetails(Integer logId, Integer userId) {
        // 先按ID查找日志
        Optional<Log> logOptional = logRepository.findById(logId);
        if (logOptional.isEmpty()) {
            return ApiResponse.error(404, "日志未找到");
        }

        Log log = logOptional.get();

        // 鉴权：允许日志创建者、任务创建者、或任务执行者查看
        Task task = log.getTask();
        Integer taskId = task.getTaskId();
        boolean isLogCreator = log.getUser() != null && log.getUser().getUserId().equals(userId);
        boolean isTaskCreator = task.getCreator() != null && task.getCreator().getUserId().equals(userId);
        boolean isTaskExecutor = taskExecutorRelationRepository.existsByTask_TaskIdAndExecutor_UserId(taskId, userId);
        if (!isLogCreator && !isTaskCreator && !isTaskExecutor) {
            return ApiResponse.error(403, "无权限查看该日志");
        }

        // 获取关联的文件ID列表
        List<LogFile> logFiles = logFileService.getLogFilesByLogId(logId);
        List<Integer> fileIds = logFiles.stream()
                .map(LogFile::getFileId)
                .collect(Collectors.toList());

        // 构建返回数据
        Map<String, Object> data = new HashMap<>();
        data.put("taskId", taskId);
        data.put("logId", log.getLogId());
        data.put("logTitle", log.getLogTitle());
        data.put("logContent", log.getLogContent());
        data.put("logStatus", log.getLogStatus());
        data.put("taskTitle", task.getTaskTitle());
        data.put("taskProgress", log.getTaskProgress());
        data.put("startTime", log.getStartTime().toString());
        data.put("endTime", log.getEndTime().toString());
        data.put("logDate", log.getLogDate().toString());
        data.put("fileIds", fileIds);

        return ApiResponse.success(data);
    }
}
