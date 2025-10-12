package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.TaskExecutorRelation;

@Repository
public interface TaskExecutorRelationRepository extends JpaRepository<TaskExecutorRelation, Integer> {
}
