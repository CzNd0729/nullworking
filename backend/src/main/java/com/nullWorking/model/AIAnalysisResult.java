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
    @Column(name = "Keyword_Imformation", nullable = false)
    private String keywordInformation;

    @Lob
    @Column(name = "Trend_Analysis", nullable = false)
    private String trendAnalysis;

    @Lob
    @Column(name = "Task_List", nullable = false)
    private String taskList;

    @Lob
    @Column(name = "Constructive_Suggestions", nullable = false)
    private String constructiveSuggestions;

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

    public String getKeywordInformation() {
        return keywordInformation;
    }

    public void setKeywordInformation(String keywordInformation) {
        this.keywordInformation = keywordInformation;
    }

    public String getTrendAnalysis() {
        return trendAnalysis;
    }

    public void setTrendAnalysis(String trendAnalysis) {
        this.trendAnalysis = trendAnalysis;
    }

    public String getTaskList() {
        return taskList;
    }

    public void setTaskList(String taskList) {
        this.taskList = taskList;
    }

    public String getConstructiveSuggestions() {
        return constructiveSuggestions;
    }

    public void setConstructiveSuggestions(String constructiveSuggestions) {
        this.constructiveSuggestions = constructiveSuggestions;
    }

    public LocalDate getAnalysisDate() {
        return analysisDate;
    }

    public void setAnalysisDate(LocalDate analysisDate) {
        this.analysisDate = analysisDate;
    }
}
