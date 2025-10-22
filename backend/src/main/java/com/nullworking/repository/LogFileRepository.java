package com.nullworking.repository;

import com.nullworking.model.LogFile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LogFileRepository extends JpaRepository<LogFile, Integer> {
    List<LogFile> findByLogId(Integer logId);
}
