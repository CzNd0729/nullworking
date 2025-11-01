package com.nullworking.model;

import jakarta.persistence.*;
import java.time.LocalDate;

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

    @Column(name = "Analysis_Date", nullable = false)
    private LocalDate analysisDate;

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

    public LocalDate getAnalysisDate() {
        return analysisDate;
    }

    public void setAnalysisDate(LocalDate analysisDate) {
        this.analysisDate = analysisDate;
    }
}
