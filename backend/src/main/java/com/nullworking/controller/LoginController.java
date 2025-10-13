package com.nullworking.controller;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import io.swagger.v3.oas.annotations.Operation;
import java.util.Map;
import java.util.HashMap;
import com.nullworking.model.User;
import com.nullworking.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class LoginController {
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
}
