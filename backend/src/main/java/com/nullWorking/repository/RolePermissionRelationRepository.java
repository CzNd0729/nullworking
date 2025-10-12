package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.RolePermissionRelation;

@Repository
public interface RolePermissionRelationRepository extends JpaRepository<RolePermissionRelation, Integer> {
}
