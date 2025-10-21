package com.nullworking.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Log;
import com.nullworking.model.Task;
import com.nullworking.model.User;
import com.nullworking.model.dto.LogCreateRequest;
import com.nullworking.model.dto.LogUpdateRequest;
import com.nullworking.repository.LogRepository;
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
}
