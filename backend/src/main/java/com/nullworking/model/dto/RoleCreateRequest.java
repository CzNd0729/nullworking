package com.nullworking.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public class RoleCreateRequest {
    @JsonProperty("roleName")
    private String roleName;

    @JsonProperty("roleDescription")
    private String roleDescription;

    @JsonProperty("permissions")
    private List<Integer> permissions;

    // Getters and Setters
    public String getRoleName() {
        return roleName;
    }

    public void setRoleName(String roleName) {
        this.roleName = roleName;
    }

    public String getRoleDescription() {
        return roleDescription;
    }

    public void setRoleDescription(String roleDescription) {
        this.roleDescription = roleDescription;
    }

    public List<Integer> getPermissions() {
        return permissions;
    }

    public void setPermissions(List<Integer> permissions) {
        this.permissions = permissions;
    }
}
