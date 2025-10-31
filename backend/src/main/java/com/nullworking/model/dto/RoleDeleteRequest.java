package com.nullworking.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class RoleDeleteRequest {
    @JsonProperty("roleId")
    private Integer roleId;

    // Getters and Setters
    public Integer getRoleId() {
        return roleId;
    }

    public void setRoleId(Integer roleId) {
        this.roleId = roleId;
    }
}
