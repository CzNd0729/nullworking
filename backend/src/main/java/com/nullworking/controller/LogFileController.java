package com.nullworking.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.LogFile;
import com.nullworking.service.LogFileService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;

@RestController
@RequestMapping("/api/log-files")
public class LogFileController {

    @Autowired
    private LogFileService logFileService;

    @Operation(summary = "上传日志文件", description = "上传文件并关联到指定日志ID")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "文件上传成功",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = LogFile.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", description = "文件上传失败",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @PostMapping(value = "/upload", consumes = {"multipart/form-data"})
    public ResponseEntity<ApiResponse> uploadFile(
            @Parameter(description = "要上传的文件") @RequestParam("file") MultipartFile file,
            @Parameter(description = "关联的日志ID") @RequestParam("logId") Integer logId) {
        try {
            LogFile logFile = logFileService.storeFile(file, logId);
            return ResponseEntity.ok(ApiResponse.success(logFile));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(ApiResponse.error(500,"文件上传失败: " + e.getMessage()));
        }
    }
}
