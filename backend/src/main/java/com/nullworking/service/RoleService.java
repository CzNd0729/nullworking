package com.nullworking.service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Permission;
import com.nullworking.model.Role;
import com.nullworking.model.RolePermissionRelation;
import com.nullworking.model.User;
import com.nullworking.model.dto.RoleCreateRequest;
import com.nullworking.model.dto.RoleUpdateRequest;
import com.nullworking.repository.PermissionRepository;
import com.nullworking.repository.RolePermissionRelationRepository;
import com.nullworking.repository.RoleRepository;
import com.nullworking.repository.UserRepository;

@Service
public class RoleService {

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PermissionRepository permissionRepository;

    @Autowired
    private RolePermissionRelationRepository rolePermissionRelationRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * 列出所有角色
     * @return 包含角色列表的响应
     */
    public ApiResponse<Map<String, Object>> listRoles() {
        try {
            List<Role> roles = roleRepository.findAll();

            // 构建响应数据
            Map<String, Object> result = new HashMap<>();
            List<Map<String, Object>> roleList = roles.stream()
                    .map(role -> {
                        Map<String, Object> roleInfo = new HashMap<>();
                        roleInfo.put("roleId", role.getRoleId());
                        roleInfo.put("roleName", role.getRoleName());
                        roleInfo.put("roleDescription", role.getRoleDescription());
                        return roleInfo;
                    })
                    .collect(Collectors.toList());
            
            result.put("roles", roleList);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(500, "获取角色列表失败: " + e.getMessage());
        }
    }

    /**
     * 创建角色
     * @param request 角色创建请求
     * @return 响应结果
     */
    @Transactional
    public ApiResponse<String> createRole(RoleCreateRequest request) {
        try {
            // 验证角色名称
            if (request.getRoleName() == null || request.getRoleName().trim().isEmpty()) {
                return ApiResponse.error(400, "角色名称不能为空");
            }

            // 检查角色名称是否已存在
            List<Role> existingRoles = roleRepository.findAll();
            for (Role role : existingRoles) {
                if (role.getRoleName().equals(request.getRoleName())) {
                    return ApiResponse.error(400, "角色名称已存在");
                }
            }

            // 创建角色
            Role role = new Role();
            role.setRoleName(request.getRoleName());
            role.setRoleDescription(request.getRoleDescription());
            role.setCreationTime(LocalDateTime.now());
            role.setUpdateTime(LocalDateTime.now());

            Role savedRole = roleRepository.save(role);

            // 关联权限
            if (request.getPermissions() != null && !request.getPermissions().isEmpty()) {
                for (Integer permissionId : request.getPermissions()) {
                    Permission permission = permissionRepository.findById(permissionId).orElse(null);
                    if (permission == null) {
                        return ApiResponse.error(404, "权限ID " + permissionId + " 不存在");
                    }

                    RolePermissionRelation relation = new RolePermissionRelation();
                    relation.setRole(savedRole);
                    relation.setPermission(permission);
                    rolePermissionRelationRepository.save(relation);
                }
            }

            return ApiResponse.success("角色创建成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "创建角色失败: " + e.getMessage());
        }
    }

    /**
     * 更新角色
     * @param request 角色更新请求
     * @return 响应结果
     */
    @Transactional
    public ApiResponse<String> updateRole(RoleUpdateRequest request) {
        try {
            Role role = roleRepository.findById(request.getRoleId()).orElse(null);
            if (role == null) {
                return ApiResponse.error(404, "角色不存在");
            }

            // 更新角色名称
            if (request.getRoleName() != null && !request.getRoleName().trim().isEmpty()) {
                // 检查角色名称是否与其他角色重复
                List<Role> existingRoles = roleRepository.findAll();
                for (Role r : existingRoles) {
                    if (!r.getRoleId().equals(request.getRoleId()) 
                        && r.getRoleName().equals(request.getRoleName())) {
                        return ApiResponse.error(400, "角色名称已存在");
                    }
                }
                role.setRoleName(request.getRoleName());
            }

            if (request.getRoleDescription() != null) {
                role.setRoleDescription(request.getRoleDescription());
            }

            role.setUpdateTime(LocalDateTime.now());
            roleRepository.save(role);

            // 更新权限关联
            if (request.getPermissions() != null) {
                // 删除旧的权限关联
                List<RolePermissionRelation> oldRelations = rolePermissionRelationRepository.findByRole_RoleId(request.getRoleId());
                for (RolePermissionRelation relation : oldRelations) {
                    rolePermissionRelationRepository.delete(relation);
                }

                // 添加新的权限关联
                if (!request.getPermissions().isEmpty()) {
                    for (Integer permissionId : request.getPermissions()) {
                        Permission permission = permissionRepository.findById(permissionId).orElse(null);
                        if (permission == null) {
                            return ApiResponse.error(404, "权限ID " + permissionId + " 不存在");
                        }

                        RolePermissionRelation relation = new RolePermissionRelation();
                        relation.setRole(role);
                        relation.setPermission(permission);
                        rolePermissionRelationRepository.save(relation);
                    }
                }
            }

            return ApiResponse.success("角色更新成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "更新角色失败: " + e.getMessage());
        }
    }

    /**
     * 删除角色
     * @param roleId 角色ID
     * @return 响应结果
     */
    @Transactional
    public ApiResponse<String> deleteRole(Integer roleId) {
        try {
            Role role = roleRepository.findById(roleId).orElse(null);
            if (role == null) {
                return ApiResponse.error(404, "角色不存在");
            }

            // 检查是否有关联用户
            List<User> allUsers = userRepository.findAll();
            for (User user : allUsers) {
                if (user.getRole() != null && user.getRole().getRoleId().equals(roleId)) {
                    return ApiResponse.error(400, "该角色下有关联用户，无法删除");
                }
            }

            // 删除权限关联
            List<RolePermissionRelation> relations = rolePermissionRelationRepository.findByRole_RoleId(roleId);
            for (RolePermissionRelation relation : relations) {
                rolePermissionRelationRepository.delete(relation);
            }

            // 删除角色
            roleRepository.delete(role);
            return ApiResponse.success("角色删除成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "删除角色失败: " + e.getMessage());
        }
    }
}
