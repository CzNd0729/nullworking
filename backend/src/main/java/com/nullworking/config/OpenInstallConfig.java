package com.nullworking.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * OpenInstall平台配置类
 * 读取application.yml中openinstall前缀的配置，适配你现有配置体系
 */
@Component
@ConfigurationProperties(prefix = "openinstall")
@Data
public class OpenInstallConfig {
    /**
     * OpenInstall分配的AppKey
     */
    private String appKey = "w0h9pp";

    /**
     * 服务器地址
     */
    private String defaultDomain = "http://58.87.76.10:8081/link";
    /**
     * 唤起APP的Scheme（与OpenInstall控制台配置一致：w0h9pp）
     */
    private String scheme = "w0h9pp";
}