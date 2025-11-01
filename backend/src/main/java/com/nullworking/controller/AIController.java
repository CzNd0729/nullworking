package com.nullworking.controller;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.AIChatRequest;
import com.nullworking.model.dto.AIChatResponse;
import com.nullworking.model.dto.AIAnalysisRequest;
import com.nullworking.service.AIService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.annotation.PreDestroy;

@RestController
@RequestMapping("/api/ai")
public class AIController {

    private final AIService aiService;

    @Autowired
    public AIController(AIService aiService) {
        this.aiService = aiService;
    }

    @PostMapping("/chat")
    public ApiResponse<AIChatResponse> chatWithAI(@RequestBody AIChatRequest request) {
        try {
            String responseContent = aiService.getAIResponse(request.getText(), request.getImageUrl());
            return ApiResponse.success(new AIChatResponse(responseContent));
        } catch (Exception e) {
            e.printStackTrace();
            return ApiResponse.error(500,"AI聊天失败: " + e.getMessage());
        }
    }

    @PostMapping("/analysis")
    public ApiResponse<Integer> startAIAnalysis(@RequestBody AIAnalysisRequest request) {
        try {
            Integer resultId = aiService.startAIAnalysis(request);
            return ApiResponse.success(resultId);
        } catch (Exception e) {
            e.printStackTrace();
            return ApiResponse.error(500, "AI分析启动失败: " + e.getMessage());
        }
    }

    @PreDestroy
    public void shutdown() {
        aiService.shutdown();
    }
}
