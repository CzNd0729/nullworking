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
        user.setPhoneNumber(request.getPhone());
        user.setEmail(request.getEmail());
        user.setCreationTime(LocalDateTime.now());
        // 默认状态：0=正常
        user.setStatus((byte) 0);
        // 角色和部门可根据实际业务设置，这里默认 null
        userRepository.save(user);
        return ApiResponse.success("注册成功");
    }

    public ApiResponse<Void> sendPasswordResetCode(String email) {
        if (email == null || email.trim().isEmpty()) {
            return ApiResponse.error(400, "邮箱不能为空");
        }
        User user = userRepository.findByEmail(email);
        if (user == null) {
            return ApiResponse.error(404, "未找到该邮箱对应的用户");
        }
        String code = verificationCodeService.generateCode(email);
        String subject = "重置密码验证码";
        String text = String.format("您的重置密码验证码是：%s，%d 分钟内有效。如非本人操作请忽略。", code, verificationCodeService.getExpireMinutes());
        try {
            emailService.sendSimpleMail(email, subject, text);
            return ApiResponse.success();
        } catch (Exception e) {
            return ApiResponse.error(500, "发送邮件失败: " + e.getMessage());
        }
    }

    public ApiResponse<String> resetPasswordWithCode(String email, String code, String newPassword) {
        if (email == null || code == null || newPassword == null) {
            return ApiResponse.error(400, "参数不完整");
        }
        boolean ok = verificationCodeService.verifyCode(email, code);
        if (!ok) {
            return ApiResponse.error(400, "验证码错误或已过期");
        }
        User user = userRepository.findByEmail(email);
        if (user == null) {
            return ApiResponse.error(404, "未找到该邮箱对应的用户");
        }
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        user.setPassword(encoder.encode(newPassword));
        userRepository.save(user);
        return ApiResponse.success("密码重置成功");
    }
}
