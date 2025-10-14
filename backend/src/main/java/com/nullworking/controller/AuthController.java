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

import com.nullworking.model.User;
import com.nullworking.repository.UserRepository;

import io.swagger.v3.oas.annotations.Operation;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @Operation(summary = "用户登录", description = "根据用户名和密码登录，返回用户ID和角色ID")
    @GetMapping("/login")
    public Map<String, Object> login(@RequestParam String userName, @RequestParam String passWord) {
        Map<String, Object> result = new HashMap<>();
        User user = userRepository.findByUserName(userName);
        if (user == null) {
            result.put("code", 404);
            result.put("message", "用户不存在");
            result.put("userID", null);
            result.put("roleID", null);
            return result;
        }
        // 加密密码校验
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        if (user.getPassword() == null || !encoder.matches(passWord, user.getPassword())) {
            result.put("code", 401);
            result.put("message", "密码错误");
            result.put("userID", null);
            result.put("roleID", null);
            return result;
        }
        result.put("code", 200);
        result.put("message", "登录成功");
        result.put("userID", user.getUserId());
        result.put("roleID", user.getRole() != null ? user.getRole().getRoleId() : null);
        return result;
    }

    @Operation(summary = "用户注册", description = "注册新用户，密码加密存储")
    @GetMapping("/register")
    public Map<String, Object> register(@RequestParam String userName,
                                       @RequestParam String password,
                                       @RequestParam String phone,
                                       @RequestParam(required = false) String email) {
        Map<String, Object> result = new HashMap<>();
        // 检查用户名是否已存在
        if (userRepository.findByUserName(userName) != null) {
            result.put("code", 409); // 用户名冲突
            return result;
        }
        // 密码加密
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String encodedPassword = encoder.encode(password);
        User user = new User();
        user.setUserName(userName);
        user.setPassword(encodedPassword);
        user.setPhoneNumber(phone);
        user.setEmail(email);
        user.setCreationTime(LocalDateTime.now());
        // 角色和部门可根据实际业务设置，这里默认 null
        userRepository.save(user);
        result.put("code", 200);
        return result;
    }
}
