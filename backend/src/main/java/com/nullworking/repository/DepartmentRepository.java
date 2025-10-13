package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.Department;

@Repository
public interface DepartmentRepository extends JpaRepository<Department, Integer> {
}
