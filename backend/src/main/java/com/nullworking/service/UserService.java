package com.nullworking.service;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Department;
import com.nullworking.model.User;
import com.nullworking.repository.DepartmentRepository;
import com.nullworking.repository.UserRepository;
// import com.nullworking.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

    // @Autowired
    // private JwtUtil jwtUtil;

    // 所有的业务逻辑将在这里实现

    public ApiResponse<Map<String, Object>> getSubDeptUser(Integer currentUserId) {
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
