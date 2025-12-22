package com.nullworking.util;

import org.springframework.util.StringUtils;

import java.util.regex.Pattern;

/**
 * 文本内容验证工具类，用于检测乱码和无效内容
 */
public class ContentValidationUtil {

    // 检测常见UTF-8解码错误导致的乱码（如ç»¼å等特征字符）
    private static final Pattern GARBAGE_CHAR_PATTERN = Pattern.compile("[çåèï¼ï¼ï¼ãã]+");
    
    // 检测有效中文字符占比过低的情况
    private static final Pattern CHINESE_CHAR_PATTERN = Pattern.compile("[\u4e00-\u9fa5]");

    /**
     * 验证AI分析结果是否有效（无乱码）
     * @param content 分析结果内容
     * @return 有效返回true，无效返回false
     */
    public static boolean isValidAnalysisContent(String content) {
        if (!StringUtils.hasText(content)) {
            return false;
        }

        // 规则1：检测是否包含典型乱码字符
        if (GARBAGE_CHAR_PATTERN.matcher(content).find()) {
            return false;
        }

        // 规则2：确保中文占比不低于30%（过滤大部分乱码情况）
        int chineseCount = CHINESE_CHAR_PATTERN.matcher(content).results().toList().size();
        double chineseRatio = (double) chineseCount / content.length();
        if (chineseRatio < 0.3) {
            return false;
        }

        return true;
    }
}