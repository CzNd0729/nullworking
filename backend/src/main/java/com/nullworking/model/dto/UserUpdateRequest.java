package com.nullworking.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class UserUpdateRequest {

    @Schema(description = "角色ID", example = "1")
    private Integer roleId;

    @Schema(description = "部门ID", example = "2")
    private Integer deptId;

    @Schema(description = "用户名", example = "updateduser")
    private String userName;

    @Schema(description = "真实姓名", example = "李四")
    private String realName;

    @Schema(description = "电话号码", example = "13900000000")
    private String phoneNumber;

    @Schema(description = "邮箱", example = "updated@example.com")
    private String email;
}
