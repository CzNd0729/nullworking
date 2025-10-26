package com.nullworking.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.dto.ItemCreateRequest;
import com.nullworking.model.dto.ItemOrderAdjustRequest;
import com.nullworking.service.ImportantItemService;
import com.nullworking.util.JwtUtil;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/items")
public class ImportantItemController {

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private ImportantItemService importantItemService;

    @Operation(summary = "添加重要事项", description = "从token获取用户ID，创建重要事项，返回code：200成功，400参数错误，401未授权，404用户不存在，500失败")
    @PostMapping("/company")
    public ApiResponse<String> addItem(
            HttpServletRequest request,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "重要事项信息",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = ItemCreateRequest.class))) @RequestBody ItemCreateRequest itemCreateRequest) {
        
        Integer userId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }
        
        return importantItemService.addItem(userId, itemCreateRequest);
    }

    @Operation(summary = "调整重要事项显示顺序", description = "传入ItemId顺序更新display_order顺序，返回code：200成功，400参数错误，401未授权，403无权限，404用户不存在，500失败")
    @PatchMapping("/company")
    public ApiResponse<String> adjustItemOrder(
            HttpServletRequest request,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(description = "调整显示顺序请求",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = ItemOrderAdjustRequest.class))) @RequestBody ItemOrderAdjustRequest itemOrderAdjustRequest) {
        
        Integer userId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
        if (userId == null) {
            return ApiResponse.error(401, "未授权或Token无效");
        }
        
        return importantItemService.adjustItemOrder(userId, itemOrderAdjustRequest);
    }

    @Operation(summary = "获取重要事项列表", description = "根据isCompany参数返回个人或公司十大事项，isCompany=1返回公司十大事项(UserID=0)，isCompany=0返回个人十大事项(通过token获取用户ID)，返回code：200成功，400参数错误，401未授权，404用户不存在，500失败")
    @GetMapping("")
    public ApiResponse<Map<String, Object>> getItems(
            HttpServletRequest request,
            @RequestParam(value = "isCompany", required = true) Integer isCompany) {
        
        // 验证参数
        if (isCompany == null || (isCompany != 0 && isCompany != 1)) {
            return ApiResponse.error(400, "isCompany参数错误，只能为0或1");
        }
        
        if (isCompany == 1) {
            // 公司十大事项 - 使用UserID=0
            return importantItemService.getItems(0);
        } else {
            // 个人十大事项 - 从token获取用户ID
            Integer userId = JwtUtil.extractUserIdFromRequest(request, jwtUtil);
            if (userId == null) {
                return ApiResponse.error(401, "未授权或Token无效");
            }
            return importantItemService.getItems(userId);
        }
    }
}
