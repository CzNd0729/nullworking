package com.nullworking.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.User;
import com.nullworking.repository.UserRepository;
import com.nullworking.util.JwtUtil;

import io.swagger.v3.oas.annotations.Operation;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtil jwtUtil;

    @Operation(summary = "用户登录", description = "根据用户名和密码登录，返回用户ID、角色ID和JWT Token")
    @GetMapping("/login")
    public ApiResponse<Map<String, Object>> login(@RequestParam String userName, @RequestParam String password) {
        Map<String, Object> data = new HashMap<>();
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(userName, password)
            );
            // 如果认证成功

            User user = userRepository.findByUserName(userName);
            String jwt = jwtUtil.generateToken(user.getUserId(), user.getUserName());

            data.put("roleID", user.getRole() != null ? user.getRole().getRoleId() : null);
            data.put("token", jwt);
            data.put("userID",user.getUserId());
            return ApiResponse.success(data);

        } catch (AuthenticationException e) {
            return ApiResponse.error(401, "用户名或密码错误");
        }
    }

    @Operation(summary = "用户注册", description = "注册新用户，需填写真实姓名，密码加密存储")
    @GetMapping("/register")
    public ApiResponse<String> register(@RequestParam String userName,
                                       @RequestParam String password,
                                       @RequestParam String realName,
                                       @RequestParam String phone,
                                       @RequestParam(required = false) String email) {
        // 检查用户名是否已存在
        if (userRepository.findByUserName(userName) != null) {
            return ApiResponse.error(409, "用户名已存在"); // 用户名冲突
        }
        // 校验真实姓名必填
        if (realName == null || realName.trim().isEmpty()) {
            return ApiResponse.error(400, "真实姓名为必填项");
        }
        // 密码加密
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String encodedPassword = encoder.encode(password);
        User user = new User();
        user.setUserName(userName);
        user.setPassword(encodedPassword);
        user.setRealName(realName.trim());
        user.setPhoneNumber(phone);
        user.setEmail(email);
        user.setCreationTime(LocalDateTime.now());
        // 角色和部门可根据实际业务设置，这里默认 null
        userRepository.save(user);
        return ApiResponse.success("注册成功");
    }
}
