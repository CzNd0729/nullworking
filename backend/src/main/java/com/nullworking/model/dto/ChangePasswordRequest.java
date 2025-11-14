package com.nullworking.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class ChangePasswordRequest {

    @Schema(description = "原密码", example = "123456")
    private String oldPassword;

    @Schema(description = "新密码", example = "111111")
    private String newPassword;
}