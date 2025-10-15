package com.nullworking.common;

import java.io.Serializable;

/**
 * 统一API响应结果封装类
 * 用于标准化接口返回格式
 */
public class ApiResponse<T> implements Serializable {
    private static final long serialVersionUID = 1L;
    
    private int code;
    private String message;
    private T data;

    // 无参构造器（JSON序列化需要）
    public ApiResponse() {
    }

    // 全参构造器
    public ApiResponse(int code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    // 成功响应（带数据）
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(200, "操作成功", data);
    }

    // 成功响应（无数据）
    public static <T> ApiResponse<T> success() {
        return new ApiResponse<>(200, "操作成功", null);
    }

    // 错误响应
    public static <T> ApiResponse<T> error(int code, String message) {
        return new ApiResponse<>(code, message, null);
    }

    // Getter和Setter
    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }
}