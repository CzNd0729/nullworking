package com.nullworking.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.Log;

@Repository
public interface LogRepository extends JpaRepository<Log, Integer> {
    List<Log> findByTaskTaskIdAndLogStatus(Integer taskId, Integer logStatus);

    void deleteByTaskTaskIdAndLogStatus(Integer taskId, Integer logStatus);
    
    Optional<Log> findByLogIdAndUserUserId(Integer logId, Integer userId);

    List<Log> findByUserUserIdAndLogDateBetween(Integer userId, LocalDate startDate, LocalDate endDate);

    List<Log> findByTaskTaskIdOrderByTaskProgressAsc(Integer taskId);

    Optional<Log> findTopByTaskTaskIdAndLogStatusOrderByTaskProgressDesc(Integer taskId, Integer logStatus);

    List<Log> findByUserUserId(Integer userId);
    List<Log> findByUserUserIdInAndLogDateBetween(List<Integer> userIds, LocalDate startDate, LocalDate endDate);
}
