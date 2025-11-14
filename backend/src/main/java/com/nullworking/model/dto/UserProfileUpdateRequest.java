package com.nullworking.model.dto;

import lombok.Data;

@Data
public class UserProfileUpdateRequest {
    private String realName;
    private String phoneNumber;
    private String email;
}
