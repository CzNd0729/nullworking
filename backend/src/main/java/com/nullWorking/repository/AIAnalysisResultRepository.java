package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.AIAnalysisResult;

@Repository
public interface AIAnalysisResultRepository extends JpaRepository<AIAnalysisResult, Integer> {
}
