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
import java.util.NoSuchElementException;
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
     */// 添加方法：查询是否存在有效短链接
    public Optional<ShortUrl> findValidShortUrlByResultId(Integer resultId) {
        LocalDateTime now = LocalDateTime.now();
        // 查询未过期且属于该resultId的短链接
        return shortUrlRepository.findByResultIdAndExpireTimeAfter(resultId, now);
    }

    // 修改generateShortUrl方法，优先使用已有有效短链接
    @Transactional(rollbackFor = Exception.class)
    public ShortUrlResponse generateShortUrl(Integer resultId, Integer currentUserId) {
        // 1. 校验用户权限（原逻辑不变）
        AIAnalysisResult result = aiAnalysisResultRepository.findById(resultId)
                .orElseThrow(() -> new IllegalArgumentException("分析结果不存在"));
        if (result.getUser() == null || result.getUser().getUserId() == null
                || !result.getUser().getUserId().equals(currentUserId)) {
            throw new SecurityException("无权限分享该分析结果");
        }
        // 2. 检查是否已有有效短链接，有则直接返回
        Optional<ShortUrl> existingShortUrl = findValidShortUrlByResultId(resultId);
        if (existingShortUrl.isPresent()) {
            ShortUrl shortUrl = existingShortUrl.get();
            ShortUrlResponse response = new ShortUrlResponse();
        response.setShortUrl(buildShortUrl(shortUrl.getShortCode()));
        return response;
    }

        // 3. 生成新短码（原逻辑不变）
        String shortCode;
        do {
            shortCode = ShortCodeGenerator.generate();
        } while (shortUrlRepository.existsByShortCode(shortCode));

        // 4. 保存新短链接（原逻辑不变）
        ShortUrl shortUrl = new ShortUrl();
        shortUrl.setShortCode(shortCode);
        shortUrl.setResultId(resultId);
        shortUrl.setUserId(currentUserId);
        shortUrl.setExpireTime(LocalDateTime.now().plusDays(DEFAULT_EXPIRE_DAYS));
        shortUrl.setVisitCount(0);
        shortUrlRepository.save(shortUrl);

        // 5. 构建响应
        ShortUrlResponse response = new ShortUrlResponse();
        response.setShortUrl(buildShortUrl(shortCode));
        return response;
}

// 新增：统一构建短链接的方法
    private String buildShortUrl(String shortCode) {
        // 只包含shortCode，避免暴露resultId
        return openInstallConfig.getDefaultDomain() + "/api/share/web/" + shortCode;
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

    /**
    * 公开接口：根据resultId查询有效短链接（无需权限校验）
    * @param resultId 分析结果ID
    * @return 完整短链接URL
    * @throws NoSuchElementException 当无有效短链接时抛出
    */
    public String getPublicShortUrlByResultId(Integer resultId) {
    // 1. 仅校验分析结果存在性（不验证用户权限）
     AIAnalysisResult result = aiAnalysisResultRepository.findById(resultId)
                .orElseThrow(() -> new IllegalArgumentException("分析结果不存在"));

     // 2. 查询未过期的短链接
        Optional<ShortUrl> existingShortUrl = findValidShortUrlByResultId(resultId);
        if (existingShortUrl.isPresent()) {
           return buildShortUrl(existingShortUrl.get().getShortCode());
        }

        // 3. 无有效短链接时抛出异常
        throw new NoSuchElementException("未找到有效短链接");
    }
}