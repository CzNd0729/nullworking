package com.nullworking.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "AI_Analysis_Result")
public class AIAnalysisResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "Result_ID")
    private Integer resultId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "User_ID", nullable = false)
    private User user;

    @Lob
    @Column(name = "Prompt", nullable = false, columnDefinition = "MEDIUMTEXT")
    private String prompt;

    @Lob
    @Column(name = "Content", nullable = false, columnDefinition = "MEDIUMTEXT")
    private String content;

    @Column(name = "Analysis_Time", nullable = false)
    private LocalDateTime analysisTime;

    @Column(name = "Status", nullable = false)
    private Integer status; // 0: 分析中, 1: 分析完成，2: 分析失败（乱码）3: 分析失败（其他原因）

    @Column(name = "Mode", nullable = false)
    private Integer mode; // 0: 用户+时间模式, 1: 仅任务模式

    // Getters and Setters
    public Integer getResultId() {
        return resultId;
    }

    public void setResultId(Integer resultId) {
        this.resultId = resultId;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getPrompt() {
        return prompt;
    }

    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public LocalDateTime getAnalysisTime() {
        return analysisTime;
    }

    public void setAnalysisTime(LocalDateTime analysisTime) {
        this.analysisTime = analysisTime;
    }

    public Integer getStatus() {
        return status;
    }

    public void setStatus(Integer status) {
        this.status = status;
    }

    public Integer getMode() {
        return mode;
    }

    public void setMode(Integer mode) {
        this.mode = mode;
    }
}
