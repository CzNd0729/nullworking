package com.nullworking.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.LogFile;
import com.nullworking.service.LogFileService;
import com.nullworking.model.dto.FileDownloadInfo;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@RestController
@RequestMapping("/api/log-files")
public class LogFileController {

    @Autowired
    private LogFileService logFileService;

    @Operation(summary = "上传日志文件", description = "上传文件")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "文件上传成功",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = LogFile.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", description = "文件上传失败",
            content = @Content(mediaType = "application/json",
            schema = @Schema(implementation = ApiResponse.class)))
    @PostMapping(consumes = {"multipart/form-data"})
    public ResponseEntity<ApiResponse> uploadFile(
            @Parameter(description = "要上传的文件") @RequestParam("file") MultipartFile file) {
        try {
            LogFile logFile = logFileService.storeFile(file);
            return ResponseEntity.ok(ApiResponse.success(logFile.getFileId()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(ApiResponse.error(500,"文件上传失败: " + e.getMessage()));
        }
    }

    @Operation(summary = "通过文件ID查看文件", description = "通过文件ID返回对应的文件")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "成功返回文件",
            content = @Content(mediaType = "application/octet-stream"))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "文件未找到")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "500", description = "文件读取失败")
    @GetMapping("/{fileId}")
    public ResponseEntity<Resource> getFileById(@Parameter(description = "文件ID") @PathVariable Integer fileId) {
        try {
            FileDownloadInfo downloadInfo = logFileService.loadFileAsResource(fileId);
            Resource resource = downloadInfo.getResource();
            String originalFileName = downloadInfo.getOriginalFileName();
            String contentType = downloadInfo.getContentType();

            if (contentType == null || contentType.isEmpty()) {
                contentType = "application/octet-stream"; // Fallback to a default content type
            }

            // Encode the filename to handle non-ASCII characters
            String encodedFileName = URLEncoder.encode(originalFileName, StandardCharsets.UTF_8.toString()).replace("+", "%20");

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + encodedFileName + "\"")
                    .body(resource);
        } catch (IOException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.status(500).build();
        }
    }
}
