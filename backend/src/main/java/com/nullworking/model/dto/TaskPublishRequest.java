package com.nullworking.model.dto;

import java.time.LocalDateTime;
import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class TaskPublishRequest {

    @Schema(description = "任务标题", example = "完成项目文档")
    private String title;

    @Schema(description = "任务内容", example = "编写用户手册和API文档")
    private String content;

    @Schema(description = "任务优先级 (0-3)", example = "1")
    private Integer priority;

    @Schema(description = "执行者用户ID列表", example = "[1, 2, 3]")
    private List<Integer> executorIDs;

    @Schema(description = "任务截止日期", example = "2023-12-31T23:59:59")
    private LocalDateTime deadline;
}
