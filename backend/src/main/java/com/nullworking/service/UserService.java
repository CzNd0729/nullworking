package com.nullworking.service;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Department;
import com.nullworking.model.Log;
import com.nullworking.model.Role;
import com.nullworking.model.Task;
import com.nullworking.model.User;
import com.nullworking.model.dto.UserCreateRequest;
import com.nullworking.model.dto.UserUpdateRequest;
import com.nullworking.model.dto.UserProfileUpdateRequest;
import com.nullworking.repository.DepartmentRepository;
import com.nullworking.repository.LogRepository;
import com.nullworking.repository.RoleRepository;
import com.nullworking.repository.TaskExecutorRelationRepository;
import com.nullworking.repository.TaskRepository;
import com.nullworking.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.lang.Nullable;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import java.util.Objects;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private LogRepository logRepository;

    @Autowired
    private TaskExecutorRelationRepository taskExecutorRelationRepository;

    @Autowired
    private PermissionService permissionService;

    // @Autowired
    // private JwtUtil jwtUtil;

    // 所有的业务逻辑将在这里实现

    public ApiResponse<Map<String, Object>> getSubDeptUser(Integer currentUserId) {
        if (currentUserId == null) {
            return ApiResponse.error(400, "当前用户ID不能为空");
        }
        // 1. 获取当前用户所属部门ID
        User currentUser = userRepository.findById(currentUserId).orElse(null);
        if (currentUser == null || currentUser.getDepartment() == null) {
            Map<String, Object> data = new HashMap<>();
            List<Map<String, Object>> emptyUserList = new ArrayList<>();
            data.put("users", emptyUserList);
            return ApiResponse.success(data);
        }
        Integer currentDepartmentId = currentUser.getDepartment().getDepartmentId();

        // 2. 获取所有同级及下级部门ID
        Set<Integer> departmentIdsInHierarchy = new HashSet<>();
        collectDepartmentHierarchy(currentDepartmentId, departmentIdsInHierarchy);

        // 3. 查询这些部门下的所有用户（排除当前用户自己）
        List<User> usersInHierarchy = userRepository.findByDepartmentDepartmentIdIn(departmentIdsInHierarchy)
                .stream()
                .filter(user -> !user.getUserId().equals(currentUserId)) // 排除当前用户自己
                .filter(user -> permissionService.canAssignTaskToUser(Objects.requireNonNull(currentUserId), user)) // 过滤掉无权分配任务的用户
                .collect(Collectors.toList());

        // 4. 格式化结果
        List<Map<String, Object>> users = new ArrayList<>();
        for (User user : usersInHierarchy) {
            Map<String, Object> userMap = new HashMap<>();
            userMap.put("userId", user.getUserId());
            userMap.put("realName", user.getRealName());
            users.add(userMap);
        }
        Map<String, Object> data = new HashMap<>();
        data.put("users",users);

        return ApiResponse.success(data);
    }

    /**
     * 获取所有用户列表
     * @return 包含所有用户信息的响应
     */
    public ApiResponse<Map<String, Object>> listUsers() {
        try {
            List<User> users = userRepository.findAll();
            
            List<Map<String, Object>> userList = new ArrayList<>();
            for (User user : users) {
                Map<String, Object> userMap = new HashMap<>();
                userMap.put("userId", user.getUserId());
                userMap.put("realName", user.getRealName());
                // 账号、联系方式
                userMap.put("userName", user.getUserName());
                userMap.put("phoneNumber", user.getPhoneNumber());
                userMap.put("email", user.getEmail());
                
                // 获取角色名称
                String roleName = user.getRole() != null ? user.getRole().getRoleName() : null;
                userMap.put("roleName", roleName);
                
                // 获取部门名称
                String deptName = user.getDepartment() != null ? user.getDepartment().getDepartmentName() : null;
                userMap.put("deptName", deptName);
                
                userList.add(userMap);
            }
            
            Map<String, Object> data = new HashMap<>();
            data.put("users", userList);
            
            return ApiResponse.success(data);
        } catch (Exception e) {
            return ApiResponse.error(500, "获取用户列表失败: " + e.getMessage());
        }
    }

    /**
     * 添加新用户
     * @param request 创建用户请求
     * @return 创建结果
     */
    public ApiResponse<Void> addUser(UserCreateRequest request) {
        try {
            // 角色与部门为必填
            if (request.getRoleId() == null) {
                return ApiResponse.error(400, "角色为必选项");
            }
            if (request.getDeptId() == null) {
                return ApiResponse.error(400, "部门为必选项");
            }
            // 检查用户名是否已存在
            if (userRepository.findByUserName(request.getUserName()) != null) {
                return ApiResponse.error(409, "用户名已存在");
            }
            
            // 校验必填字段
            if (request.getRealName() == null || request.getRealName().trim().isEmpty()) {
                return ApiResponse.error(400, "真实姓名为必填项");
            }
            
            if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
                return ApiResponse.error(400, "密码为必填项");
            }
            
            if (request.getPhone() == null || request.getPhone().trim().isEmpty()) {
                return ApiResponse.error(400, "电话号码为必填项");
            }
            
            // 验证角色是否存在
            Optional<Role> roleOptional = roleRepository.findById(Objects.requireNonNull(request.getRoleId()));
            if (roleOptional.isEmpty()) {
                return ApiResponse.error(404, "角色不存在");
            }
            
            // 验证部门是否存在
            Optional<Department> deptOptional = departmentRepository.findById(Objects.requireNonNull(request.getDeptId()));
            if (deptOptional.isEmpty()) {
                return ApiResponse.error(404, "部门不存在");
            }
            
            // 密码加密
            BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
            String encodedPassword = encoder.encode(request.getPassword());
            
            // 创建用户
            User user = new User();
            user.setUserName(request.getUserName());
            user.setPassword(encodedPassword);
            user.setRealName(request.getRealName().trim());
            user.setPhoneNumber(request.getPhone().trim());
            user.setEmail(request.getEmail());
            user.setCreationTime(LocalDateTime.now());
            
            // 设置角色
            user.setRole(roleOptional.get());
            
            // 设置部门
            user.setDepartment(deptOptional.get());
            
            // 保存用户
            userRepository.save(user);
            
            return ApiResponse.success();
        } catch (Exception e) {
            return ApiResponse.error(500, "添加用户失败: " + e.getMessage());
        }
    }

    /**
     * 更新用户信息
     * @param userId 用户ID
     * @param request 更新请求
     * @return 更新结果
     */
    public ApiResponse<Void> updateUser(Integer userId, UserUpdateRequest request) {
        try {
            // 查找用户
            Optional<User> userOptional = userRepository.findById(Objects.requireNonNull(userId));
            if (userOptional.isEmpty()) {
                return ApiResponse.error(404, "用户不存在");
            }
            
            User user = userOptional.get();

            // 强制要求角色与部门为必填
            if (request.getRoleId() == null) {
                return ApiResponse.error(400, "角色为必选项");
            }
            if (request.getDeptId() == null) {
                return ApiResponse.error(400, "部门为必选项");
            }

            // 更新角色（必填校验后）
            Optional<Role> roleOptional = roleRepository.findById(Objects.requireNonNull(request.getRoleId()));
            if (roleOptional.isEmpty()) {
                return ApiResponse.error(404, "角色不存在");
            }
            user.setRole(roleOptional.get());

            // 更新部门（必填校验后）
            Optional<Department> deptOptional = departmentRepository.findById(Objects.requireNonNull(request.getDeptId()));
            if (deptOptional.isEmpty()) {
                return ApiResponse.error(404, "部门不存在");
            }
            user.setDepartment(deptOptional.get());
            
            // 更新其他字段
            if (request.getUserName() != null && !request.getUserName().trim().isEmpty()) {
                // 检查用户名是否已被其他用户使用
                User existingUser = userRepository.findByUserName(request.getUserName());
                if (existingUser != null && !existingUser.getUserId().equals(userId)) {
                    return ApiResponse.error(400, "用户名已被使用");
                }
                user.setUserName(request.getUserName());
            }
            
            if (request.getRealName() != null && !request.getRealName().trim().isEmpty()) {
                user.setRealName(request.getRealName());
            }
            
            if (request.getPhoneNumber() != null && !request.getPhoneNumber().trim().isEmpty()) {
                user.setPhoneNumber(request.getPhoneNumber());
            }
            
            if (request.getEmail() != null) {
                user.setEmail(request.getEmail());
            }
            
            // 保存更新
            userRepository.save(user);
            
            return ApiResponse.success();
        } catch (Exception e) {
            return ApiResponse.error(500, "更新用户失败: " + e.getMessage());
        }
    }

    /**
     * 删除用户
     * @param userId 用户ID
     * @return 删除结果
     */
    public ApiResponse<Void> deleteUser(Integer userId) {
        try {
            // 查找用户
            Optional<User> userOptional = userRepository.findById(Objects.requireNonNull(userId));
            if (userOptional.isEmpty()) {
                return ApiResponse.error(404, "用户不存在");
            }
            
            User user = userOptional.get();
            
            // 检查用户是否有关联的任务（作为创建者）
            List<Task> createdTasks = taskRepository.findByCreator_UserId(userId);
            if (!createdTasks.isEmpty()) {
                return ApiResponse.error(400, "该用户创建了 " + createdTasks.size() + " 个任务，无法删除。请先处理相关任务。");
            }
            
            // 检查用户是否有关联的任务（作为执行者）
            boolean isExecutor = taskExecutorRelationRepository.existsByExecutor_UserId(userId);
            if (isExecutor) {
                return ApiResponse.error(400, "该用户正在执行任务，无法删除。请先从相关任务中移除该用户。");
            }
            
            // 检查用户是否有关联的日志
            List<Log> userLogs = logRepository.findByUserUserId(userId);
            if (!userLogs.isEmpty()) {
                return ApiResponse.error(400, "该用户有 " + userLogs.size() + " 条日志记录，无法删除。请先处理相关日志。");
            }
            
            // 删除用户
            userRepository.delete(Objects.requireNonNull(user));
            
            return ApiResponse.success();
        } catch (Exception e) {
            return ApiResponse.error(500, "删除用户失败: " + e.getMessage());
        }
    }

    /**
     * 递归收集所有当前部门及下级部门的ID
     * @param departmentId 当前部门ID
     * @param collectedDepartmentIds 已收集的部门ID集合
     */
    private void collectDepartmentHierarchy(Integer departmentId, Set<Integer> collectedDepartmentIds) {
        if (departmentId == null || collectedDepartmentIds.contains(departmentId)) {
            return;
        }

        collectedDepartmentIds.add(departmentId);
        // 获取所有子部门
        List<Department> subDepartments = departmentRepository.findByParentDepartment_departmentId(departmentId);
        for (Department subDepartment : subDepartments) {
            collectDepartmentHierarchy(subDepartment.getDepartmentId(), collectedDepartmentIds);
        }
    }

    /**
     * 获取用户个人资料（角色、邮箱、手机号）
     * @param userId 用户ID
     * @return 包含用户个人资料的响应
     */
    public ApiResponse<Map<String, Object>> getUserProfile(Integer userId) {
        try {
            User user = userRepository.findById(Objects.requireNonNull(userId)).orElse(null);
            if (user == null) {
                return ApiResponse.error(404, "用户不存在");
            }

            Map<String, Object> userProfile = new HashMap<>();
            userProfile.put("userId", user.getUserId());
            userProfile.put("realName", user.getRealName());
            userProfile.put("email", user.getEmail());
            userProfile.put("phoneNumber", user.getPhoneNumber());
            userProfile.put("roleId", user.getRole() != null ? user.getRole().getRoleId() : null);
            userProfile.put("deptId", user.getDepartment() != null ? user.getDepartment().getDepartmentId() : null);
            userProfile.put("roleName", user.getRole() != null ? user.getRole().getRoleName() : null);
            userProfile.put("deptName", user.getDepartment() != null ? user.getDepartment().getDepartmentName() : null);

            return ApiResponse.success(userProfile);
        } catch (Exception e) {
            return ApiResponse.error(500, "获取用户个人资料失败: " + e.getMessage());
        }
    }

    /**
     * 更新用户个人资料（只能修改自己的）
     * @param currentUserId 当前用户ID（从token中获取）
     * @param request 更新请求
     * @return 更新结果
     */
    public ApiResponse<Void> updateUserProfile(Integer currentUserId, UserProfileUpdateRequest request) {
        try {
            // 查找用户
            Optional<User> userOptional = userRepository.findById(Objects.requireNonNull(currentUserId));
            if (userOptional.isEmpty()) {
                return ApiResponse.error(404, "用户不存在");
            }
            User user = userOptional.get();

            if (request.getRealName() != null && !request.getRealName().trim().isEmpty()) {
                user.setRealName(request.getRealName());
            }

            if (request.getPhoneNumber() != null && !request.getPhoneNumber().trim().isEmpty()) {
                user.setPhoneNumber(request.getPhoneNumber());
            }

            if (request.getEmail() != null) {
                user.setEmail(request.getEmail());
            }

            // 保存更新
            Objects.requireNonNull(user); // 确保 user 非空，解决 Null type safety 警告
            userRepository.save(user);

            return ApiResponse.success();
        } catch (Exception e) {
            return ApiResponse.error(500, "更新用户个人资料失败: " + e.getMessage());
        }
    }

    /**
     * 更新用户的推送token
     * @param currentUserId 当前用户ID
     * @param pushToken 推送token
     * @return 更新结果
     */
    public ApiResponse<Void> updateUserPushToken(Integer currentUserId, String pushToken) {
        try {
            if (pushToken == null || pushToken.trim().isEmpty()) {
                pushToken=null;
            }

            Optional<User> userOptional = userRepository.findById(Objects.requireNonNull(currentUserId));
            if (userOptional.isEmpty()) {
                return ApiResponse.error(404, "用户不存在");
            }
            User user = userOptional.get();
            user.setHuaweiPushToken(pushToken);
            userRepository.save(user);

            return ApiResponse.success();
        } catch (Exception e) {
            return ApiResponse.error(500, "更新pushToken失败: " + e.getMessage());
        }
    }

    /**
     * 根据用户ID获取华为推送token
     * @param userId 用户ID
     * @return 华为推送token，如果用户不存在或token为空则返回null
     */
    public String getHuaweiPushTokenByUserId(@Nullable Integer userId) {
        if (userId == null) {
            return null;
        }
        return userRepository.findById(userId)
                .map(User::getHuaweiPushToken)
                .orElse(null);
    }

}
