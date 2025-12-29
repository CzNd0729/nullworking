package com.nullworking.service;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.Department;
import com.nullworking.model.Role;
import com.nullworking.model.User;
import com.nullworking.model.dto.UserCreateRequest;
import com.nullworking.model.dto.UserUpdateRequest;
import com.nullworking.model.dto.UserProfileUpdateRequest;
import com.nullworking.repository.DepartmentRepository;
import com.nullworking.repository.RoleRepository;
// import com.nullworking.repository.LogRepository;
// import com.nullworking.repository.TaskExecutorRelationRepository;
// import com.nullworking.repository.TaskRepository;
import com.nullworking.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.lang.Nullable;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.*;
import java.util.Base64;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

    @Autowired
    private RoleRepository roleRepository;

    // 以下仓库目前未在软删除模式下使用，如后续有业务需要可再启用
    // @Autowired
    // private TaskRepository taskRepository;

    // @Autowired
    // private LogRepository logRepository;

    // @Autowired
    // private TaskExecutorRelationRepository taskExecutorRelationRepository;

    @Autowired
    private PermissionService permissionService;

    @Value("${jwt.secret}")
    private String jwtSecret; // 复用JWT密钥作为加密密钥，不修改配置文件

    // @Autowired
    // private JwtUtil jwtUtil;

    // 所有的业务逻辑将在这里实现

    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,6}$"
    );

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

        // 3. 查询这些部门下的所有用户（排除当前用户自己，且仅包含未删除用户）
        List<User> usersInHierarchy = userRepository.findByDepartmentDepartmentIdInAndStatus(departmentIdsInHierarchy, (byte) 0)
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
            // 仅查询未被软删除的用户
            List<User> users = userRepository.findByStatus((byte) 0);
            
            List<Map<String, Object>> userList = new ArrayList<>();
            for (User user : users) {
                Map<String, Object> userMap = new HashMap<>();
                userMap.put("userId", user.getUserId());
                userMap.put("realName", user.getRealName());
                // 账号、联系方式（解密后返回）
                userMap.put("userName", user.getUserName());
                userMap.put("phoneNumber", decryptData(user.getPhoneNumber()));
                userMap.put("email", decryptData(user.getEmail()));
                
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
    public ApiResponse<Integer> addUser(UserCreateRequest request) {
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
            
            // 验证邮箱格式
            if (request.getEmail() == null || !EMAIL_PATTERN.matcher(request.getEmail()).matches()) {
                return ApiResponse.error(400, "邮箱格式不正确");
            }
            
            // 密码加密
            BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
            String encodedPassword = encoder.encode(request.getPassword());
            
            // 创建用户
            User user = new User();
            user.setUserName(request.getUserName());
            user.setPassword(encodedPassword);
            user.setRealName(request.getRealName().trim());
            // 电话号和邮箱加密存储（仿照密码加密方式，使用Java标准库）
            user.setPhoneNumber(encryptData(request.getPhone().trim()));
            user.setEmail(encryptData(request.getEmail()));
            user.setCreationTime(LocalDateTime.now());
            // 默认状态：0=正常
            user.setStatus((byte) 0);
            
            // 设置角色
            user.setRole(roleOptional.get());
            
            // 设置部门
            user.setDepartment(deptOptional.get());
            
            // 保存用户
            userRepository.save(user);
            
            return ApiResponse.success(user.getUserId());
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
    // filePath: nullworking/service/UserService.java
public ApiResponse<Void> updateUser(Integer userId, UserUpdateRequest request) {
    try {
            // 不允许编辑管理员
            if (userId == 0) {
                return ApiResponse.error(400, "不允许编辑管理员");
            }
            
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

        // 更新其他允许修改的字段（真实姓名、电话、邮箱等）
        if (request.getRealName() != null && !request.getRealName().trim().isEmpty()) {
            user.setRealName(request.getRealName().trim());
        }
        if (request.getPhone() != null && !request.getPhone().trim().isEmpty()) {
            // 电话号加密存储
            user.setPhoneNumber(encryptData(request.getPhone().trim()));
        }
        if (request.getEmail() != null && EMAIL_PATTERN.matcher(request.getEmail()).matches()) {
            // 检查邮箱唯一性（排除自己）- 查询前先加密
            String encryptedEmail = encryptData(request.getEmail());
            User exist = userRepository.findByEmail(encryptedEmail);
            if (exist != null && !exist.getUserId().equals(userId)) {
                return ApiResponse.error(409, "该邮箱已被其他账号占用");
            }
            // 邮箱加密存储
            user.setEmail(encryptedEmail);
        }

        // 注意：此处刻意不处理 userName 字段，禁止更新用户名

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
            
            if (userId==0){
                return ApiResponse.error(400, "不允许删除管理员");
            }

            User user = userOptional.get();

            // 已软删除的用户无需重复删除
            if (user.getStatus() != null && user.getStatus() == (byte) 1) {
                return ApiResponse.error(400, "该用户已离职，无需重复删除");
            }

            // 软删除：标记状态为已删除，并将部门挪到总公司（Dept_ID = 1）
            user.setStatus((byte) 1);

            // 将部门设置为总公司（假定 ID=1 为总公司）
            Department headDepartment = departmentRepository.findById(1).orElse(null);
            user.setDepartment(headDepartment);

            userRepository.save(user);

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
            // 电话号和邮箱解密后返回
            userProfile.put("email", decryptData(user.getEmail()));
            userProfile.put("phoneNumber", decryptData(user.getPhoneNumber()));
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
                // 电话号加密存储
                user.setPhoneNumber(encryptData(request.getPhoneNumber().trim()));
            }

            if (request.getEmail() != null) {
                // 验证邮箱不能为空
                if (request.getEmail().trim().isEmpty()) {
                    return ApiResponse.error(400, "邮箱不能为空");
                }
                // 检查邮箱唯一性（排除自己）- 查询前先加密
                String encryptedEmail = encryptData(request.getEmail());
                User exist = userRepository.findByEmail(encryptedEmail);
                if (exist != null && !exist.getUserId().equals(currentUserId)) {
                    return ApiResponse.error(409, "该邮箱已被其他账号占用");
                }
                // 邮箱加密存储
                user.setEmail(encryptedEmail);
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

    /**
     * 修改用户密码
     * @param userId 用户ID
     * @param oldPassword 旧密码
     * @param newPassword 新密码
     * @return 修改结果
     */
    public ApiResponse<Void> changePassword(Integer userId, String oldPassword, String newPassword) {
        try {
            Optional<User> userOptional = userRepository.findById(userId);
            if (userOptional.isEmpty()) {
                return ApiResponse.error(404, "用户不存在");
            }

            if (newPassword == null || newPassword.trim().isEmpty()) {
                return ApiResponse.error(400, "新密码不能为空");
            }

            User user = userOptional.get();
            BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

            if (!encoder.matches(oldPassword, user.getPassword())) {
                return ApiResponse.error(400, "原密码不正确");
            }

            user.setPassword(encoder.encode(newPassword));
            userRepository.save(user);

            return ApiResponse.success();
        } catch (Exception e) {
            return ApiResponse.error(500, "修改密码失败: " + e.getMessage());
        }
    }

    /**
     * 加密敏感数据（电话号、邮箱）- 仿照密码加密方式，使用Java标准库，不新建类
     */
    private String encryptData(String data) {
        if (data == null || data.isEmpty() || jwtSecret == null || jwtSecret.isEmpty()) {
            return data;
        }
        try {
            // 使用JWT密钥生成AES密钥（取前32字节）
            byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
            byte[] aesKey = new byte[32];
            System.arraycopy(keyBytes, 0, aesKey, 0, Math.min(keyBytes.length, 32));
            SecretKeySpec keySpec = new SecretKeySpec(aesKey, "AES");
            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.ENCRYPT_MODE, keySpec);
            byte[] encryptedBytes = cipher.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(encryptedBytes);
        } catch (Exception e) {
            // 加密失败时返回原值，避免影响业务
            return data;
        }
    }

    /**
     * 解密敏感数据（电话号、邮箱）
     */
    private String decryptData(String data) {
        if (data == null || data.isEmpty() || jwtSecret == null || jwtSecret.isEmpty()) {
            return data;
        }
        // 判断是否为加密数据：加密后的Base64字符串通常较长且不包含常见字符（如@、-等）
        // 如果数据看起来像未加密的（包含@符号的邮箱或纯数字的电话号），直接返回
        if (data.contains("@") || (data.length() <= 16 && data.matches("^[0-9\\-+\\s]+$"))) {
            return data; // 看起来是未加密的数据
        }
        try {
            // 使用JWT密钥生成AES密钥（取前32字节）
            byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
            byte[] aesKey = new byte[32];
            System.arraycopy(keyBytes, 0, aesKey, 0, Math.min(keyBytes.length, 32));
            SecretKeySpec keySpec = new SecretKeySpec(aesKey, "AES");
            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.DECRYPT_MODE, keySpec);
            byte[] decryptedBytes = cipher.doFinal(Base64.getDecoder().decode(data));
            return new String(decryptedBytes, StandardCharsets.UTF_8);
        } catch (Exception e) {
            // 解密失败时返回原值（可能是旧数据未加密）
            return data;
        }
    }

}
