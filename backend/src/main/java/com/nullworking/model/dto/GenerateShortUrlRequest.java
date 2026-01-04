package com.nullworking.model.dto;

import lombok.Data;
import javax.validation.constraints.NotNull;

/**
 * 生成短链接的请求参数DTO
 * 仅封装必要参数，复用现有校验注解
 */
@Data
public class GenerateShortUrlRequest {
    /**
     * AI分析结果ID
     */
    @NotNull(message = "分析结果ID不能为空")
    private Integer resultId;
}