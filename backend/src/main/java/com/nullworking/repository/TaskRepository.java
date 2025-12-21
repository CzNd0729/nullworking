package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.Task;
import java.util.List;
import java.time.LocalDateTime;

@Repository
public interface TaskRepository extends JpaRepository<Task, Integer> {
	List<Task> findByCreator_UserIdAndTaskStatusNot(Integer userId, Byte taskStatus);

	List<Task> findByCreator_UserId(Integer userId);

	List<Task> findByDeadlineBetweenAndIsDeadlineNotifiedFalseAndTaskStatusNot(LocalDateTime start, LocalDateTime end, Byte taskStatus);

	/**
     * 查询截止时间在指定时间之前，且状态不在排除列表中的任务
     * @param deadline 截止时间上限（当前时间）
     * @param excludeStatuses 要排除的状态（已完成、已关闭）
     * @return 符合条件的任务列表
     */
    List<Task> findByDeadlineBeforeAndTaskStatusNotIn(LocalDateTime deadline, List<Byte> excludeStatuses);
}
