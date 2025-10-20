package com.nullworking.model.dto;

import lombok.Data;

import java.time.LocalDateTime;

import io.swagger.v3.oas.annotations.media.Schema;

@Data
@Schema(description = "日志创建请求体")
public class LogCreateRequest {
    @Schema(description = "任务ID", example = "3")
    private Integer taskId;
    @Schema(description = "日志标题", example = "前端设计")
    private String logTitle;
    @Schema(description = "日志内容", example = "完成前端日志页面设计")
    private String logContent;
    @Schema(description = "日志状态 (0: 未完成, 1: 已完成)", example = "0")
    private Integer logStatus; // 0 for pending, 1 for completed
    @Schema(description = "任务进度百分比 (0-100)", example = "80")
    private Integer taskProgress; // Percentage of task progress
    @Schema(description = "开始时间 (HH:mm 格式)", example = "15:00")
    private String startTime; // Format: HH:mm
    @Schema(description = "结束时间 (HH:mm 格式)", example = "18:00")
    private String endTime;   // Format: HH:mm
    @Schema(description = "日志日期 (YYYY-MM-DD 格式)", example = "2025-10-20")
    private String logDate; // Format: YYYY-MM-DD
}
