package com.nullworking.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "Role")
public class Role {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "Role_ID")
    private Integer roleId;

    @Column(name = "Role_Name", nullable = false, length = 64, unique = true)
    private String roleName;

    @Column(name = "Role_Description", length = 255)
    private String roleDescription;

    @Column(name = "Creation_Time", nullable = false)
    private LocalDateTime creationTime;

    @Column(name = "Update_Time", nullable = false)
    private LocalDateTime updateTime;

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

    public LocalDateTime getCreationTime() {
        return creationTime;
    }

    public void setCreationTime(LocalDateTime creationTime) {
        this.creationTime = creationTime;
    }

    public LocalDateTime getUpdateTime() {
        return updateTime;
    }

    public void setUpdateTime(LocalDateTime updateTime) {
        this.updateTime = updateTime;
    }
}
