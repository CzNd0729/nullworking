package com.nullworking.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Log;
import com.nullworking.model.Task;
import com.nullworking.model.User;
import com.nullworking.model.dto.LogCreateRequest;
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

    @Transactional
    public ApiResponse<Void> createLog(LogCreateRequest request, Integer userId) {
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
}
