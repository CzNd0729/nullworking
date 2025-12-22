package com.nullworking.model.dto;

import lombok.Data;

/**
 * 短链接生成的响应参数DTO
 * 封装前端需展示的短链接、有效期等信息
 */
@Data
public class ShortUrlResponse {
    private String shortUrl;
    // 修正为7天有效期（7*24=168小时）
    private Integer expireHours = 168; 
}