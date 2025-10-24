package com.nullworking.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class LoginRequest {

    @Schema(description = "用户名", example = "testuser")
    private String userName;

    @Schema(description = "密码", example = "password123")
    private String password;
}
