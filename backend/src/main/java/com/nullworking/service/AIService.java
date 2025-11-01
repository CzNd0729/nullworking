package com.nullworking.service;

import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionRequest;
import com.volcengine.ark.runtime.model.completion.chat.ChatMessage;
import com.volcengine.ark.runtime.model.completion.chat.ChatMessageRole;
import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionContentPart;
import com.volcengine.ark.runtime.service.ArkService;
import com.nullworking.model.AIAnalysisResult;
import com.nullworking.model.User;
import com.nullworking.model.dto.AIAnalysisRequest;
import com.nullworking.repository.AIAnalysisResultRepository;
import com.nullworking.repository.UserRepository;
import com.nullworking.repository.LogRepository;
import com.nullworking.repository.TaskRepository;
import okhttp3.ConnectionPool;
import okhttp3.Dispatcher;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.beans.factory.annotation.Autowired;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;
import com.nullworking.model.Log;

@Service
public class AIService {

    private final ArkService arkService;
    private final AIAnalysisResultRepository aiAnalysisResultRepository;
    private final UserRepository userRepository;
    private final LogRepository logRepository;
    private final TaskRepository taskRepository;
    private final String systemPrompt;

    @Autowired
    public AIService(
            @Value("${ark.api.key}") String apiKey,
            @Value("${ark.base.url}") String baseUrl,
            AIAnalysisResultRepository aiAnalysisResultRepository,
            UserRepository userRepository,
            LogRepository logRepository,
            TaskRepository taskRepository,
            @Value("${ark.system.prompt}") String systemPrompt) {
        ConnectionPool connectionPool = new ConnectionPool(5, 1, TimeUnit.SECONDS);
        Dispatcher dispatcher = new Dispatcher();
        this.arkService = ArkService.builder().dispatcher(dispatcher).connectionPool(connectionPool).baseUrl(baseUrl).apiKey(apiKey).build();
        this.aiAnalysisResultRepository = aiAnalysisResultRepository;
        this.userRepository = userRepository;
        this.logRepository = logRepository;
        this.taskRepository = taskRepository;
        this.systemPrompt = systemPrompt;
    }

    public String getAIResponse(String text, String imageUrl) {
        final List<ChatMessage> messages = new ArrayList<>();
        // 添加系统级提示词
        messages.add(ChatMessage.builder().role(ChatMessageRole.SYSTEM).content(systemPrompt).build());

        final List<ChatCompletionContentPart> multiParts = new ArrayList<>();

        if (imageUrl != null && !imageUrl.isEmpty()) {
            multiParts.add(ChatCompletionContentPart.builder().type("image_url").imageUrl(
                    new ChatCompletionContentPart.ChatCompletionContentPartImageURL(imageUrl)
            ).build());
        }
        multiParts.add(ChatCompletionContentPart.builder().type("text").text(
                text
        ).build());

        final ChatMessage userMessage = ChatMessage.builder().role(ChatMessageRole.USER)
                .multiContent(multiParts).build();
        messages.add(userMessage);

        ChatCompletionRequest chatCompletionRequest = ChatCompletionRequest.builder()
                .model("doubao-seed-1-6-251015") // 指定您创建的方舟推理接入点 ID
                .messages(messages)
                .reasoningEffort("medium")
                .build();

        StringBuilder response = new StringBuilder();
        arkService.createChatCompletion(chatCompletionRequest).getChoices().forEach(choice -> response.append(choice.getMessage().getContent()));
        return response.toString();
    }

