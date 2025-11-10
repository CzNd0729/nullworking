package com.nullworking.service;

import com.nullworking.model.Permission;
import com.nullworking.model.User;
import com.nullworking.repository.PermissionRepository;
import com.nullworking.repository.RolePermissionRelationRepository;
import com.nullworking.repository.UserRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class PermissionService {

    @Autowired
    private PermissionRepository permissionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RolePermissionRelationRepository rolePermissionRelationRepository;

    /**
     * 检查用户是否拥有对目标用户分配任务的权限。
     * 一个用户A拥有对用户B分配任务的权限，当且仅当用户A拥有“ASSIGN_TASK_TO_用户B的角色名”的权限。
     * @param currentUserId 当前用户ID
     * @param targetUser 目标用户
     * @return 如果拥有权限返回 true，否则返回 false
     */
    public boolean canAssignTaskToUser(Integer currentUserId, User targetUser) {
        if (currentUserId == null || targetUser == null || targetUser.getRole() == null || targetUser.getRole().getRoleName() == null) {
            return false;
        }

        User currentUser = userRepository.findById(currentUserId).orElse(null);
        if (currentUser == null) {
            return false;
        }

        if (currentUser.getRole() == null) {
            return false;
        }

        String requiredPermissionName = "ASSIGN_TASK_TO_" + targetUser.getRole().getRoleName().toUpperCase();
        Optional<Permission> requiredPermission = permissionRepository.findByPermissionName(requiredPermissionName);

        if (requiredPermission.isEmpty()) {
            return false; // 如果所需权限不存在，则认为无权
        }

        // 检查当前用户是否拥有该权限
        return rolePermissionRelationRepository.findByRole_RoleId(currentUser.getRole().getRoleId())
                .stream()
                .anyMatch(relation -> relation.getPermission().getPermissionId().equals(requiredPermission.get().getPermissionId()));
    }
}
