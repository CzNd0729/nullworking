package com.nullworking.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;

import java.time.LocalDateTime;

@Data
@Entity
@DynamicInsert
@DynamicUpdate
@Table(name = "notification")
@EqualsAndHashCode
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Integer id;

    @Column(name = "receiver_id", nullable = false)
    private Integer receiverId;

    @Column(name = "content", nullable = false, length = 500)
    private String content;

    @Column(name = "related_type", nullable = false, length = 20)
    private String relatedType;

    @Column(name = "related_id", nullable = false)
    private Integer relatedId;

    @Column(name = "is_read", nullable = false)
    private Boolean isRead;

    @Column(name = "creation_time", nullable = false, updatable = false)
    private LocalDateTime creationTime;
}
