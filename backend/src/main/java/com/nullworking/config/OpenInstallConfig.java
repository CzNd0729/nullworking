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
     * OpenInstall默认测试域名
     */
    private String defaultDomain = "https://app-w0h9pp.openinstall.com/w0h9pp";
    /**
     * 唤起APP的Scheme（与OpenInstall控制台配置一致：w0h9pp）
     */
    private String scheme = "w0h9pp";
}