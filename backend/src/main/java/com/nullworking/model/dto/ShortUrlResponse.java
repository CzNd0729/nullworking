package com.nullworking.model.dto;

import lombok.Data;

/**
 * 短链接生成的响应参数DTO
 * 封装前端需展示的短链接、有效期等信息
 */
@Data
public class ShortUrlResponse {
    /**
     * 最终生成的OpenInstall格式短链接
     */
    private String shortUrl;

    /**
     * 短链接有效期（默认2小时）
     * 复用现有业务规则，无需额外配置
     */
    private Integer expireHours = 2;
}