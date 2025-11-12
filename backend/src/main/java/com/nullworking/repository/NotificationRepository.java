package com.nullworking.repository;

import com.nullworking.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Integer> {
    List<Notification> findByReceiverIdOrderByCreationTimeDesc(Integer receiverId);
}
