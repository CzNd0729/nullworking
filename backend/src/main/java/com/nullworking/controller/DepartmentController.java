package com.nullworking.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.DepartmentCreateRequest;
import com.nullworking.model.dto.DepartmentUpdateRequest;
import com.nullworking.service.DepartmentService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;

@RestController
@RequestMapping("/api/departments")
public class DepartmentController {

    @Autowired
    private DepartmentService departmentService;

    /**
     * 获取指定部门及其子部门的所有用户
     * @param deptId 部门ID
     * @return 包含用户列表的响应
     */
    @Operation(summary = "获取部门及其子部门用户", description = "获取指定部门及其所有子部门中的所有用户，返回用户ID和真实姓名")
    @GetMapping("/{departmentId}/sub-users")
    public ApiResponse<Map<String, Object>> getSubDeptUsers(
            @Parameter(description = "部门ID") @PathVariable Integer departmentId) {
        return departmentService.getSubDeptUsers(departmentId);
    }

    /**
     * 列出指定部门的子部门
     * @param parentDeptId 父部门ID（可选）
     * @return 包含子部门列表的响应
     */
    @Operation(summary = "列出子部门", description = "列出指定部门的所有子部门，如果不传参数则列出根部门")
    @GetMapping("/{departmentId}/sub-departments")
    public ApiResponse<Map<String, Object>> listSubDepts(
            @Parameter(description = "部门ID") @PathVariable Integer departmentId) {
        return departmentService.listSubDepts(departmentId);
    }

    /**
     * 创建部门
     * @param request 部门创建请求
     * @return 响应结果
     */
    @Operation(summary = "创建部门", description = "创建新部门，可以指定父部门，返回code：200成功，400参数错误，404父部门不存在，500失败")
    @PostMapping("")
    public ApiResponse<String> createDept(
            @Parameter(description = "部门创建信息") @RequestBody DepartmentCreateRequest request) {
        return departmentService.createDept(request);
    }

    /**
     * 更新部门
     * @param request 部门更新请求
     * @return 响应结果
     */
    @Operation(summary = "更新部门", description = "更新部门信息，包括名称、描述和父部门，返回code：200成功，400参数错误，404部门不存在，500失败")
    @PutMapping("/{departmentId}")
    public ApiResponse<String> updateDept(
            @Parameter(description = "部门ID") @PathVariable Integer departmentId,
            @Parameter(description = "部门更新信息") @RequestBody DepartmentUpdateRequest request) {
        return departmentService.updateDept(departmentId, request);
    }

    /**
     * 删除部门
     * @param deptId 部门ID
     * @return 响应结果
     */
    @Operation(summary = "删除部门", description = "删除指定部门，如果部门下有子部门或用户则无法删除，返回code：200成功，400无法删除，404部门不存在，500失败")
    @DeleteMapping("/{departmentId}")
    public ApiResponse<String> deleteDept(
            @Parameter(description = "部门ID") @PathVariable Integer departmentId) {
        return departmentService.deleteDept(departmentId);
    }
}
