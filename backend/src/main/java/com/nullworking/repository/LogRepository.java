package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.nullworking.model.Log;

@Repository
public interface LogRepository extends JpaRepository<Log, Integer> {
	long deleteByTask_TaskId(Integer taskId);

	@Modifying
	@Query("DELETE FROM Log l WHERE l.task.taskId = :taskId")
	int deleteByTaskId(@Param("taskId") Integer taskId);
}
