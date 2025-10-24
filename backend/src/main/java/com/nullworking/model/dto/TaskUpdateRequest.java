package com.nullworking.model.dto;

import java.time.LocalDateTime;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class TaskUpdateRequest {

    @Schema(description = "任务标题", example = "更新后的项目文档")
    private String title;

    @Schema(description = "任务内容", example = "更新用户手册和API文档的某些部分")
    private String content;

    @Schema(description = "任务优先级 (0-3)", example = "2")
    private Integer priority;

    @Schema(description = "任务截止日期", example = "2024-01-31T23:59:59")
    private LocalDateTime deadline;
}
