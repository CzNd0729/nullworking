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

import java.util.Objects;

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
                        
                        // 获取该角色关联的权限ID
                        List<Integer> permissionIds = rolePermissionRelationRepository.findByRole_RoleId(role.getRoleId())
                                .stream()
                                .map(relation -> relation.getPermission().getPermissionId())
                                .collect(Collectors.toList());
                        roleInfo.put("permissionIds", permissionIds);

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

            // 确保“分配任务给该角色”的权限存在 (但不自动关联)
            String assignTaskPermissionName = "ASSIGN_TASK_TO_" + savedRole.getRoleName().toUpperCase();
            Permission assignTaskPermission = permissionRepository.findByPermissionName(assignTaskPermissionName)
                    .orElseGet(() -> {
                        Permission newPermission = new Permission();
                        newPermission.setPermissionName(assignTaskPermissionName);
                        newPermission.setPermissionDescription("允许将任务分配给" + savedRole.getRoleName());
                        newPermission.setCreationTime(LocalDateTime.now());
                        newPermission.setUpdateTime(LocalDateTime.now());
                        return permissionRepository.save(newPermission);
                    });

            // 关联请求中提供的权限
            if (request.getPermissionIds() != null && !request.getPermissionIds().isEmpty()) {
                for (Integer permissionId : request.getPermissionIds()) {
                    if (permissionId == null) {
                        continue; // Skip null permissionId
                    }

                    Permission permissionToAssociate = null;
                    if (assignTaskPermission != null && permissionId.equals(assignTaskPermission.getPermissionId())) {
                        permissionToAssociate = assignTaskPermission;
                    } else {
                        permissionToAssociate = permissionRepository.findById(permissionId).orElse(null);
                    }

                    if (permissionToAssociate == null) {
                        return ApiResponse.error(404, "权限ID " + permissionId + " 不存在");
                    }

                    // 检查是否已存在该权限关联，避免重复添加
                    if (savedRole.getRoleId() != null && permissionToAssociate.getPermissionId() != null) {
                        if (rolePermissionRelationRepository.findByRole_RoleIdAndPermission_PermissionId(savedRole.getRoleId(), permissionToAssociate.getPermissionId()).isPresent()) {
                            continue; // Skip if already associated
                        }
                    }

                    RolePermissionRelation relation = new RolePermissionRelation();
                    relation.setRole(savedRole);
                    relation.setPermission(permissionToAssociate);
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
    public ApiResponse<String> updateRole(Integer roleId, RoleUpdateRequest request) {
        try {
            if (roleId == null) {
                return ApiResponse.error(400, "角色ID不能为空");
            }
            Role role = roleRepository.findById(Objects.requireNonNull(roleId)).orElse(null);
            if (role == null) {
                return ApiResponse.error(404, "角色不存在");
            }

            // 更新角色名称
            if (request.getRoleName() != null && !request.getRoleName().trim().isEmpty()) {
                // 检查角色名称是否与其他角色重复
                List<Role> existingRoles = roleRepository.findAll();
                for (Role r : existingRoles) {
                    if (r.getRoleId() != null && !r.getRoleId().equals(roleId) 
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

            // 确保“分配任务给该角色”的权限存在 (但不自动关联)
            String assignTaskPermissionName = "ASSIGN_TASK_TO_" + role.getRoleName().toUpperCase();
            Permission assignTaskPermission = permissionRepository.findByPermissionName(assignTaskPermissionName)
                    .orElseGet(() -> {
                        Permission newPermission = new Permission();
                        newPermission.setPermissionName(assignTaskPermissionName);
                        newPermission.setPermissionDescription("允许将任务分配给 " + role.getRoleName() + ".");
                        newPermission.setCreationTime(LocalDateTime.now());
                        newPermission.setUpdateTime(LocalDateTime.now());
                        return permissionRepository.save(newPermission);
                    });
            
            // 更新权限关联
            if (request.getPermissionIds() != null) {
                // 删除旧的权限关联 (只删除不在请求中的权限)
                List<RolePermissionRelation> oldRelations = rolePermissionRelationRepository.findByRole_RoleId(roleId);
                Set<Integer> newPermissionIds = new HashSet<>(request.getPermissionIds());

                for (RolePermissionRelation relation : oldRelations) {
                    if (relation == null || relation.getPermission() == null || relation.getPermission().getPermissionId() == null) {
                        continue; // Skip null relations or relations with null permissions
                    }
                    if (!newPermissionIds.contains(relation.getPermission().getPermissionId())) {
                        rolePermissionRelationRepository.delete(relation);
                    }
                }

                // 添加新的权限关联
                if (!request.getPermissionIds().isEmpty()) {
                    for (Integer permissionId : request.getPermissionIds()) {
                        if (permissionId == null) {
                            continue; // Skip null permissionId
                        }
                        
                        Permission permissionToAssociate = null;
                        if (assignTaskPermission != null && permissionId.equals(assignTaskPermission.getPermissionId())) {
                            permissionToAssociate = assignTaskPermission;
                        } else {
                            permissionToAssociate = permissionRepository.findById(permissionId).orElse(null);
                        }

                        if (permissionToAssociate == null) {
                            return ApiResponse.error(404, "权限ID " + permissionId + " 不存在");
                        }

                        // 检查是否已存在该权限关联，避免重复添加
                        if (role.getRoleId() != null && permissionToAssociate.getPermissionId() != null) {
                            if (rolePermissionRelationRepository.findByRole_RoleIdAndPermission_PermissionId(role.getRoleId(), permissionToAssociate.getPermissionId()).isPresent()) {
                                continue; // Skip if already associated
                            }
                        }

                        RolePermissionRelation relation = new RolePermissionRelation();
                        relation.setRole(role);
                        relation.setPermission(permissionToAssociate);
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
            if (roleId == null) {
                return ApiResponse.error(400, "角色ID不能为空");
            }
            Role role = roleRepository.findById(roleId).orElse(null);
            if (role == null) {
                return ApiResponse.error(404, "角色不存在");
            }

            // 检查是否有关联用户
            List<User> allUsers = userRepository.findAll();
            for (User user : allUsers) {
                if (user == null) {
                    continue; // Skip null user
                }
                if (user.getRole() != null && user.getRole().getRoleId() != null && user.getRole().getRoleId().equals(roleId)) {
                    return ApiResponse.error(400, "该角色下有关联用户，无法删除");
                }
            }

            // 删除权限关联
            List<RolePermissionRelation> relations = rolePermissionRelationRepository.findByRole_RoleId(roleId);
            for (RolePermissionRelation relation : relations) {
                if (relation == null) {
                    continue; // Skip null relation
                }
                rolePermissionRelationRepository.delete(relation);
            }

            // 删除角色
            roleRepository.delete(role);
            return ApiResponse.success("角色删除成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "删除角色失败: " + e.getMessage());
        }
    }

    /**
     * 列出所有权限
     * @return 包含权限列表的响应
     */
    public ApiResponse<Map<String, Object>> listPermissions() {
        try {
            List<Permission> permissions = permissionRepository.findAll();
            Map<String, Object> result = new HashMap<>();
            List<Map<String, Object>> permissionList = permissions.stream()
                    .map(permission -> {
                        Map<String, Object> permissionInfo = new HashMap<>();
                        permissionInfo.put("permissionId", permission.getPermissionId());
                        permissionInfo.put("permissionName", permission.getPermissionName());
                        permissionInfo.put("permissionDescription", permission.getPermissionDescription());
                        return permissionInfo;
                    })
                    .collect(Collectors.toList());
            result.put("permissions", permissionList);
            return ApiResponse.success(result);
        } catch (Exception e) {
            return ApiResponse.error(500, "获取权限列表失败: " + e.getMessage());
        }
    }
}
