package com.nullworking.controller;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.AIAnalysisResult;
import com.nullworking.model.dto.GenerateShortUrlRequest;
import com.nullworking.model.dto.ShortUrlResponse;
import com.nullworking.service.ShortUrlService;
import com.nullworking.util.JwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.NoSuchElementException;
import jakarta.validation.constraints.NotNull;

/**
 * AI 分析结果短链接分享控制器
 */
@RestController
@RequestMapping("/api/share")
public class ShareController {

    @Autowired
    private ShortUrlService shortUrlService;

    @Autowired
    private JwtUtil jwtUtil;

    /**
     * 生成短链接（需要登录）
     */
    @Operation(summary = "生成AI分析结果短链接", description = "仅分析结果创建者可以生成分享短链接")
    @PostMapping("/generate")
    public ApiResponse<ShortUrlResponse> generateShortUrl(
            @Valid @RequestBody GenerateShortUrlRequest request,
            HttpServletRequest httpServletRequest) {

        Integer currentUserId = JwtUtil.extractUserIdFromRequest(httpServletRequest, jwtUtil);
        if (currentUserId == null) {
            return ApiResponse.error(401, "未授权，请先登录");
        }

        try {
            ShortUrlResponse response = shortUrlService.generateShortUrl(request.getResultId(), currentUserId);
            return ApiResponse.success(response);
        } catch (SecurityException e) {
            return ApiResponse.error(403, e.getMessage());
        } catch (IllegalArgumentException e) {
            return ApiResponse.error(400, e.getMessage());
        } catch (Exception e) {
            return ApiResponse.error(500, "生成短链接失败: " + e.getMessage());
        }
    }

    /**
     * 网页版展示 AI 分析结果（用于 H5 打开短链接）
     */
    @Operation(summary = "根据shortCode查询AI分析结果", description = "返回该分析结果")
    @GetMapping("/web/{shortCode}")
    public Map<String, Object> showWebResult(@PathVariable String shortCode) {
        Map<String, Object> response = new HashMap<>();
        try {
            AIAnalysisResult result = shortUrlService.parseShortCode(shortCode);
            response.put("status", "success");
            response.put("content", result.getContent());
            response.put("analysisTime", result.getAnalysisTime());
        } catch (Exception e) {
            response.put("status", "error");
            response.put("errorMsg", e.getMessage());
        }
        return response;
    }

    /**
    * 根据分析结果ID查询短链接（公开接口）
    */
    @Operation(summary = "根据resultId查询短链接", description = "返回该分析结果对应的有效短链接")
    @GetMapping("/getShortUrlByResultId/{resultId}")
    public ApiResponse<String> getShortUrlByResultId(
            @PathVariable @NotNull(message = "分析结果ID不能为空") Integer resultId) {

        try {
            String shortUrl = shortUrlService.getPublicShortUrlByResultId(resultId);
            return ApiResponse.success(shortUrl);
        } catch (IllegalArgumentException e) {
            return ApiResponse.error(400, e.getMessage());
        } catch (NoSuchElementException e) {
            return ApiResponse.error(404, "该分析结果暂无有效短链接");
        } catch (Exception e) {
            return ApiResponse.error(500, "查询短链接失败: " + e.getMessage());
        }
    }
}