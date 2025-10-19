package com.nullworking.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
// import org.springframework.security.authentication.AuthenticationManager;
// import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
// import org.springframework.security.core.AuthenticationException;

import com.nullworking.common.ApiResponse;
import com.nullworking.service.AuthService;
// import com.nullworking.model.User;
// import com.nullworking.repository.UserRepository;
// import com.nullworking.util.JwtUtil;

import io.swagger.v3.oas.annotations.Operation;
// import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    // @Autowired
    // private UserRepository userRepository;

    // @Autowired
    // private AuthenticationManager authenticationManager;

    // @Autowired
    // private JwtUtil jwtUtil;

    @Autowired
    private AuthService authService;

    @Operation(summary = "用户登录", description = "根据用户名和密码登录，返回用户ID、角色ID和JWT Token")
    @GetMapping("/login")
    public ApiResponse<Map<String, Object>> login(@RequestParam String userName, @RequestParam String password) {
        return authService.login(userName, password);
    }

    @Operation(summary = "用户注册", description = "注册新用户，需填写真实姓名，密码加密存储")
    @GetMapping("/register")
    public ApiResponse<String> register(@RequestParam String userName,
                                       @RequestParam String password,
                                       @RequestParam String realName,
                                       @RequestParam String phone,
                                       @RequestParam(required = false) String email) {
        return authService.register(userName, password, realName, phone, email);
    }
}
