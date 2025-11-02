package com.nullworking.controller;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.AIChatRequest;
import com.nullworking.model.dto.AIChatResponse;
import com.nullworking.model.dto.AIAnalysisRequest;
import com.nullworking.model.dto.AIAnalysisResultSummaryDTO;
import com.nullworking.service.AIService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.annotation.PreDestroy;
import java.util.List;
import com.nullworking.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;

@RestController
@RequestMapping("/api/ai")
public class AIController {

    private final AIService aiService;
    private final JwtUtil jwtUtil;

    @Autowired
    public AIController(AIService aiService, JwtUtil jwtUtil) {
        this.aiService = aiService;
        this.jwtUtil = jwtUtil;
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
    public ApiResponse<Integer> startAIAnalysis(@RequestBody AIAnalysisRequest request, @RequestParam Integer mode) {
        try {
            Integer resultId = aiService.startAIAnalysis(request, mode);
            return ApiResponse.success(resultId);
        } catch (Exception e) {
            e.printStackTrace();
            return ApiResponse.error(500, "AI分析启动失败: " + e.getMessage());
        }
    }

    @GetMapping("/analysis/{resultId}")
    public ApiResponse<Map<String, Object>> getAIAnalysisResult(@PathVariable Integer resultId) {
        try {
            Map<String, Object> result = aiService.getAIAnalysisResult(resultId);
            return ApiResponse.success(result);
        } catch (Exception e) {
            e.printStackTrace();
            return ApiResponse.error(500, "获取AI分析结果详情失败: " + e.getMessage());
        }
    }

    @GetMapping("/analysis")
    public ApiResponse<List<AIAnalysisResultSummaryDTO>> listAIAnalysisResults(HttpServletRequest httpRequest) {
        try {
            Integer currentUserId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
            if (currentUserId == null) {
                return ApiResponse.error(401, "未授权");
            }
            List<AIAnalysisResultSummaryDTO> results = aiService.listAIAnalysisResults(currentUserId);
            return ApiResponse.success(results);
        } catch (Exception e) {
            e.printStackTrace();
            return ApiResponse.error(500, "获取AI分析结果列表失败: " + e.getMessage());
        }
    }
}
