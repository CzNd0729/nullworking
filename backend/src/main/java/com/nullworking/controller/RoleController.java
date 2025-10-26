package com.nullworking.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.RoleCreateRequest;
import com.nullworking.model.dto.RoleUpdateRequest;
import com.nullworking.service.RoleService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;

@RestController
@RequestMapping("/api/roles")
public class RoleController {

    @Autowired
    private RoleService roleService;

    /**
     * 列出所有角色
     * @return 包含角色列表的响应
     */
    @Operation(summary = "列出所有角色", description = "获取系统中所有角色的列表，包括角色ID、名称和描述")
    @GetMapping("")
    public ApiResponse<Map<String, Object>> listRoles() {
        return roleService.listRoles();
    }

    /**
     * 创建角色
     * @param request 角色创建请求
     * @return 响应结果
     */
    @Operation(summary = "创建角色", description = "创建新角色并分配权限，返回code：200成功，400参数错误，404权限不存在，500失败")
    @PostMapping("")
    public ApiResponse<String> createRole(
            @Parameter(description = "角色创建信息") @RequestBody RoleCreateRequest request) {
        return roleService.createRole(request);
    }

    /**
     * 更新角色
     * @param request 角色更新请求
     * @return 响应结果
     */
    @Operation(summary = "更新角色", description = "更新角色信息包括权限分配，返回code：200成功，400参数错误，404角色不存在或权限不存在，500失败")
    @PutMapping("/{roleId}")
    public ApiResponse<String> updateRole(
            @Parameter(description = "角色ID") @PathVariable Integer roleId,
            @Parameter(description = "角色更新信息") @RequestBody RoleUpdateRequest request) {
        return roleService.updateRole(request);
    }

    /**
     * 删除角色
     * @param roleId 角色ID
     * @return 响应结果
     */
    @Operation(summary = "删除角色", description = "删除指定角色，如果角色下有关联用户则无法删除，返回code：200成功，400无法删除，404角色不存在，500失败")
    @DeleteMapping("/{roleId}")
    public ApiResponse<String> deleteRole(
            @Parameter(description = "角色ID") @PathVariable Integer roleId) {
        return roleService.deleteRole(roleId);
    }
}
