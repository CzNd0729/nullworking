package com.nullworking.model.dto;

import java.time.LocalDateTime;
import java.util.Map;

public class AIAnalysisResultSummaryDTO {
    private Integer resultId;
    private LocalDateTime analysisTime;
    private Map<String, Object> prompt;
    private Integer status;
    private Integer mode;

    public AIAnalysisResultSummaryDTO(Integer resultId ,LocalDateTime analysisTime, Map<String, Object> prompt) {
        this.resultId = resultId;
        this.analysisTime = analysisTime;
        this.prompt = prompt;
    }

    public AIAnalysisResultSummaryDTO(Integer resultId ,LocalDateTime analysisTime, Map<String, Object> prompt, Integer status, Integer mode) {
        this.resultId = resultId;
        this.analysisTime = analysisTime;
        this.prompt = prompt;
        this.status = status;
        this.mode = mode;
    }

    public LocalDateTime getAnalysisTime() {
        return analysisTime;
    }

    public void setAnalysisTime(LocalDateTime analysisTime) {
        this.analysisTime = analysisTime;
    }

    public Map<String, Object> getPrompt() {
        return prompt;
    }

    public void setPrompt(Map<String, Object> prompt) {
        this.prompt = prompt;
    }

    public Integer getResultId() {
        return resultId;
    }

    public void setResultId(Integer resultId) {
        this.resultId = resultId;
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
