package com.nullworking.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

@Data
public class AIAnalysisRequest {

    @Schema(description = "用户ID列表，可选，",example ="[38]")
    private List<Integer> userIds;

    @Schema(description = "开始日期，格式：yyyy-MM-dd，可选",example = "2025-10-27")
    private String startDate;

    @Schema(description = "结束日期，格式：yyyy-MM-dd，可选",example = "2025-11-03")
    private String endDate;

    @Schema(description = "任务ID，可选",example = "86")
    private Integer taskId;

    @Schema(description = "AI分析的提示词", example = "分析这个人本周的工作情况")
    private String prompt;
}
