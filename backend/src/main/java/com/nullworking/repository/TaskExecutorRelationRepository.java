package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.nullworking.model.TaskExecutorRelation;
import java.util.List;

@Repository
public interface TaskExecutorRelationRepository extends JpaRepository<TaskExecutorRelation, Integer> {
	long deleteByTask_TaskId(Integer taskId);

	@Modifying
	@Query("DELETE FROM TaskExecutorRelation r WHERE r.task.taskId = :taskId")
	int deleteByTaskId(@Param("taskId") Integer taskId);

	@Modifying
	@Query("UPDATE TaskExecutorRelation r SET r.taskIsDeleted = TRUE WHERE r.task.taskId = :taskId")
	int markTaskDeleted(@Param("taskId") Integer taskId);

	@Query("SELECT r.task.taskId FROM TaskExecutorRelation r WHERE r.executor.userId = :userId AND r.taskIsDeleted = FALSE")
	List<Integer> findActiveTaskIdsByExecutor(@Param("userId") Integer userId);

	@Query("SELECT r.executor.userId FROM TaskExecutorRelation r WHERE r.task.taskId = :taskId AND r.taskIsDeleted = FALSE")
	List<Integer> findActiveExecutorIdsByTaskId(@Param("taskId") Integer taskId);
}
