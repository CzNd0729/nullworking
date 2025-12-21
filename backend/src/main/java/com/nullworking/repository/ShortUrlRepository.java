package com.nullworking.repository;

import com.nullworking.model.ShortUrl;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * 短链接表数据访问层
 * 继承JpaRepository，复用Spring Data JPA默认CRUD方法
 */
@Repository
public interface ShortUrlRepository extends JpaRepository<ShortUrl, Long> {
    /**
     * 根据短码查询短链接记录
     * @param shortCode 短码
     * @return 短链接实体（Optional避免空指针）
     */
    Optional<ShortUrl> findByShortCode(String shortCode);

    /**
     * 校验短码是否已存在（避免重复）
     * @param shortCode 短码
     * @return true=已存在，false=不存在
     */
    boolean existsByShortCode(String shortCode);
}