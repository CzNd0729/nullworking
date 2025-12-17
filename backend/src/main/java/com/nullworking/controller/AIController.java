package com.nullworking.controller;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.AIChatRequest;
import com.nullworking.model.dto.AIChatResponse;
import com.nullworking.model.dto.AIAnalysisRequest;
import com.nullworking.model.dto.AIAnalysisResultSummaryDTO;
import com.nullworking.model.dto.AITaskUpdateRequest;
import com.nullworking.model.dto.AITaskCreationResponse;
import com.nullworking.service.AIService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import com.nullworking.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.parameters.RequestBody;

@RestController
@RequestMapping("/api")
public class AIController {

    private final AIService aiService;
    private final JwtUtil jwtUtil;

    @Autowired
    public AIController(AIService aiService, JwtUtil jwtUtil) {
        this.aiService = aiService;
        this.jwtUtil = jwtUtil;
    }

    @Operation(summary = "通过AI创建或更新任务", description = "根据用户提供的文本和可选的任务初始信息，通过AI生成或修改任务信息")
    @RequestBody(description = "用户输入的文本和任务信息", required = true,
                 content = @Content(mediaType = "application/json",
                                    schema = @Schema(implementation = AITaskUpdateRequest.class),
                                    examples = {
                                        @ExampleObject(name = "创建新任务",
                                                       value = "{\"text\": \"帮我创建一个明天下午三点前完成，关于编写一个用户管理模块的任务，优先级高\"}"),
                                        @ExampleObject(name = "修改现有任务",
                                                       value = "{\"text\": \"把截止日期推迟一天\", \"taskTitle\": \"编写用户管理模块\", \"deadline\": \"2025-12-17T15:00:00\"}")
                                    }))
    @PostMapping("/ai/task")
    public ApiResponse<AITaskCreationResponse> createTaskWithAI(@org.springframework.web.bind.annotation.RequestBody AITaskUpdateRequest request, HttpServletRequest httpRequest) {
        Integer currentUserId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (currentUserId == null) {
            return ApiResponse.error(401, "未授权");
        }
        String userText = request.getText();
        if (userText == null || userText.isEmpty()) {
            return ApiResponse.error(400, "用户输入文本不能为空。");
        }
        try {
            AITaskCreationResponse response = aiService.createOrUpdateTaskWithAI(request);
            return ApiResponse.success(response);
        } catch (Exception e) {
            e.printStackTrace();
            return ApiResponse.error(500, "AI任务创建失败: " + e.getMessage());
        }
    }

    @Deprecated
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
    public ApiResponse<Integer> startAIAnalysis(@RequestBody AIAnalysisRequest request, @RequestParam Integer mode, HttpServletRequest httpRequest) {
        Integer currentUserId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
        if (currentUserId == null) {
            return ApiResponse.error(401, "未授权");
        }
        // try-catch 块不再需要，因为服务层已经返回ApiResponse
        return aiService.startAIAnalysis(request, mode, currentUserId);
    }

    @GetMapping("/analysis/{resultId}")
    public ApiResponse<Map<String, Object>> getAIAnalysisResult(@PathVariable Integer resultId, HttpServletRequest httpRequest) {
        try {
            Integer currentUserId = JwtUtil.extractUserIdFromRequest(httpRequest, jwtUtil);
            if (currentUserId == null) {
                return ApiResponse.error(401, "未授权");
            }
            Map<String, Object> result = aiService.getAIAnalysisResult(resultId, currentUserId);
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
