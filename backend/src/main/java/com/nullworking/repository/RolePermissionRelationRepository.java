package com.nullworking.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.RolePermissionRelation;

@Repository
public interface RolePermissionRelationRepository extends JpaRepository<RolePermissionRelation, Integer> {
    List<RolePermissionRelation> findByRole_RoleId(Integer roleId);
    Optional<RolePermissionRelation> findByRole_RoleIdAndPermission_PermissionId(Integer roleId, Integer permissionId);
}
