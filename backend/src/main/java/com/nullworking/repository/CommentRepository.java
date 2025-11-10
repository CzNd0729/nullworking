package com.nullworking.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nullworking.model.Comment;

public interface CommentRepository extends JpaRepository<Comment, Integer> {
    Optional<Comment> findByIdAndUserIdAndIsDeletedFalse(Integer id, Integer userId);

    // Order by latest activity: use updated_at if present, otherwise created_at
    @Query(value = "SELECT * FROM comment WHERE log_id = :logId AND is_deleted = 0 ORDER BY COALESCE(updated_at, created_at) DESC", nativeQuery = true)
    List<Comment> findByLogIdAndIsDeletedFalseOrderByLatest(@Param("logId") Integer logId);
}
