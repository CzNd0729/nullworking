package com.nullworking.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public class RoleUpdateRequest {
    @JsonProperty("roleId")
    private Integer roleId;

    @JsonProperty("roleName")
    private String roleName;

    @JsonProperty("roleDescription")
    private String roleDescription;

    @JsonProperty("permissionIds")
    private List<Integer> permissionIds;

    // Getters and Setters
    public Integer getRoleId() {
        return roleId;
    }

    public void setRoleId(Integer roleId) {
        this.roleId = roleId;
    }

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

    public List<Integer> getPermissionIds() {
        return permissionIds;
    }

    public void setPermissionIds(List<Integer> permissionIds) {
        this.permissionIds = permissionIds;
    }
}
