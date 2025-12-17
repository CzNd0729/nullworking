package com.nullworking.model.dto;

import java.time.LocalDateTime;
import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class AITaskUpdateRequest {

    @Schema(description = "用于AI修改或创建任务的指令文本", example = "帮我创建一个关于完成项目文档的任务，截止日期在明天下午5点，优先级高。")
    private String text;

    @Schema(description = "任务标题", example = "完成项目文档")
    private String taskTitle;

    @Schema(description = "任务内容", example = "编写用户手册和API文档")
    private String taskContent;

    @Schema(description = "任务优先级 (0-3)", example = "1")
    private Integer priority;

    @Schema(description = "执行者用户ID列表", example = "[1, 2, 3]")
    private List<Integer> executorIds;

    @Schema(description = "任务截止日期", example = "2025-12-31T23:59:59")
    private LocalDateTime deadline;
}

