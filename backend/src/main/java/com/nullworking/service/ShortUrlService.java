package com.nullworking.service;

import com.nullworking.config.OpenInstallConfig;
import com.nullworking.model.AIAnalysisResult;
import com.nullworking.model.ShortUrl;
import com.nullworking.model.dto.ShortUrlResponse;
import com.nullworking.repository.AIAnalysisResultRepository;
import com.nullworking.repository.ShortUrlRepository;
import com.nullworking.util.ShortCodeGenerator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 短链接业务服务类（数据库版）
 * 替换内存Map为数据库操作，添加事务保证数据一致性
 */
@Service
public class ShortUrlService {
    @Autowired
    private ShortUrlRepository shortUrlRepository;

    @Autowired
    private AIAnalysisResultRepository aiAnalysisResultRepository;

    @Autowired
    private OpenInstallConfig openInstallConfig;

    // 默认过期天数（可配置化，也可放application.yml）
    private static final int DEFAULT_EXPIRE_DAYS = 7;

    /**
     * 生成短链接（数据库版，带事务）
     */
    @Transactional(rollbackFor = Exception.class)
    public ShortUrlResponse generateShortUrl(Integer resultId, Integer currentUserId) {
        // 1. 校验用户权限：仅结果创建者可分享
        AIAnalysisResult result = aiAnalysisResultRepository.findById(resultId)
                .orElseThrow(() -> new IllegalArgumentException("分析结果不存在"));
        if (result.getUser() == null || result.getUser().getUserId() == null
                || !result.getUser().getUserId().equals(currentUserId)) {
            throw new SecurityException("无权限分享该分析结果");
        }

        // 2. 生成唯一短码（循环检测数据库是否已存在）
        String shortCode;
        do {
            shortCode = ShortCodeGenerator.generate();
        } while (shortUrlRepository.existsByShortCode(shortCode));

        // 3. 构建短链接实体，存入数据库
        ShortUrl shortUrl = new ShortUrl();
        shortUrl.setShortCode(shortCode);
        shortUrl.setResultId(resultId);
        shortUrl.setUserId(currentUserId);
        shortUrl.setExpireTime(LocalDateTime.now().plusDays(DEFAULT_EXPIRE_DAYS));
        shortUrl.setVisitCount(0); // 初始访问次数为0
        shortUrlRepository.save(shortUrl);

        // 4. 拼接OpenInstall短链接
        ShortUrlResponse response = new ShortUrlResponse();
        response.setShortUrl(
                openInstallConfig.getDefaultDomain()
                        + "?shortCode=" + shortCode
                        + "&resultId=" + resultId
        );
        return response;
    }

    /**
     * 解析短码获取AI分析结果（数据库版，带事务）
     */
    @Transactional(rollbackFor = Exception.class)
    public AIAnalysisResult parseShortCode(String shortCode) {
        // 1. 查询短链接记录
        Optional<ShortUrl> shortUrlOpt = shortUrlRepository.findByShortCode(shortCode);
        if (shortUrlOpt.isEmpty()) {
            throw new IllegalArgumentException("短链接无效");
        }
        ShortUrl shortUrl = shortUrlOpt.get();

        // 2. 校验是否过期
        if (shortUrl.getExpireTime().isBefore(LocalDateTime.now())) {
            // 可选：删除过期记录（或定时任务清理）
            shortUrlRepository.delete(shortUrl);
            throw new IllegalArgumentException("短链接已过期");
        }

        // 3. 累加访问次数并更新
        shortUrl.setVisitCount(shortUrl.getVisitCount() + 1);
        shortUrlRepository.save(shortUrl);

        // 4. 查询并返回AI分析结果
        return aiAnalysisResultRepository.findById(shortUrl.getResultId())
                .orElseThrow(() -> new IllegalArgumentException("分析结果不存在"));
    }
}