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

            // 构建“扁平但按层级深度优先排序”的返回，保持前端键名不变（depts）
            Map<String, Object> result = new HashMap<>();
            List<Map<String, Object>> ordered = new ArrayList<>();
            for (Department child : departments) {
                buildFlatDeptOrder(child, 0, ordered);
            }
            result.put("depts", ordered);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(500, "获取子部门列表失败: " + e.getMessage());
        }
    }

    /**
     * 将部门树拍平成深度优先顺序的列表，保持兼容字段
     */
    private void buildFlatDeptOrder(Department dept, int level, List<Map<String, Object>> acc) {
        Map<String, Object> node = new HashMap<>();
        node.put("deptId", dept.getDepartmentId());
        node.put("deptName", dept.getDepartmentName());
        node.put("deptDescription", dept.getDepartmentDescription());
        node.put("level", level); // 可供前端可选使用做缩进；不影响兼容
        acc.add(node);

        if (dept.getSubDepartments() != null && !dept.getSubDepartments().isEmpty()) {
            // 可按名称排序，保证稳定输出
            List<Department> children = new ArrayList<>(dept.getSubDepartments());
            children.sort(Comparator.comparing(Department::getDepartmentName, Comparator.nullsLast(String::compareTo)));
            for (Department child : children) {
                buildFlatDeptOrder(child, level + 1, acc);
            }
        }
    }

    /**
     * 构建整棵部门树（从所有根部门开始）
     */
    public ApiResponse<Map<String, Object>> getDeptTree() {
        try {
            List<Department> roots = departmentRepository.findByParentDepartment_departmentIdIsNull();

            List<Map<String, Object>> tree = new ArrayList<>();
            for (Department root : roots) {
                tree.add(buildDeptNode(root));
            }

            Map<String, Object> result = new HashMap<>();
            result.put("tree", tree);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(500, "获取部门树失败: " + e.getMessage());
        }
    }

    /**
     * 构建某个部门为根的子树
     */
    public ApiResponse<Map<String, Object>> getDeptSubTree(Integer departmentId) {
        try {
            Department root = departmentRepository.findById(departmentId).orElse(null);
            if (root == null) {
                return ApiResponse.error(404, "部门不存在");
            }

            Map<String, Object> node = buildDeptNode(root);
            Map<String, Object> result = new HashMap<>();
            // 与 getDeptTree 返回结构保持一致，使用列表承载
            result.put("tree", Collections.singletonList(node));
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(500, "获取部门子树失败: " + e.getMessage());
        }
    }

    /**
     * 递归构建节点
     */
    private Map<String, Object> buildDeptNode(Department dept) {
        Map<String, Object> node = new HashMap<>();
        node.put("deptId", dept.getDepartmentId());
        node.put("deptName", dept.getDepartmentName());
        node.put("deptDescription", dept.getDepartmentDescription());

        List<Map<String, Object>> children = new ArrayList<>();
        if (dept.getSubDepartments() != null && !dept.getSubDepartments().isEmpty()) {
            for (Department child : dept.getSubDepartments()) {
                children.add(buildDeptNode(child));
            }
        }
        node.put("children", children);
        return node;
    }

    /**
     * 创建部门
     * @param request 部门创建请求
     * @return 响应结果
     */
    @Transactional
    public ApiResponse<Integer> createDept(DepartmentCreateRequest request) {
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
            return ApiResponse.success(department.getDepartmentId());
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
                
                // 检查是否会产生循环引用（新父部门不能是当前部门的后代）
                if (isDescendantOf(parentDept, departmentId)) {
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
     * 检查部门是否是指定部门的后代（子孙部门）
     * @param department 要检查的部门
     * @param ancestorId 祖先部门ID
     * @return 如果department的祖先链中包含ancestorId，返回true
     */
    private boolean isDescendantOf(Department department, Integer ancestorId) {
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
