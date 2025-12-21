package com.nullworking.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UserCreateRequest {

    @Schema(description = "用户名", example = "newuser")
    private String userName;

    @Schema(description = "密码", example = "newpassword123")
    private String password;

    @Schema(description = "角色ID", example = "1")
    private Integer roleId;

    @Schema(description = "部门ID", example = "2")
    private Integer deptId;

    @Schema(description = "真实姓名", example = "张三")
    private String realName;

    @Schema(description = "电话号码", example = "13800000000")
    private String phone;

    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    @Schema(description = "邮箱", example = "newuser@example.com")
    private String email;
}
