package com.nullworking.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class RegisterRequest {

    @Schema(description = "用户名", example = "newuser")
    private String userName;

    @Schema(description = "密码", example = "newpassword123")
    private String password;

    @Schema(description = "真实姓名", example = "张三")
    private String realName;

    @Schema(description = "电话号码", example = "13800000000")
    private String phone;

    @Schema(description = "邮箱", example = "newuser@example.com")
    private String email;
}
