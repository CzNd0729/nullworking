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
import java.time.format.DateTimeFormatter;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.Map;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.stream.Collectors;
import com.nullworking.model.Log;
import com.nullworking.model.Task;
import com.nullworking.model.dto.AIAnalysisResultSummaryDTO;
import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.AITaskUpdateRequest;
import com.nullworking.model.dto.AITaskCreationResponse;
import java.util.Objects; // 导入 Objects 类

@Service
public class AIService {

    private final ArkService arkService;
    private final AIAnalysisResultRepository aiAnalysisResultRepository;
    private final UserRepository userRepository;
    private final LogRepository logRepository;
    private final TaskRepository taskRepository;
    private final String systemPrompt;
    private final String model;
    private final ObjectMapper objectMapper;
    private final PermissionService permissionService;
    // private final UserService userService;
    // private final LogFileService logFileService;
    // private final LogFileRepository logFileRepository;
    private final String taskCreationSystemPromptTemplate; // 新增属性，用于存储从配置读取的提示词模板

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
            @Value("${volcengine.ark.model}") String model,
            ObjectMapper objectMapper,
            PermissionService permissionService,
            UserService userService,
            LogFileService logFileService,
            LogFileRepository logFileRepository,
            @Value("${ark.task-creation.system.prompt}") String taskCreationSystemPromptTemplate) { // 注入新的属性
        ConnectionPool connectionPool = new ConnectionPool(5, 1, TimeUnit.SECONDS);
        Dispatcher dispatcher = new Dispatcher();
        this.arkService = ArkService.builder().dispatcher(dispatcher).connectionPool(connectionPool).baseUrl(baseUrl).apiKey(apiKey).build();
        this.aiAnalysisResultRepository = aiAnalysisResultRepository;
        this.userRepository = userRepository;
        this.logRepository = logRepository;
        this.taskRepository = taskRepository;
        this.systemPrompt = systemPrompt;
        this.model = model;
        this.objectMapper = objectMapper;

        // 配置ObjectMapper以正确处理LocalDateTime
        // JavaTimeModule javaTimeModule = new JavaTimeModule();
        // javaTimeModule.addDeserializer(LocalDateTime.class, new LocalDateTimeDeserializer(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        // this.objectMapper.registerModule(javaTimeModule);
        this.objectMapper.findAndRegisterModules(); // 注册Java 8 Date/Time模块 (如果已经注册了JavaTimeModule，这个可能不是必需的)

        this.objectMapper.setSerializationInclusion(JsonInclude.Include.NON_NULL); // 忽略null字段
        this.permissionService = permissionService;
        this.taskCreationSystemPromptTemplate = taskCreationSystemPromptTemplate; // 赋值
        // this.userService = userService;
        // this.logFileService = logFileService;
        // this.logFileRepository = logFileRepository;
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
                .model(model) // 指定您创建的方舟推理接入点 ID
                .messages(messages)
                .reasoningEffort("medium")
                .build();

        StringBuilder response = new StringBuilder();
        arkService.createChatCompletion(chatCompletionRequest).getChoices().forEach(choice -> response.append(choice.getMessage().getContent()));
        return response.toString();
    }

    public AITaskCreationResponse createOrUpdateTaskWithAI(AITaskUpdateRequest request) {
        String userText = request.getText();
        Map<String, Object> existingTaskInfo = new HashMap<>();
        if (request.getTaskTitle() != null) existingTaskInfo.put("taskTitle", request.getTaskTitle());
        if (request.getTaskContent() != null) existingTaskInfo.put("taskContent", request.getTaskContent());
        if (request.getPriority() != null) existingTaskInfo.put("priority", request.getPriority());
        if (request.getExecutorIds() != null) existingTaskInfo.put("executorIds", request.getExecutorIds());
        if (request.getDeadline() != null) existingTaskInfo.put("deadline", request.getDeadline().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));

        String fullUserPrompt = userText;
        if (!existingTaskInfo.isEmpty()) {
            try {
                String existingTaskJson = objectMapper.writeValueAsString(existingTaskInfo);
                fullUserPrompt += "\n\n请基于以下任务信息进行修改：\n" + existingTaskJson;
            } catch (JsonProcessingException e) {
                // 处理序列化异常，或者选择不附加额外信息
                e.printStackTrace();
            }
        }
        
        return createTaskFromAI(fullUserPrompt);
    }

    public AITaskCreationResponse createTaskFromAI(String userText) {
        final List<ChatMessage> messages = new ArrayList<>();
        // 添加系统级提示词，要求AI返回JSON格式的任务信息
        // String taskCreationSystemPrompt = "你是一个任务创建助手，请根据用户提供的文本，生成一个任务。任务信息应包含：任务标题 (taskTitle)，任务内容 (taskContent)，截止时间 (deadline，格式为yyyy-MM-dd HH:mm:ss，如果未指定则为当天23:59:59)，以及优先级 (priority，可选值：High, Medium, Low，默认为Medium)。请以JSON格式返回结果，例如：{\"taskTitle\": \"示例任务标题\", \"taskContent\": \"示例任务内容\", \"deadline\": \"2025-12-31 23:59:59\", \"priority\": \"High\"}";
        
        // 获取当前系统时间并格式化
        String currentDateTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        // 结合配置的模板和当前时间构建最终提示词
        String finalTaskCreationSystemPrompt = taskCreationSystemPromptTemplate + "\n当前系统时间是：" + currentDateTime;
        
        messages.add(ChatMessage.builder().role(ChatMessageRole.SYSTEM).content(finalTaskCreationSystemPrompt).build());

        final List<ChatCompletionContentPart> multiParts = new ArrayList<>();
        multiParts.add(ChatCompletionContentPart.builder().type("text").text(userText).build());

        final ChatMessage userMessage = ChatMessage.builder().role(ChatMessageRole.USER)
                .multiContent(multiParts).build();
        messages.add(userMessage);

        ChatCompletionRequest chatCompletionRequest = ChatCompletionRequest.builder()
                .model("doubao-1-5-lite-32k-250115") // 指定您创建的方舟推理接入点 ID
                .messages(messages)
                .reasoningEffort("medium")
                .build();

        StringBuilder response = new StringBuilder();
        arkService.createChatCompletion(chatCompletionRequest).getChoices().forEach(choice -> response.append(choice.getMessage().getContent()));
        
        try {
            // 尝试解析AI的响应为AITaskCreationResponse对象
            System.out.println(response.toString());
            return objectMapper.readValue(response.toString(), AITaskCreationResponse.class);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
            throw new RuntimeException("Failed to parse AI response for task creation.", e);
        }
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
        analysisResult.setMode(Objects.requireNonNullElse(mode, 0));
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
                    userMap.put("userId", Objects.requireNonNullElse(user.getUserId(), 0));
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
                Task task = taskRepository.findById(request.getTaskId()).orElse(null);
                if (task == null) {
                    analysisResult.setContent("任务不存在，无法进行分析。");
                    analysisResult.setStatus(3); // 3: 分析失败
                    aiAnalysisResultRepository.save(analysisResult);
                    return;
                }

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
                    userMap.put("userId", Objects.requireNonNullElse(user.getUserId(), 0));
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

            // 乱码校验
            boolean isValid = com.nullworking.util.ContentValidationUtil.isValidAnalysisContent(aiResponse);
            if (!isValid) {
                analysisResult.setContent(aiResponse);
                analysisResult.setStatus(2); // 2: 乱码失败
            } else {
                analysisResult.setContent(aiResponse);
                analysisResult.setStatus(1); // 1: 分析完成
            }

        } catch (Exception e) {
            analysisResult.setContent("Error: " + e.getMessage());
            analysisResult.setStatus(3); // 3: 分析失败
            e.printStackTrace();
        } finally {
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
        // 乱码校验：状态为2时禁止查看
        if (analysisResult.getStatus() != null && analysisResult.getStatus() == 2) {
            throw new RuntimeException("AI分析结果疑似乱码，无法查看。");
        }
        String content = analysisResult.getContent();
        if (content == null) {
            throw new RuntimeException("AI分析结果内容为空，ID: " + resultId);
        }
        try {
            // ========== 核心修改：使用LinkedHashMap保证插入顺序 ==========
            // 步骤1：初始化有序Map（LinkedHashMap），保证字段顺序
            Map<String, Object> resultMap = new LinkedHashMap<>();
            
            // 步骤2：解析prompt并按顺序放入（prompt字段整体在前）
            String promptJson = analysisResult.getPrompt();
            if (promptJson != null && !promptJson.isEmpty()) {
                try {
                    // 解析prompt为有序Map，保留其原有字段顺序
                    Map<String, Object> promptMap = objectMapper.readValue(
                            promptJson, 
                            new TypeReference<LinkedHashMap<String, Object>>() {} // 关键：解析为LinkedHashMap
                    );
                    // 按prompt原有顺序，将所有字段放入结果Map（先放）
                    resultMap.putAll(promptMap);
                } catch (Exception e) {
                    throw new RuntimeException("AI分析结果prompt JSON解析失败，ID: " + resultId, e);
                }
            }
            
            // 步骤3：解析content并按顺序放入（content字段整体在后）
            // 解析content为有序Map，保留其原有字段顺序
            Map<String, Object> contentMap = objectMapper.readValue(
                    content, 
                    new TypeReference<LinkedHashMap<String, Object>>() {} // 关键：解析为LinkedHashMap
            );
            // 按content原有顺序，将所有字段放入结果Map（后放）
            resultMap.putAll(contentMap);

            return resultMap;
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
                    return new AIAnalysisResultSummaryDTO(Objects.requireNonNullElse(result.getResultId(), 0), result.getAnalysisTime(), promptMap, Objects.requireNonNullElse(result.getStatus(), 0), Objects.requireNonNullElse(result.getMode(), 0));
                })
                .collect(Collectors.toList());
    }
}
