package com.nullworking.controller;

import com.nullworking.common.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthCheckController {

    @GetMapping("/api/health")
    public ApiResponse<String> checkHealth() {
        return ApiResponse.success("OK");
    }
}