package com.nullworking.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class ItemUpdateRequest {

    @Schema(description = "事项标题", example = "新品发布会准备")
    private String title;

    @Schema(description = "事项内容", example = "产品经理于10-31前拟写并提交新品介绍")
    private String content;

    @Schema(description = "显示顺序 (1-10)", example = "1")
    private Integer displayOrder;
}