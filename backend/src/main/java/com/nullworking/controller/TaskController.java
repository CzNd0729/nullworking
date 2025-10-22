package com.nullworking.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import jakarta.servlet.http.HttpServletRequest;

import com.nullworking.common.ApiResponse;
import com.nullworking.service.LogService;
import com.nullworking.service.TaskService;
import com.nullworking.util.JwtUtil;
import com.nullworking.model.dto.TaskPublishRequest;
import com.nullworking.model.dto.TaskUpdateRequest;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;

@RestController
@RequestMapping("/api/tasks")
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

    @Autowired
    private LogService logService;

    @Operation(summary = "删除任务(关闭)", description = "根据任务ID将任务状态置为3=已关闭，仅创建者可操作，返回code：200成功，401未授权，403无权限，404不存在，500失败")
    @DeleteMapping("/{taskId}")
    @Transactional
    public ApiResponse<String> deleteTask(
            @Parameter(description = "任务ID") @PathVariable("taskId") Integer taskId, HttpServletRequest request) {
        Integer userId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }
        return taskService.deleteTask(taskId, userId);
    }

    @Operation(summary = "查询任务列表", description = "返回当前用户创建与参与的任务列表（默认包含已删除任务），完成任务包含finishTime")
    @GetMapping("")
    public ApiResponse<Map<String, Object>> listUserTasks(
            HttpServletRequest request,
            @Parameter(description = "任务状态 (0:进行中, 1:已延期, 2:已完成, 3:已关闭)") @RequestParam(value = "taskStatus", required = false) Byte taskStatus,
            @Parameter(description = "参与者类型 (creator:创建者, executor:执行者)") @RequestParam(value = "participantType", required = false) String participantType) {
        Integer userId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }

        return taskService.listUserTasks(userId, taskStatus, participantType);
    }

    @Operation(summary = "任务详情", description = "获取指定任务的所有日志，按进度排序，包含已完成和待完成的日志")
    @GetMapping("/{taskId}")
    public ApiResponse<Map<String, Object>> taskDetails(@PathVariable("taskId") Integer taskId, HttpServletRequest httpRequest) {
        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权: 无效的token或用户ID");
        }
        return logService.taskDetails(taskId, userId);
    }

    @Operation(summary = "发布任务", description = "创建新任务并分配多个执行者，优先级0-3，创建者从Token获取，返回code：200成功，400参数错误，404创建者不存在，500失败")
    @PostMapping("")
    public ApiResponse<Map<String, Object>> publishTask(
            HttpServletRequest request,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "任务发布信息",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = TaskPublishRequest.class))) @RequestBody TaskPublishRequest taskPublishRequest) {

        Integer creatorId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (creatorId == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }
        return taskService.publishTask(creatorId, taskPublishRequest);
    }

    @Operation(summary = "更新任务", description = "仅创建者可更新任务信息，优先级0-3，返回code：200成功，400参数错误，401未授权，403无权限，404任务不存在，500失败")
    @PutMapping("/{taskId}")
    public ApiResponse<Map<String, Object>> updateTask(
            HttpServletRequest request,
            @Parameter(description = "任务ID") @PathVariable("taskId") Integer taskId,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "任务更新信息",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = TaskUpdateRequest.class))) @RequestBody TaskUpdateRequest taskUpdateRequest) {

        Integer userId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }
        return taskService.updateTask(taskId, userId, taskUpdateRequest);
    }
}
