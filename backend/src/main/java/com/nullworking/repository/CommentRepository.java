package com.nullworking.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nullworking.model.Comment;

public interface CommentRepository extends JpaRepository<Comment, Integer> {
    Optional<Comment> findByIdAndUserIdAndIsDeletedFalse(Integer id, Integer userId);

    List<Comment> findByLogIdAndIsDeletedFalseOrderByCreatedAtAsc(Integer logId);
}
