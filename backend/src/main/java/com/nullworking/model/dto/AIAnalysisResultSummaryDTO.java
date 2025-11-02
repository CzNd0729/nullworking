package com.nullworking.model.dto;

import java.time.LocalDateTime;

public class AIAnalysisResultSummaryDTO {
    private Integer resultId;
    private LocalDateTime analysisTime;
    private String prompt;

    public AIAnalysisResultSummaryDTO(Integer resultId ,LocalDateTime analysisTime, String prompt) {
        this.resultId = resultId;
        this.analysisTime = analysisTime;
        this.prompt = prompt;
    }

    public LocalDateTime getAnalysisTime() {
        return analysisTime;
    }

    public void setAnalysisTime(LocalDateTime analysisTime) {
        this.analysisTime = analysisTime;
    }

    public String getPrompt() {
        return prompt;
    }

    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }

    public Integer getResultId() {
        return resultId;
    }

    public void setResultId(Integer resultId) {
        this.resultId = resultId;
    }
}
