package com.nullworking.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.common.ApiResponse;
import com.nullworking.service.UserService;
import com.nullworking.util.JwtUtil;

import io.swagger.v3.oas.annotations.Operation;
import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/user")
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
    @GetMapping("/getSubDeptUser")
    public ApiResponse<Map<String, Object>> getSubDeptUser(HttpServletRequest request) {
        String authorizationHeader = request.getHeader("Authorization");
        String jwt = null;

        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            jwt = authorizationHeader.substring(7);
        }
        try {
            Integer currentUserId = jwtUtil.extractUserId(jwt);
            if (currentUserId == null) {
                return ApiResponse.error(401, "无效的token或用户ID");
            }
            return userService.getSubDeptUser(currentUserId);
        } catch (Exception e) {
            return ApiResponse.error(500, "服务器错误: " + e.getMessage());
        }
    }
}
