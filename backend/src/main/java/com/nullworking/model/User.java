package com.nullworking.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "User")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "User_ID")
    private Integer userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "Role_ID", nullable = true)
    private Role role;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "Dept_ID", nullable = true)
    private Department department;

    @Column(name = "User_Name", nullable = false, length = 64, unique = true)
    private String userName;

    @Column(name = "Password", length = 128)
    private String password;

    @Column(name = "Real_Name", nullable = false, length = 64)
    private String realName;

    @Column(name = "Phone_Number", nullable = false, length = 16)
    private String phoneNumber;

    @Column(name = "Email", length = 64)
    private String email;

    @Column(name = "Creation_Time", nullable = false)
    private LocalDateTime creationTime;

    @Column(name = "huawei_push_token", length = 255)
    private String huaweiPushToken;

    // Getters and Setters
    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public Department getDepartment() {
        return department;
    }

    public void setDepartment(Department department) {
        this.department = department;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getRealName() {
        return realName;
    }

    public void setRealName(String realName) {
        this.realName = realName;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public LocalDateTime getCreationTime() {
        return creationTime;
    }

    public void setCreationTime(LocalDateTime creationTime) {
        this.creationTime = creationTime;
    }

    public String getHuaweiPushToken() {
        return huaweiPushToken;
    }

    public void setHuaweiPushToken(String huaweiPushToken) {
        this.huaweiPushToken = huaweiPushToken;
    }
}
