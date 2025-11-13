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
import com.nullworking.service.PermissionService;
import com.nullworking.service.UserService;
import com.nullworking.service.LogFileService;
import com.nullworking.repository.LogFileRepository;
import okhttp3.ConnectionPool;
import okhttp3.Dispatcher;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;
import com.nullworking.model.Log;
import com.nullworking.model.Task;
import com.nullworking.model.dto.AIAnalysisResultSummaryDTO;
import com.nullworking.common.ApiResponse;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class AIService {

    private final ArkService arkService;
    private final AIAnalysisResultRepository aiAnalysisResultRepository;
    private final UserRepository userRepository;
    private final LogRepository logRepository;
    private final TaskRepository taskRepository;
    private final String systemPrompt;
    private final ObjectMapper objectMapper;
    private final PermissionService permissionService;
    private final UserService userService;
    private final LogFileService logFileService;
    private final LogFileRepository logFileRepository;

    @Lazy
    @Autowired
    private AIService self;

    @Autowired
    public AIService(
            @Value("${ark.api.key}") String apiKey,
            @Value("${ark.base.url}") String baseUrl,
            AIAnalysisResultRepository aiAnalysisResultRepository,
            UserRepository userRepository,
            LogRepository logRepository,
            TaskRepository taskRepository,
            @Value("${ark.system.prompt}") String systemPrompt,
            ObjectMapper objectMapper,
            PermissionService permissionService,
            UserService userService,
            LogFileService logFileService,
            LogFileRepository logFileRepository) {
        ConnectionPool connectionPool = new ConnectionPool(5, 1, TimeUnit.SECONDS);
        Dispatcher dispatcher = new Dispatcher();
        this.arkService = ArkService.builder().dispatcher(dispatcher).connectionPool(connectionPool).baseUrl(baseUrl).apiKey(apiKey).build();
        this.aiAnalysisResultRepository = aiAnalysisResultRepository;
        this.userRepository = userRepository;
        this.logRepository = logRepository;
        this.taskRepository = taskRepository;
        this.systemPrompt = systemPrompt;
        this.objectMapper = objectMapper;
        this.objectMapper.findAndRegisterModules(); // 注册Java 8 Date/Time模块
        this.objectMapper.setSerializationInclusion(JsonInclude.Include.NON_NULL); // 忽略null字段
        this.permissionService = permissionService;
        this.userService = userService;
        this.logFileService = logFileService;
        this.logFileRepository = logFileRepository;
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
                .model("doubao-seed-1-6-thinking-250715") // 指定您创建的方舟推理接入点 ID
                .messages(messages)
                .reasoningEffort("medium")
                .build();

        StringBuilder response = new StringBuilder();
        arkService.createChatCompletion(chatCompletionRequest).getChoices().forEach(choice -> response.append(choice.getMessage().getContent()));
        return response.toString();
    }

    public ApiResponse<Integer> startAIAnalysis(AIAnalysisRequest request, Integer mode, Integer userId) {
        // 0. 权限检查
        if (!permissionService.hasPermission(userId, "AI_ANALYSIS")) {
            return ApiResponse.error(403, "权限不足：您没有进行AI分析的权限。");
        }

        // 1. 数据完整性检查
        if (mode == null) {
            return ApiResponse.error(400, "分析模式 (mode) 不能为空。");
        }

        if (mode == 0) { // 用户+时间模式
            if (request.getUserIds() == null || request.getUserIds().isEmpty()) {
                return ApiResponse.error(400, "在用户+时间模式下，用户ID列表 (userIds) 不能为空。");
            }
            if (request.getStartDate() == null || request.getStartDate().isEmpty()) {
                return ApiResponse.error(400, "在用户+时间模式下，开始日期 (startDate) 不能为空。");
            }
            if (request.getEndDate() == null || request.getEndDate().isEmpty()) {
                return ApiResponse.error(400, "在用户+时间模式下，结束日期 (endDate) 不能为空。");
            }
        } else if (mode == 1) { // 仅任务模式
            if (request.getTaskId() == null) {
                return ApiResponse.error(400, "在任务模式下，任务ID (taskId) 不能为空。");
            }
            // 可选：如需校验任务归属，可在此补充
        } else {
            return ApiResponse.error(400, "不支持的分析模式: " + mode + "。支持的模式为0 (用户+时间) 或1 (仅任务)。");
        }

        AIAnalysisResult analysisResult = new AIAnalysisResult();

        User currentUser = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found for ID: " + userId));
        analysisResult.setUser(currentUser);
        analysisResult.setAnalysisTime(LocalDateTime.now());
        // 设置初始状态为0（分析中）
        analysisResult.setStatus(0);
        // 设置分析模式
        analysisResult.setMode(mode);
        // 将整个request对象转换为JSON字符串并存储到prompt字段
        try {
            String requestJson = objectMapper.writeValueAsString(request);
            analysisResult.setPrompt(requestJson);
        } catch (Exception e) {
            analysisResult.setPrompt("Error converting request to JSON: " + e.getMessage());
            e.printStackTrace();
        }
        analysisResult.setContent("Pending"); // 初始状态
        aiAnalysisResultRepository.save(analysisResult);

        // 异步执行AI分析
        self.performAIAnalysis(analysisResult.getResultId(), request, mode);

        return ApiResponse.success(analysisResult.getResultId());
    }

    @Async
    public void performAIAnalysis(Integer resultId, AIAnalysisRequest request, Integer mode) {
        AIAnalysisResult analysisResult = aiAnalysisResultRepository.findById(resultId)
                .orElseThrow(() -> new RuntimeException("Analysis result not found for ID: " + resultId));

        try {
            // 1. 根据request参数（userIds, startDate, endDate, taskId）构建完整的AI请求
            String jsonData = "";
            String fullPrompt = request.getUserPrompt(); // 使用新的userPrompt字段

            if (mode == 0) { // 用户+时间模式
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

                // 构建users JSON
                List<Map<String, Object>> userList = users.stream().map(user -> {
                    Map<String, Object> userMap = new HashMap<>();
                    userMap.put("userId", user.getUserId());
                    userMap.put("userName", user.getRealName());
                    return userMap;
                }).collect(Collectors.toList());

                // 构建logs JSON
                List<Map<String, Object>> logList = logs.stream().map(log -> {
                    Map<String, Object> logMap = new HashMap<>();
                    logMap.put("logId", log.getLogId());
                    Task logTask = log.getTask();
                    if (logTask != null) {
                        logMap.put("taskId", logTask.getTaskId());
                    } else {
                        logMap.put("taskId", null);
                    }
                    User logUser = log.getUser();
                    if (logUser != null) {
                        logMap.put("userId", logUser.getUserId());
                    } else {
                        logMap.put("userId", null);
                    }
                    logMap.put("logTitle", log.getLogTitle());
                    logMap.put("logContent", log.getLogContent());
                    logMap.put("logStatus", log.getLogStatus());
                    logMap.put("taskProgress", log.getTaskProgress());
                    logMap.put("startTime", log.getStartTime().format(DateTimeFormatter.ISO_LOCAL_TIME));
                    logMap.put("endTime", log.getEndTime().format(DateTimeFormatter.ISO_LOCAL_TIME));
                    logMap.put("logDate", log.getLogDate().format(DateTimeFormatter.ISO_LOCAL_DATE));
                    return logMap;
                }).collect(Collectors.toList());

                // 从日志中提取唯一的任务
                List<Task> tasksInLogs = logs.stream()
                        .map(Log::getTask)
                        .filter(java.util.Objects::nonNull)
                        .distinct()
                        .collect(Collectors.toList());

                // 构建tasks JSON
                List<Map<String, Object>> taskList = tasksInLogs.stream().map(task -> {
                    Map<String, Object> taskMap = new HashMap<>();
                    taskMap.put("taskId", task.getTaskId());
                    taskMap.put("taskTitle", task.getTaskTitle());
                    taskMap.put("taskContent", task.getTaskContent());
                    taskMap.put("taskStatus", task.getTaskStatus());
                    taskMap.put("startTime", task.getStartTime().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                    taskMap.put("endTime", task.getEndTime().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                    taskMap.put("priority", task.getPriority());
                    return taskMap;
                }).collect(Collectors.toList());

                Map<String, Object> data = new HashMap<>();
                data.put("users", userList);
                data.put("logs", logList);
                data.put("tasks", taskList); // 添加任务列表
                jsonData = objectMapper.writeValueAsString(data);
                fullPrompt = request.getUserPrompt() + "\n\n以下是相关数据：\n" + jsonData; // 使用新的userPrompt字段
            } else if (mode == 1) { // 仅任务模式
                // 根据taskId获取任务
                Task task = taskRepository.findById(request.getTaskId())
                        .orElseThrow(() -> new RuntimeException("Task not found for ID: " + request.getTaskId()));

                // 获取与该任务关联的所有日志
                List<Log> logs = logRepository.findByTaskTaskId(request.getTaskId());

                // 从日志中提取唯一用户
                List<User> users = logs.stream()
                        .map(Log::getUser)
                        .filter(java.util.Objects::nonNull) // 过滤掉可能的null用户
                        .distinct()
                        .collect(Collectors.toList());

                // 构建task JSON
                Map<String, Object> taskMap = new HashMap<>();
                taskMap.put("taskId", task.getTaskId());
                taskMap.put("taskTitle", task.getTaskTitle());
                taskMap.put("taskContent", task.getTaskContent());
                taskMap.put("taskStatus", task.getTaskStatus());
                taskMap.put("startTime", task.getStartTime().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                taskMap.put("endTime", task.getEndTime().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                taskMap.put("priority", task.getPriority());

                // 构建users JSON
                List<Map<String, Object>> userList = users.stream().map(user -> {
                    Map<String, Object> userMap = new HashMap<>();
                    userMap.put("userId", user.getUserId());
                    userMap.put("userName", user.getRealName());
                    return userMap;
                }).collect(Collectors.toList());

                // 构建logs JSON
                List<Map<String, Object>> logList = logs.stream().map(log -> {
                    Map<String, Object> logMap = new HashMap<>();
                    logMap.put("logId", log.getLogId());
                    Task logTask = log.getTask();
                    if (logTask != null) {
                        logMap.put("taskId", logTask.getTaskId());
                    } else {
                        logMap.put("taskId", null);
                    }
                    User logUser = log.getUser();
                    if (logUser != null) {
                        logMap.put("userId", logUser.getUserId());
                    } else {
                        logMap.put("userId", null);
                    }
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
                data.put("task", taskMap);
                data.put("users", userList);
                data.put("logs", logList);
                // 在任务模式下，直接使用已获取的任务作为任务列表
                List<Map<String, Object>> taskList = new ArrayList<>();
                taskList.add(taskMap);
                data.put("tasks", taskList); // 添加任务列表
                jsonData = objectMapper.writeValueAsString(data);
                fullPrompt = request.getUserPrompt() + "\n\n以下是任务相关数据：\n" + jsonData; // 使用新的userPrompt字段
            }
            
            // 模拟AI分析结果
            String aiResponse = getAIResponse(fullPrompt, null); // 这里可以根据实际情况传入imageUrl

            // 解析AI响应并更新analysisResult
            // 假设aiResponse包含一个JSON字符串
            analysisResult.setContent(aiResponse);

        } catch (Exception e) {
            analysisResult.setContent("Error: " + e.getMessage());
            e.printStackTrace();
        } finally {
            analysisResult.setStatus(1); // 分析完成，无论成功失败都标记为完成
            aiAnalysisResultRepository.save(analysisResult);
        }
    }

    public Map<String, Object> getAIAnalysisResult(Integer resultId, Integer userId) {
        AIAnalysisResult analysisResult = aiAnalysisResultRepository.findById(resultId)
                .orElseThrow(() -> new RuntimeException("AI分析结果未找到，ID: " + resultId));
        // 权限校验：只能查看自己的分析结果
        if (!analysisResult.getUser().getUserId().equals(userId)) {
            throw new RuntimeException("权限不足：只能查看自己的分析结果。");
        }
        String content = analysisResult.getContent();
        if (content == null) {
            throw new RuntimeException("AI分析结果内容为空，ID: " + resultId);
        }
        try {
            return objectMapper.readValue(content, new TypeReference<Map<String, Object>>() {});
        } catch (JsonProcessingException e) {
            throw new RuntimeException("AI分析结果JSON解析失败，ID: " + resultId, e);
        }
    }

    public List<AIAnalysisResultSummaryDTO> listAIAnalysisResults(Integer userId) {
        // 只返回当前用户的分析结果，按分析时间降序排序
        return aiAnalysisResultRepository.findByUser_UserId(userId).stream()
                .sorted((a, b) -> b.getAnalysisTime().compareTo(a.getAnalysisTime()))
                .map(result -> {
                    Map<String, Object> promptMap = null;
                    String promptString = result.getPrompt();
                    if (promptString != null) {
                        try {
                            promptMap = objectMapper.readValue(promptString, new TypeReference<Map<String, Object>>() {});
                        } catch (JsonProcessingException e) {
                            System.err.println("Error parsing prompt JSON for resultId " + result.getResultId() + ": " + e.getMessage());
                            promptMap = new HashMap<>();
                            promptMap.put("error", "Error parsing prompt JSON");
                        }
                    } else {
                        promptMap = new HashMap<>();
                    }
                    return new AIAnalysisResultSummaryDTO(result.getResultId(), result.getAnalysisTime(), promptMap, result.getStatus(), result.getMode());
                })
                .collect(Collectors.toList());
    }
}
