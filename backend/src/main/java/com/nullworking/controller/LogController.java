package com.nullworking.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.LogCreateRequest;
import com.nullworking.model.dto.LogUpdateRequest;
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
    public ResponseEntity<ApiResponse<Void>> createLog(
            @Parameter(description = "日志创建请求体") @RequestBody LogCreateRequest request,
            HttpServletRequest httpRequest) {
        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ResponseEntity.status(401).body(new ApiResponse<>(401, "Unauthorized", null));
        }
        ApiResponse<Void> response = logService.createLog(request, userId);
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else if (response.getCode() == 404) {
            return ResponseEntity.status(404).body(response);
        } else {
            return ResponseEntity.status(500).body(response);
        }
    }

    @Operation(summary = "更新日志", description = "更新指定的日志条目")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "日志更新成功",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "请求参数错误",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "未授权访问",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "日志未找到",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", description = "日志更新失败",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @PutMapping("/{logId}")
    public ResponseEntity<ApiResponse<Void>> updateLog(
            @Parameter(description = "日志ID") @PathVariable Integer logId,
            @Parameter(description = "日志更新请求体") @RequestBody LogUpdateRequest request,
            HttpServletRequest httpRequest) {
        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ResponseEntity.status(401).body(new ApiResponse<>(401, "Unauthorized", null));
        }
        ApiResponse<Void> response = logService.updateLog(logId, request, userId);
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else if (response.getCode() == 404) {
            return ResponseEntity.status(404).body(response);
        } else {
            return ResponseEntity.status(500).body(response);
        }
    }

    @Operation(summary = "删除日志", description = "删除指定的日志条目")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "日志删除成功",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "未授权访问",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "日志未找到",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", description = "日志删除失败",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @DeleteMapping("/{logId}")
    public ResponseEntity<ApiResponse<Void>> deleteLog(
            @Parameter(description = "日志ID") @PathVariable Integer logId,
            HttpServletRequest httpRequest) {
        Integer userId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (userId == null) {
            return ResponseEntity.status(401).body(new ApiResponse<>(401, "Unauthorized", null));
        }
        ApiResponse<Void> response = logService.deleteLog(logId, userId);
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else if (response.getCode() == 404) {
            return ResponseEntity.status(404).body(response);
        } else {
            return ResponseEntity.status(500).body(response);
        }
    }
}
