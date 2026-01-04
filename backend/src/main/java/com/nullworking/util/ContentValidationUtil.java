package com.nullworking.util;

import org.springframework.util.StringUtils;

import java.util.regex.Pattern;

/**
 * 文本内容验证工具类，用于检测乱码和无效内容
 */
public class ContentValidationUtil {

    // 识别有效中文字符的正则
    private static final Pattern CHINESE_CHAR_PATTERN = Pattern.compile("[\u4e00-\u9fa5]");
    
    // 识别可能的 Mojibake 字符 (通常是 UTF-8 字节被误认为 ISO-8859-1 字符)
    // 这些字符在正常的中文 AI 分析结果（即使包含 JSON）中极少成对出现
    private static final Pattern MOJIBAKE_CHAR_PATTERN = Pattern.compile("[\u0080-\u00FF]");

    /**
     * 验证AI分析结果是否有效（无乱码）
     * 
     * @param content 分析结果内容
     * @return 有效返回true，无效返回false
     */
    public static boolean isValidAnalysisContent(String content) {
        if (!StringUtils.hasText(content)) {
            return false;
        }

        String trimmedContent = content.trim();
        int length = trimmedContent.length();

        // 1. 统计特征字符
        long chineseCount = CHINESE_CHAR_PATTERN.matcher(trimmedContent).results().count();
        long extendedAsciiCount = MOJIBAKE_CHAR_PATTERN.matcher(trimmedContent).results().count();

        // 2. 逻辑校验
        
        // 规则 A：乱码特征检测
        // 如果拉丁扩展字符（Mojibake 常见成分）的数量远多于中文字符，极有可能是乱码
        // 正常文本中偶尔会出现少量这类字符（如单位符号），但乱码会成倍出现
        if (extendedAsciiCount > 10 && extendedAsciiCount > chineseCount) {
            return false;
        }

        // 规则 B：中文占比校验
        // 正常的分析结果必须包含中文。考虑到 JSON 结构的干扰，设置极低的阈值以防误杀。
        if (length > 100) {
            double chineseRatio = (double) chineseCount / length;
            // 只要有 1% 的中文字符就放行，主要为了拦截完全乱码或纯英文结果
            if (chineseRatio < 0.01) {
                return false;
            }
        } else if (length > 5) {
            // 短内容必须包含至少一个中文字符
            if (chineseCount < 1) {
                return false;
            }
        }

        return true;
    }
}
