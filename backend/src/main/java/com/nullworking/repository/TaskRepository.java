package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.Task;
import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Integer> {
	List<Task> findByCreator_UserIdAndTaskStatusNot(Integer userId, Byte taskStatus);
}
