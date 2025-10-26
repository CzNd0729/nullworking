package com.nullworking.service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Department;
import com.nullworking.model.User;
import com.nullworking.model.dto.DepartmentCreateRequest;
import com.nullworking.model.dto.DepartmentUpdateRequest;
import com.nullworking.repository.DepartmentRepository;
import com.nullworking.repository.UserRepository;

@Service
public class DepartmentService {

    @Autowired
    private DepartmentRepository departmentRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * 获取指定部门及其子部门的所有用户
     * @param deptId 部门ID
     * @return 包含用户列表的响应
     */
    public ApiResponse<Map<String, Object>> getSubDeptUsers(Integer deptId) {
        try {
            Department department = departmentRepository.findById(deptId).orElse(null);
            if (department == null) {
                return ApiResponse.error(404, "部门不存在");
            }

            // 获取该部门及其所有子部门的ID
            Set<Integer> departmentIds = new HashSet<>();
            collectDepartmentIds(department, departmentIds);

            // 查找这些部门的所有用户
            List<User> users = userRepository.findByDepartmentDepartmentIdIn(departmentIds);

            // 构建响应数据
            Map<String, Object> result = new HashMap<>();
            List<Map<String, Object>> userList = users.stream()
                    .map(user -> {
                        Map<String, Object> userInfo = new HashMap<>();
                        userInfo.put("userId", user.getUserId());
                        userInfo.put("realName", user.getRealName());
                        return userInfo;
                    })
                    .collect(Collectors.toList());
            
            result.put("users", userList);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(500, "获取部门用户失败: " + e.getMessage());
        }
    }

    /**
     * 递归收集部门及其所有子部门的ID
     */
    private void collectDepartmentIds(Department department, Set<Integer> departmentIds) {
        if (department == null) return;
        
        departmentIds.add(department.getDepartmentId());
        
        if (department.getSubDepartments() != null) {
            for (Department subDept : department.getSubDepartments()) {
                collectDepartmentIds(subDept, departmentIds);
            }
        }
    }

    /**
     * 列出指定部门的子部门
     * @param departmentId 部门ID
     * @return 包含子部门列表的响应
     */
    public ApiResponse<Map<String, Object>> listSubDepts(Integer departmentId) {
        try {
            List<Department> departments;
            
            Department parentDepartment = departmentRepository.findById(departmentId).orElse(null);
            if (parentDepartment == null) {
                return ApiResponse.error(404, "部门不存在");
            }
            departments = departmentRepository.findByParentDepartment_departmentId(departmentId);

            // 构建响应数据
            Map<String, Object> result = new HashMap<>();
            List<Map<String, Object>> deptList = departments.stream()
                    .map(dept -> {
                        Map<String, Object> deptInfo = new HashMap<>();
                        deptInfo.put("deptId", dept.getDepartmentId());
                        deptInfo.put("deptName", dept.getDepartmentName());
                        deptInfo.put("deptDescription", dept.getDepartmentDescription());
                        return deptInfo;
                    })
                    .collect(Collectors.toList());
            
            result.put("depts", deptList);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(500, "获取子部门列表失败: " + e.getMessage());
        }
    }

    /**
     * 创建部门
     * @param request 部门创建请求
     * @return 响应结果
     */
    @Transactional
    public ApiResponse<String> createDept(DepartmentCreateRequest request) {
        try {
            // 验证部门名称
            if (request.getDeptName() == null || request.getDeptName().trim().isEmpty()) {
                return ApiResponse.error(400, "部门名称不能为空");
            }

            // 检查部门名称是否已存在
            List<Department> existingDepts = departmentRepository.findAll();
            for (Department dept : existingDepts) {
                if (dept.getDepartmentName().equals(request.getDeptName())) {
                    return ApiResponse.error(400, "部门名称已存在");
                }
            }

            Department department = new Department();
            department.setDepartmentName(request.getDeptName());
            department.setDepartmentDescription(request.getDeptDescription());

            // 设置父部门
            if (request.getParentDept() != null) {
                Department parentDept = departmentRepository.findById(request.getParentDept()).orElse(null);
                if (parentDept == null) {
                    return ApiResponse.error(404, "父部门不存在");
                }
                department.setParentDepartment(parentDept);
            }

            department.setCreationTime(LocalDateTime.now());
            department.setUpdateTime(LocalDateTime.now());

            departmentRepository.save(department);
            return ApiResponse.success("部门创建成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "创建部门失败: " + e.getMessage());
        }
    }

    /**
     * 更新部门
     * @param departmentId 部门ID
     * @param request 部门更新请求
     * @return 响应结果
     */
    @Transactional
    public ApiResponse<String> updateDept(Integer departmentId, DepartmentUpdateRequest request) {
        try {
            Department department = departmentRepository.findById(departmentId).orElse(null);
            if (department == null) {
                return ApiResponse.error(404, "部门不存在");
            }

            // 验证部门名称
            if (request.getDeptName() != null && !request.getDeptName().trim().isEmpty()) {
                // 检查部门名称是否与其他部门重复
                List<Department> existingDepts = departmentRepository.findAll();
                for (Department dept : existingDepts) {
                    if (!dept.getDepartmentId().equals(departmentId) 
                        && dept.getDepartmentName().equals(request.getDeptName())) {
                        return ApiResponse.error(400, "部门名称已存在");
                    }
                }
                department.setDepartmentName(request.getDeptName());
            }

            if (request.getDeptDescription() != null) {
                department.setDepartmentDescription(request.getDeptDescription());
            }

            // 更新父部门
            if (request.getParentDept() != null) {
                // 检查是否会产生循环引用
                if (request.getParentDept().equals(departmentId)) {
                    return ApiResponse.error(400, "不能将部门设置为自己的父部门");
                }
                
                Department parentDept = departmentRepository.findById(request.getParentDept()).orElse(null);
                if (parentDept == null) {
                    return ApiResponse.error(404, "父部门不存在");
                }
                
                // 检查是否会产生循环引用（父部门是自己的子部门）
                if (isDescendant(department, parentDept.getDepartmentId())) {
                    return ApiResponse.error(400, "不能将部门设置为其子部门的子部门");
                }
                
                department.setParentDepartment(parentDept);
            }

            department.setUpdateTime(LocalDateTime.now());
            departmentRepository.save(department);
            return ApiResponse.success("部门更新成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "更新部门失败: " + e.getMessage());
        }
    }

    /**
     * 检查部门是否是指定部门的子部门
     */
    private boolean isDescendant(Department department, Integer ancestorId) {
        Department current = department.getParentDepartment();
        while (current != null) {
            if (current.getDepartmentId().equals(ancestorId)) {
                return true;
            }
            current = current.getParentDepartment();
        }
        return false;
    }

    /**
     * 删除部门
     * @param deptId 部门ID
     * @return 响应结果
     */
    @Transactional
    public ApiResponse<String> deleteDept(Integer deptId) {
        try {
            Department department = departmentRepository.findById(deptId).orElse(null);
            if (department == null) {
                return ApiResponse.error(404, "部门不存在");
            }

            // 检查是否有子部门
            if (department.getSubDepartments() != null && !department.getSubDepartments().isEmpty()) {
                return ApiResponse.error(400, "该部门下有子部门，无法删除");
            }

            // 检查是否有关联用户
            List<User> users = userRepository.findByDepartmentDepartmentIdIn(Collections.singleton(deptId));
            if (!users.isEmpty()) {
                return ApiResponse.error(400, "该部门下有关联用户，无法删除");
            }

            departmentRepository.delete(department);
            return ApiResponse.success("部门删除成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "删除部门失败: " + e.getMessage());
        }
    }
}
