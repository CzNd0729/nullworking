package com.nullworking.controller;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Department;
import com.nullworking.model.User;
import com.nullworking.repository.DepartmentRepository;
import com.nullworking.repository.UserRepository;
import com.nullworking.util.JwtUtil;

import io.swagger.v3.oas.annotations.Operation;
import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/user")
public class UserController {

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

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

            // 1. 获取当前用户所属部门ID
            User currentUser = userRepository.findById(currentUserId).orElse(null);
            if (currentUser == null || currentUser.getDepartment() == null) {
                Map<String, Object> data = new HashMap<>();
                data.put("users", new ArrayList<>());
                return ApiResponse.success(data);
            }
            Integer currentDepartmentId = currentUser.getDepartment().getDepartmentId();

            // 2. 获取所有同级及下级部门ID
            Set<Integer> departmentIdsInHierarchy = new HashSet<>();
            collectDepartmentHierarchy(currentDepartmentId, departmentIdsInHierarchy);

            // 3. 查询这些部门下的所有用户（排除当前用户自己）
            List<User> usersInHierarchy = userRepository.findByDepartmentDepartmentIdIn(departmentIdsInHierarchy)
                    .stream()
                    .filter(user -> !user.getUserId().equals(currentUserId)) // 排除当前用户自己
                    .collect(Collectors.toList());

            // 4. 格式化结果
            List<Map<String, Object>> users = new ArrayList<>();
            for (User user : usersInHierarchy) {
                Map<String, Object> userMap = new HashMap<>();
                userMap.put("userId", user.getUserId());
                userMap.put("realName", user.getRealName());
                users.add(userMap);
            }
            Map<String, Object> data = new HashMap<>();
            data.put("users",users);

            return ApiResponse.success(data);

        } catch (Exception e) {
            return ApiResponse.error(500, "服务器错误: " + e.getMessage());
        }
    }

    /**
     * 递归收集所有当前部门及下级部门的ID
     * @param departmentId 当前部门ID
     * @param collectedDepartmentIds 已收集的部门ID集合
     */
    private void collectDepartmentHierarchy(Integer departmentId, Set<Integer> collectedDepartmentIds) {
        if (departmentId == null || collectedDepartmentIds.contains(departmentId)) {
            return;
        }

        collectedDepartmentIds.add(departmentId);
        // 获取所有子部门
        List<Department> subDepartments = departmentRepository.findByParentDepartment_departmentId(departmentId);
        for (Department subDepartment : subDepartments) {
            collectDepartmentHierarchy(subDepartment.getDepartmentId(), collectedDepartmentIds);
        }
    }
}
