package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.Permission;

@Repository
public interface PermissionRepository extends JpaRepository<Permission, Integer> {
}
