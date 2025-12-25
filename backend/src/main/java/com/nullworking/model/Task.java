package com.nullworking.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Lob;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;


@Entity
@Table(name = "Task")
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "Task_ID")
    private Integer taskId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "Creator_ID", nullable = false)
    private User creator;

    @Column(name = "Task_Title", nullable = false, length = 128)
    private String taskTitle;

    @Lob
    @Column(name = "Task_Content", nullable = false, columnDefinition = "TEXT")
    private String taskContent;

    @Column(name = "Priority", nullable = false)
    private Byte priority;

    @Column(name = "Task_Status", nullable = false)
    private Byte taskStatus;

    @Column(name = "Creation_Time", nullable = false)
    private LocalDateTime creationTime;

    @Column(name = "Deadline", nullable = false)
    private LocalDateTime deadline;


    @Column(name = "Completion_Time")
    private LocalDateTime completionTime;

    @Column(name = "Is_Deadline_Notified", nullable = false, columnDefinition = "boolean default false")
    private Boolean isDeadlineNotified = false;

    // Getters and Setters
    public Integer getTaskId() {
        return taskId;
    }

    public void setTaskId(Integer taskId) {
        this.taskId = taskId;
    }

    public User getCreator() {
        return creator;
    }

    public void setCreator(User creator) {
        this.creator = creator;
    }

    public String getTaskTitle() {
        return taskTitle;
    }

    public void setTaskTitle(String taskTitle) {
        this.taskTitle = taskTitle;
    }

    public String getTaskContent() {
        return taskContent;
    }

    public void setTaskContent(String taskContent) {
        this.taskContent = taskContent;
    }

    public Byte getPriority() {
        return priority;
    }

    public void setPriority(Byte priority) {
        this.priority = priority;
    }

    public Byte getTaskStatus() {
        return taskStatus;
    }

    public void setTaskStatus(Byte taskStatus) {
        this.taskStatus = taskStatus;
    }

    public LocalDateTime getCreationTime() {
        return creationTime;
    }

    public void setCreationTime(LocalDateTime creationTime) {
        this.creationTime = creationTime;
    }

    public LocalDateTime getDeadline() {
        return deadline;
    }

    public void setDeadline(LocalDateTime deadline) {
        this.deadline = deadline;
    }

    public LocalDateTime getCompletionTime() {
        return completionTime;
    }

    public void setCompletionTime(LocalDateTime completionTime) {
        this.completionTime = completionTime;
    }

    // Custom getters for AIAnalysisService compatibility
    public LocalDateTime getStartTime() {
        return creationTime;
    }

    public LocalDateTime getEndTime() {
        return deadline;
    }
    
    public Boolean getIsDeadlineNotified() {
        return isDeadlineNotified;
    }

    public void setIsDeadlineNotified(Boolean isDeadlineNotified) {
        this.isDeadlineNotified = isDeadlineNotified;
    }
}
