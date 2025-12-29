package com.nullworking.service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.nullworking.common.ApiResponse;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import com.nullworking.model.User;
import com.nullworking.model.dto.RegisterRequest;
import com.nullworking.repository.UserRepository;
import com.nullworking.util.JwtUtil;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private EmailService emailService;

    @Autowired
    private VerificationCodeService verificationCodeService;

    @Value("${jwt.secret}")
    private String jwtSecret; // 复用JWT密钥作为加密密钥，不修改配置文件

    // 所有的业务逻辑将在这里实现

    public ApiResponse<Map<String, Object>> login(String userName, String password) {
        Map<String, Object> data = new HashMap<>();
        try {
            // 先根据用户名查询用户，区分“用户不存在/密码错误”和“已离职(软删除)”的场景
            User user = userRepository.findByUserName(userName);
            if (user == null) {
                // 用户名不存在：保持原有提示，防止信息泄露
                return ApiResponse.error(401, "用户名或密码错误");
            }

            // 如果用户已被软删除（离职），直接返回“已离职”提示
            if (user.getStatus() != null && user.getStatus() == (byte) 1) {
                return ApiResponse.error(403, "该账号已离职，无法登录");
            }

            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(userName, password)
            );
            // 如果认证成功
            String jwt = jwtUtil.generateToken(user.getUserId(), user.getUserName());

            data.put("token", jwt);
            data.put("userId",user.getUserId());
            data.put("userName",user.getRealName());
            return ApiResponse.success(data);

        } catch (AuthenticationException e) {
            return ApiResponse.error(401, "用户名或密码错误");
        }
    }

    public ApiResponse<String> register(RegisterRequest request) {
        // 检查用户名是否已存在
        if (userRepository.findByUserName(request.getUserName()) != null) {
            return ApiResponse.error(409, "用户名已存在"); // 用户名冲突
        }
        // 校验真实姓名必填
        if (request.getRealName() == null || request.getRealName().trim().isEmpty()) {
            return ApiResponse.error(400, "真实姓名为必填项");
        }
        // 密码加密
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String encodedPassword = encoder.encode(request.getPassword());
        User user = new User();
        user.setUserName(request.getUserName());
        user.setPassword(encodedPassword);
        user.setRealName(request.getRealName().trim());
        // 电话号和邮箱加密存储（仿照密码加密方式，使用Java标准库）
        user.setPhoneNumber(encryptData(request.getPhone()));
        user.setEmail(encryptData(request.getEmail()));
        user.setCreationTime(LocalDateTime.now());
        // 默认状态：0=正常
        user.setStatus((byte) 0);
        // 角色和部门可根据实际业务设置，这里默认 null
        userRepository.save(user);
        return ApiResponse.success("注册成功");
    }

    public ApiResponse<Void> sendPasswordResetCode(String emailOrUsername) {
        if (emailOrUsername == null || emailOrUsername.trim().isEmpty()) {
            return ApiResponse.error(400, "请输入用户名或邮箱");
        }
        // 允许输入用户名或邮箱，优先用户名精确查找
        User user = userRepository.findByUserName(emailOrUsername);
        if (user == null) {
            // 查询邮箱前先加密（仿照密码验证方式）
            String encryptedEmail = encryptData(emailOrUsername);
            user = userRepository.findByEmail(encryptedEmail);
        }
        if (user == null) {
            return ApiResponse.error(404, "未找到该用户");
        }
        // 使用解密后的邮箱发送邮件
        String decryptedEmail = decryptData(user.getEmail());
        String code = verificationCodeService.generateCode(decryptedEmail);
        String subject = "重置密码验证码";
        String text = String.format("您的重置密码验证码是：%s，%d 分钟内有效。如非本人操作请忽略。", code, verificationCodeService.getExpireMinutes());
        try {
            emailService.sendSimpleMail(decryptedEmail, subject, text);
            return ApiResponse.success();
        } catch (Exception e) {
            return ApiResponse.error(500, "发送邮件失败: " + e.getMessage());
        }
    }

    public ApiResponse<String> resetPasswordWithCode(String email, String code, String newPassword) {
        if (email == null || code == null || newPassword == null) {
            return ApiResponse.error(400, "参数不完整");
        }
        // 验证新密码不能为空
        if (newPassword.trim().isEmpty()) {
            return ApiResponse.error(400, "新密码不能为空");
        }
        // 允许输入用户名或邮箱，优先用户名精确查找
        User user = userRepository.findByUserName(email);
        if (user == null) {
            // 查询邮箱前先加密（仿照密码验证方式）
            String encryptedEmail = encryptData(email);
            user = userRepository.findByEmail(encryptedEmail);
        }
        if (user == null) {
            return ApiResponse.error(404, "未找到该用户");
        }
        // 验证码验证需要使用解密后的邮箱
        String decryptedEmail = decryptData(user.getEmail());
        boolean ok = verificationCodeService.verifyCode(decryptedEmail, code);
        if (!ok) {
            return ApiResponse.error(400, "验证码错误或已过期");
        }
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        user.setPassword(encoder.encode(newPassword));
        userRepository.save(user);
        return ApiResponse.success("密码重置成功");
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
