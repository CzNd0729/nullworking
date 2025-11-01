package com.nullworking.service;

import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionRequest;
import com.volcengine.ark.runtime.model.completion.chat.ChatMessage;
import com.volcengine.ark.runtime.model.completion.chat.ChatMessageRole;
import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionContentPart;
import com.volcengine.ark.runtime.service.ArkService;
import okhttp3.ConnectionPool;
import okhttp3.Dispatcher;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
public class AIService {

    private final ArkService arkService;

    public AIService(@Value("${ark.api.key}") String apiKey, @Value("${ark.base.url}") String baseUrl) {
        ConnectionPool connectionPool = new ConnectionPool(5, 1, TimeUnit.SECONDS);
        Dispatcher dispatcher = new Dispatcher();
        this.arkService = ArkService.builder().dispatcher(dispatcher).connectionPool(connectionPool).baseUrl(baseUrl).apiKey(apiKey).build();
    }

    public String getAIResponse(String text, String imageUrl) {
        final List<ChatMessage> messages = new ArrayList<>();
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

    public void shutdown() {
        if (arkService != null) {
            arkService.shutdownExecutor();
        }
    }
}
