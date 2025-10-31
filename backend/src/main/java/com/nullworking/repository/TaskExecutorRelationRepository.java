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

	@Query("SELECT r.task.taskId FROM TaskExecutorRelation r WHERE r.executor.userId = :userId AND r.task.taskStatus <> 3")
	List<Integer> findActiveTaskIdsByExecutor(@Param("userId") Integer userId);

	@Query("SELECT r.executor.userId FROM TaskExecutorRelation r WHERE r.task.taskId = :taskId AND r.task.taskStatus <> 3")
	List<Integer> findActiveExecutorIdsByTaskId(@Param("taskId") Integer taskId);

	@Query("SELECT r.task.taskId FROM TaskExecutorRelation r WHERE r.executor.userId = :userId")
	List<Integer> findAllTaskIdsByExecutor(@Param("userId") Integer userId);

	@Query("SELECT r.executor.userId FROM TaskExecutorRelation r WHERE r.task.taskId = :taskId")
	List<Integer> findAllExecutorIdsByTaskId(@Param("taskId") Integer taskId);

	boolean existsByTask_TaskIdAndExecutor_UserId(Integer taskId, Integer userId);

	boolean existsByExecutor_UserId(Integer userId);
}
