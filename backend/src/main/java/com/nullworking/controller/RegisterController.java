package com.nullworking.controller;
import java.time.LocalDateTime;

import io.swagger.v3.oas.annotations.Operation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.nullworking.model.User;
import com.nullworking.repository.UserRepository;
import java.util.HashMap;
import java.util.Map;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@RestController
@RequestMapping("/api")
public class RegisterController {
    @Autowired
    private UserRepository userRepository;

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
