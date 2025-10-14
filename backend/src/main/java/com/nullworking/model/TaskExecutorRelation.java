package com.nullworking.model;

import jakarta.persistence.*;
import java.io.Serializable;

@Entity
@Table(name = "Task_Executor_Relation")
public class TaskExecutorRelation implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "Relation_ID")
    private Integer relationId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "Executor_ID", nullable = false)
    private User executor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "Task_ID", nullable = false)
    private Task task;

    // Getters and Setters
    public Integer getRelationId() {
        return relationId;
    }

    public void setRelationId(Integer relationId) {
        this.relationId = relationId;
    }

    public User getExecutor() {
        return executor;
    }

    public void setExecutor(User executor) {
        this.executor = executor;
    }

    public Task getTask() {
        return task;
    }

    public void setTask(Task task) {
        this.task = task;
    }

}
