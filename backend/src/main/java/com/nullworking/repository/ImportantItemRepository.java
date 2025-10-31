package com.nullworking.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.ImportantItem;
import com.nullworking.model.User;

@Repository
public interface ImportantItemRepository extends JpaRepository<ImportantItem, Integer> {
    Optional<ImportantItem> findByUserAndDisplayOrder(User user, Byte displayOrder);
    List<ImportantItem> findByUser_UserIdOrderByDisplayOrder(Integer userId);
    List<ImportantItem> findByUserAndDisplayOrderGreaterThan(User user, Byte displayOrder);
    Integer countByUser(User user);
}
