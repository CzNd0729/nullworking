// filePath: nullworking/model/dto/UserUpdateRequest.java
package com.nullworking.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import lombok.Data;

@Data
public class UserUpdateRequest {

    // 移除 userName 字段，禁止前端传递用户名
    
    @Schema(description = "角色ID", example = "1")
    private Integer roleId;

    @Schema(description = "部门ID", example = "2")
    private Integer deptId;

    @Schema(description = "真实姓名", example = "张三")
    private String realName;

    @Schema(description = "电话号码", example = "13800000000")
    private String phone;

    @Email(message = "邮箱格式不正确")
    @Schema(description = "邮箱", example = "user@example.com")
    private String email;
}