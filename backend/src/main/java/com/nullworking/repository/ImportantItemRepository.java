package com.nullworking.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.ImportantItem;

@Repository
public interface ImportantItemRepository extends JpaRepository<ImportantItem, Integer> {
}
