package com.nullworking.repository;

import com.nullworking.model.ShortUrl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.time.LocalDateTime;

/**
 * 短链接表数据访问层
 * 继承JpaRepository，复用Spring Data JPA默认CRUD方法
 */
@Repository
public interface ShortUrlRepository extends JpaRepository<ShortUrl, Long> {
    Optional<ShortUrl> findByShortCode(String shortCode);
    boolean existsByShortCode(String shortCode);
    
    // 新增：查询未过期的短链接
    Optional<ShortUrl> findByResultIdAndExpireTimeAfter(Integer resultId, LocalDateTime now);
}