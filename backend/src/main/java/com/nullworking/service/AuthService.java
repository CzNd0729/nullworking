package com.nullworking.service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.nullworking.common.ApiResponse;
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

    public ApiResponse<Void> sendPasswordResetCode(String emailOrUsername) {
        if (emailOrUsername == null || emailOrUsername.trim().isEmpty()) {
            return ApiResponse.error(400, "请输入用户名或邮箱");
        }
        // 允许输入用户名或邮箱，优先用户名精确查找
        User user = userRepository.findByUserName(emailOrUsername);
        if (user == null) {
            user = userRepository.findByEmail(emailOrUsername);
        }
        if (user == null) {
            return ApiResponse.error(404, "未找到该用户");
        }
        String code = verificationCodeService.generateCode(user.getEmail());
        String subject = "重置密码验证码";
        String text = String.format("您的重置密码验证码是：%s，%d 分钟内有效。如非本人操作请忽略。", code, verificationCodeService.getExpireMinutes());
        try {
            emailService.sendSimpleMail(user.getEmail(), subject, text);
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
            user = userRepository.findByEmail(email);
        }
        if (user == null) {
            return ApiResponse.error(404, "未找到该用户");
        }
        boolean ok = verificationCodeService.verifyCode(user.getEmail(), code);
        if (!ok) {
            return ApiResponse.error(400, "验证码错误或已过期");
        }
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        user.setPassword(encoder.encode(newPassword));
        userRepository.save(user);
        return ApiResponse.success("密码重置成功");
    }
}
