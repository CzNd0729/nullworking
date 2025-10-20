package com.nullworking.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.Log;

@Repository
public interface LogRepository extends JpaRepository<Log, Integer> {
    List<Log> findByTaskTaskIdAndLogStatus(Integer taskId, Integer logStatus);

    void deleteByTaskTaskIdAndLogStatus(Integer taskId, Integer logStatus);
}