    public Integer startAIAnalysis(AIAnalysisRequest request) {
        AIAnalysisResult analysisResult = new AIAnalysisResult();
        
        // 从SecurityContextHolder中获取当前用户的ID
        String username = ((UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal()).getUsername();
        User currentUser = userRepository.findByUserName(username);
        analysisResult.setUser(currentUser);
        analysisResult.setAnalysisDate(LocalDate.now());
        analysisResult.setPrompt(request.getPrompt()); // 设置prompt字段
        analysisResult.setContent("Pending"); // 初始状态
        aiAnalysisResultRepository.save(analysisResult);

        // 异步执行AI分析
        performAIAnalysis(analysisResult.getResultId(), request);

        return analysisResult.getResultId();
    }

    @Async
    public void performAIAnalysis(Integer resultId, AIAnalysisRequest request) {
        AIAnalysisResult analysisResult = aiAnalysisResultRepository.findById(resultId)
                .orElseThrow(() -> new RuntimeException("Analysis result not found for ID: " + resultId));

        try {
            // 1. 根据request参数（userIds, startDate, endDate, taskId）构建完整的AI请求
            // 获取用户列表
            List<User> users = new ArrayList<>();
            if (request.getUserIds() != null && !request.getUserIds().isEmpty()) {
                users = userRepository.findByUserIdIn(request.getUserIds());
            }

            // 获取日志信息
            List<Log> logs = new ArrayList<>();
            if (request.getUserIds() != null && !request.getUserIds().isEmpty() &&
                    request.getStartDate() != null && !request.getStartDate().isEmpty() &&
                    request.getEndDate() != null && !request.getEndDate().isEmpty()) {
                LocalDate startDate = LocalDate.parse(request.getStartDate(), DateTimeFormatter.ISO_LOCAL_DATE);
                LocalDate endDate = LocalDate.parse(request.getEndDate(), DateTimeFormatter.ISO_LOCAL_DATE);
                logs = logRepository.findByUserUserIdInAndLogDateBetween(request.getUserIds(), startDate, endDate);
            }
            
            // 格式化数据为JSON
            ObjectMapper objectMapper = new ObjectMapper();
            objectMapper.findAndRegisterModules(); // 注册Java 8 Date/Time模块

            // 构建users JSON
            List<Map<String, Object>> userList = users.stream().map(user -> {
                Map<String, Object> userMap = new HashMap<>();
                userMap.put("userId", user.getUserId());
                userMap.put("userName", user.getUserName());
                return userMap;
            }).collect(Collectors.toList());

            // 构建logs JSON
            List<Map<String, Object>> logList = logs.stream().map(log -> {
                Map<String, Object> logMap = new HashMap<>();
                logMap.put("logId", log.getLogId());
                logMap.put("taskId", log.getTask().getTaskId());
                logMap.put("userId", log.getUser().getUserId());
                logMap.put("logTitle", log.getLogTitle());
                logMap.put("logContent", log.getLogContent());
                logMap.put("logStatus", log.getLogStatus());
                logMap.put("taskProgress", log.getTaskProgress());
                logMap.put("startTime", log.getStartTime().format(DateTimeFormatter.ISO_LOCAL_TIME));
                logMap.put("endTime", log.getEndTime().format(DateTimeFormatter.ISO_LOCAL_TIME));
                logMap.put("logDate", log.getLogDate().format(DateTimeFormatter.ISO_LOCAL_DATE));
                return logMap;
            }).collect(Collectors.toList());

            Map<String, Object> data = new HashMap<>();
            data.put("users", userList);
            data.put("logs", logList);

            String jsonData = objectMapper.writeValueAsString(data);
            String fullPrompt = request.getPrompt() + "\n\n以下是相关数据：\n" + jsonData;

            // 模拟AI分析结果
            String aiResponse = getAIResponse(fullPrompt, null); // 这里可以根据实际情况传入imageUrl

            // 解析AI响应并更新analysisResult
            // 假设aiResponse包含一个JSON字符串
            analysisResult.setContent(aiResponse);

        } catch (Exception e) {
            analysisResult.setContent("Error: " + e.getMessage());
            e.printStackTrace();
        } finally {
            aiAnalysisResultRepository.save(analysisResult);
        }
    }

    public void shutdown() {
        if (arkService != null) {
            arkService.shutdownExecutor();
        }
    }
}
