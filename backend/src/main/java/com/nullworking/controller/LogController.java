package com.nullworking.controller;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.LogCreateRequest;
import com.nullworking.service.LogService;
import com.nullworking.util.JwtUtil;

import jakarta.servlet.http.HttpServletRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;

@RestController
@RequestMapping("/api/logs")
public class LogController {

    @Autowired
    private LogService logService;

    @Autowired
    private JwtUtil jwtUtil;

    @Operation(summary = "创建日志", description = "创建新的日志条目")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "日志创建成功",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "请求参数错误",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "任务或用户未找到",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", description = "日志创建失败",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @PostMapping("/")
    public ResponseEntity<ApiResponse> createLog(
            @Parameter(description = "日志创建请求体") @RequestBody LogCreateRequest request,
            HttpServletRequest httpRequest) {
        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ResponseEntity.status(401).body(new ApiResponse(401, "Unauthorized", null));
        }
        ApiResponse response = logService.createLog(request, userId);
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else if (response.getCode() == 404) {
            return ResponseEntity.status(404).body(response);
        } else {
            return ResponseEntity.status(500).body(response);
        }
    }

    @Operation(summary = "日志列表", description = "通过 startTime-endTime 过滤日志，格式如：2024-10-1~2025-10-1；若开始与结束相同表示单日")
    @GetMapping
    public ApiResponse<Map<String, Object>> ListLogs(@RequestParam("startTime-endTime") String timeRange, HttpServletRequest httpRequest) {
        String[] parts = timeRange.split("~");
        if (parts.length != 2) {
            return ApiResponse.error(400, "时间范围格式错误，应为 start~end，如：2024-10-1~2025-10-1");
        }
        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-M-d");
        LocalDate start = LocalDate.parse(parts[0].trim(), dateFormatter);
        LocalDate end = LocalDate.parse(parts[1].trim(), dateFormatter);
        if (start.isAfter(end)) {
            return ApiResponse.error(400, "开始日期不能晚于结束日期");
        }
        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权: 无效的token或用户ID");
        }
        return logService.listLogs(userId, start, end);
    }
}
