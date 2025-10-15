package com.nullworking.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.Department;

@Repository
public interface DepartmentRepository extends JpaRepository<Department, Integer> {
    List<Department> findByParentDepartment_departmentId(Integer parentDepartmentId);
    List<Department> findByParentDepartment_departmentIdIsNull();
}
