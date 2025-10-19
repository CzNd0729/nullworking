package com.nullworking.service;

import com.nullworking.common.ApiResponse;
import com.nullworking.model.User;
import com.nullworking.repository.UserRepository;
import com.nullworking.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import com.nullworking.model.dto.RegisterRequest;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtil jwtUtil;

    // 所有的业务逻辑将在这里实现

    public ApiResponse<Map<String, Object>> login(String userName, String password) {
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
        // 角色和部门可根据实际业务设置，这里默认 null
        userRepository.save(user);
        return ApiResponse.success("注册成功");
    }
}
