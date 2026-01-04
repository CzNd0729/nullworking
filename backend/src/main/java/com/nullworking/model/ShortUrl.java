package com.nullworking.model;

import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * 短链接映射表实体类
 * 与数据库short_url表一一映射
 */
@Data
@Entity
@Table(name = "short_url") // 替换为你实际的表名
public class ShortUrl {
    /**
     * 主键ID（自增）
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 短码（6位，唯一）
     */
    @Column(name = "short_code", nullable = false, unique = true, length = 8)
    private String shortCode;

    /**
     * 关联的AI分析结果ID
     */
    @Column(name = "result_id", nullable = false)
    private Integer resultId;

    /**
     * 生成短链接的用户ID（鉴权用）
     */
    @Column(name = "user_id", nullable = false)
    private Integer userId;

    /**
     * 过期时间（默认7天）
     */
    @Column(name = "expire_time", nullable = false)
    private LocalDateTime expireTime;

    /**
     * 创建时间（自动填充）
     */
    @CreationTimestamp
    @Column(name = "create_time", updatable = false)
    private LocalDateTime createTime;

    /**
     * 访问次数（统计用）
     */
    @Column(name = "visit_count")
    private Integer visitCount = 0;
}