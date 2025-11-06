package com.nullworking.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.UserCreateRequest;
import com.nullworking.model.dto.UserUpdateRequest;
import com.nullworking.service.UserService;
import com.nullworking.util.JwtUtil;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private JwtUtil jwtUtil;

    // @Autowired
    // private UserRepository userRepository;

    // @Autowired
    // private DepartmentRepository departmentRepository;

    @Autowired
    private UserService userService;

    @Operation(summary = "获取同级及下级部门用户", description = "从token解析用户ID，递归查询同级及下级部门中的其他用户，返回用户ID与用户真实姓名")
    @GetMapping("/subordinateUsers")
    public ApiResponse<Map<String, Object>> getSubDeptUser(HttpServletRequest request) {
        Integer currentUserId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        try {
            return userService.getSubDeptUser(currentUserId);
        } catch (Exception e) {
            return ApiResponse.error(500, "服务器错误: " + e.getMessage());
        }
    }

    @Operation(summary = "获取所有用户列表", description = "获取系统中所有用户的基本信息，包括用户ID、真实姓名、角色名称和部门名称")
    @GetMapping("")
    public ApiResponse<Map<String, Object>> listUsers(HttpServletRequest request) {
        // 检查是否为管理员
        Integer currentUserId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (currentUserId == null || currentUserId != 0) {
            return ApiResponse.error(403, "权限不足，只有管理员可以查看所有用户列表");
        }
        return userService.listUsers();
    }

    @Operation(summary = "添加新用户", description = "创建新用户，包括用户名、密码、角色、部门、真实姓名、电话号码和邮箱")
    @PostMapping("")
    public ApiResponse<Void> addUser(@RequestBody UserCreateRequest request, HttpServletRequest httpRequest) {
        // 检查是否为管理员
        Integer currentUserId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (currentUserId == null || currentUserId != 0) {
            return ApiResponse.error(403, "权限不足，只有管理员可以添加用户");
        }
        return userService.addUser(request);
    }

    @Operation(summary = "更新用户信息", description = "更新指定用户的基本信息，包括角色、部门、用户名、真实姓名、电话号码和邮箱")
    @PutMapping("/{userId}")
    public ApiResponse<Void> updateUser(
            @Parameter(description = "用户ID") @PathVariable("userId") Integer userId,
            @RequestBody UserUpdateRequest request,
            HttpServletRequest httpRequest) {
        // 检查是否为管理员
        Integer currentUserId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (currentUserId == null || currentUserId != 0) {
            return ApiResponse.error(403, "权限不足，只有管理员可以更新用户信息");
        }
        return userService.updateUser(userId, request);
    }

    @Operation(summary = "删除用户", description = "根据用户ID删除指定用户")
    @DeleteMapping("/{userId}")
    public ApiResponse<Void> deleteUser(
            @Parameter(description = "用户ID") @PathVariable("userId") Integer userId,
            HttpServletRequest request) {
        // 检查是否为管理员
        Integer currentUserId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (currentUserId == null || currentUserId != 0) {
            return ApiResponse.error(403, "权限不足，只有管理员可以删除用户");
        }
        return userService.deleteUser(userId);
    }
}