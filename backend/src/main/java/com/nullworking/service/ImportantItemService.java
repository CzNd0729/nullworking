package com.nullworking.service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.ImportantItem;
import com.nullworking.model.User;
import com.nullworking.model.dto.ItemCreateRequest;
import com.nullworking.model.dto.ItemOrderAdjustRequest;
import com.nullworking.model.dto.ItemUpdateRequest;
import com.nullworking.repository.ImportantItemRepository;
import com.nullworking.repository.UserRepository;

@Service
public class ImportantItemService {

    @Autowired
    private ImportantItemRepository importantItemRepository;

    @Autowired
    private UserRepository userRepository;

    public ApiResponse<String> addItem(Integer userId, ItemCreateRequest request) {
        try {
            // 验证用户是否存在
            User user = userRepository.findById(userId)
                    .orElse(null);
            if (user == null) {
                return ApiResponse.error(404, "用户不存在");
            }

            // 验证显示顺序
            if (request.getDisplayOrder() == null || request.getDisplayOrder() < 1 || request.getDisplayOrder() > 10) {
                return ApiResponse.error(400, "显示顺序必须在1-10之间");
            }

            // 验证该用户是否已有相同的显示顺序
            if (importantItemRepository.findByUserAndDisplayOrder(user, request.getDisplayOrder().byteValue()).isPresent()) {
                return ApiResponse.error(400, "该显示顺序已被使用，请选择其他顺序");
            }

            // 创建重要事项
            ImportantItem item = new ImportantItem();
            item.setUser(user);
            item.setItemTitle(request.getTitle());
            item.setItemContent(request.getContent());
            item.setDisplayOrder(request.getDisplayOrder().byteValue());
            item.setCreationTime(LocalDateTime.now());
            item.setUpdateTime(LocalDateTime.now());

            importantItemRepository.save(item);

            return ApiResponse.success("重要事项添加成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "添加失败: " + e.getMessage());
        }
    }

    @Transactional
    public ApiResponse<String> adjustItemOrder(Integer userId, ItemOrderAdjustRequest request) {
        try {
            // 验证用户是否存在
            User user = userRepository.findById(userId)
                    .orElse(null);
            if (user == null) {
                return ApiResponse.error(404, "用户不存在");
            }

            List<Integer> itemIds = request.getDisplayOrders();
            
            // 验证参数
            if (itemIds == null || itemIds.isEmpty()) {
                return ApiResponse.error(400, "显示顺序列表不能为空");
            }

            // 验证数量限制（最多10个）
            if (itemIds.size() > 10) {
                return ApiResponse.error(400, "事项数量不能超过10个");
            }

            // 验证ID不重复
            long distinctCount = itemIds.stream().distinct().count();
            if (distinctCount != itemIds.size()) {
                return ApiResponse.error(400, "事项ID存在重复");
            }

            // 验证所有事项都属于该用户且存在
            List<ImportantItem> items = importantItemRepository.findAllById(itemIds);
            if (items.size() != itemIds.size()) {
                return ApiResponse.error(400, "部分事项ID不存在");
            }

            // 验证所有事项都属于该用户
            for (ImportantItem item : items) {
                if (!item.getUser().getUserId().equals(userId)) {
                    return ApiResponse.error(403, "无权操作其他用户的事项");
                }
            }

            // 创建ItemId到Item的映射
            Map<Integer, ImportantItem> itemMap = new HashMap<>();
            for (ImportantItem item : items) {
                itemMap.put(item.getItemId(), item);
            }

            // 将所有事项的display_order设置为临时值（避免唯一索引冲突）
            for (int i = 0; i < itemIds.size(); i++) {
                ImportantItem item = itemMap.get(itemIds.get(i));
                item.setDisplayOrder((byte) (200 + i)); // 使用200+作为临时值
                item.setUpdateTime(LocalDateTime.now());
            }
            importantItemRepository.saveAll(items);

            // 按照请求中的顺序设置新的display_order（1到items.size()）
            for (int i = 0; i < itemIds.size(); i++) {
                ImportantItem item = itemMap.get(itemIds.get(i));
                item.setDisplayOrder((byte) (i + 1)); // 根据请求的顺序设置display_order
                item.setUpdateTime(LocalDateTime.now());
            }
            importantItemRepository.saveAll(items);

            return ApiResponse.success("显示顺序调整成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "调整失败: " + e.getMessage());
        }
    }

    public ApiResponse<String> updateItem(Integer userId, Integer itemId, ItemUpdateRequest request) {
        try {
            // 验证用户是否存在
            User user = userRepository.findById(userId)
                    .orElse(null);
            if (user == null) {
                return ApiResponse.error(404, "用户不存在");
            }

            // 验证事项是否存在
            ImportantItem item = importantItemRepository.findById(itemId)
                    .orElse(null);
            if (item == null) {
                return ApiResponse.error(404, "事项不存在");
            }

            // 验证用户是否有权限修改该事项
            if (!item.getUser().getUserId().equals(userId)) {
                return ApiResponse.error(403, "无权修改其他用户的事项");
            }

            // 验证显示顺序
            if (request.getDisplayOrder() != null) {
                if (request.getDisplayOrder() < 1 || request.getDisplayOrder() > 10) {
                    return ApiResponse.error(400, "显示顺序必须在1-10之间");
                }

                // 验证该用户是否已有相同的显示顺序（排除当前事项）
                Byte displayOrder = request.getDisplayOrder().byteValue();
                if (importantItemRepository.findByUserAndDisplayOrder(user, displayOrder)
                        .filter(existingItem -> !existingItem.getItemId().equals(itemId))
                        .isPresent()) {
                    return ApiResponse.error(400, "该显示顺序已被使用，请选择其他顺序");
                }
            }

            // 更新事项信息
            if (request.getTitle() != null) {
                item.setItemTitle(request.getTitle());
            }
            if (request.getContent() != null) {
                item.setItemContent(request.getContent());
            }
            if (request.getDisplayOrder() != null) {
                item.setDisplayOrder(request.getDisplayOrder().byteValue());
            }
            item.setUpdateTime(LocalDateTime.now());

            importantItemRepository.save(item);

            return ApiResponse.success("重要事项更新成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "更新失败: " + e.getMessage());
        }
    }

    public ApiResponse<Map<String, Object>> getItems(Integer userId) {
        try {
            // 查询该用户的所有重要事项，按显示顺序排序
            // 对于userId=0（公司事项），直接查询，不验证用户是否存在
            List<ImportantItem> items = importantItemRepository.findByUser_UserIdOrderByDisplayOrder(userId);

            // 转换为响应Map
            List<Map<String, Object>> itemList = items.stream()
                    .map(item -> {
                        Map<String, Object> itemMap = new HashMap<>();
                        itemMap.put("itemId", item.getItemId());
                        itemMap.put("displayOrder", item.getDisplayOrder());
                        itemMap.put("title", item.getItemTitle());
                        itemMap.put("content", item.getItemContent());
                        return itemMap;
                    })
                    .collect(Collectors.toList());

            // 构建响应数据
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("items", itemList);

            return ApiResponse.success(responseData);
        } catch (Exception e) {
            return ApiResponse.error(500, "查询失败: " + e.getMessage());
        }
    }

    @Transactional
    public ApiResponse<String> deleteItem(Integer userId, Integer itemId) {
        try {
            // 验证用户是否存在
            User user = userRepository.findById(userId)
                    .orElse(null);
            if (user == null) {
                return ApiResponse.error(404, "用户不存在");
            }

            // 验证事项是否存在
            ImportantItem item = importantItemRepository.findById(itemId)
                    .orElse(null);
            if (item == null) {
                return ApiResponse.error(404, "事项不存在");
            }

            // 验证用户是否有权限删除该事项
            if (!item.getUser().getUserId().equals(userId)) {
                return ApiResponse.error(403, "无权删除其他用户的事项");
            }

            // 删除事项
            importantItemRepository.delete(item);

            return ApiResponse.success("重要事项删除成功");
        } catch (Exception e) {
            return ApiResponse.error(500, "删除失败: " + e.getMessage());
        }
    }
    
}