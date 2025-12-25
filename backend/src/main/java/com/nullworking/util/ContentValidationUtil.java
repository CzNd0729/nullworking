package com.nullworking.util;

import org.springframework.util.StringUtils;

import java.util.regex.Pattern;

/**
 * 文本内容验证工具类，用于检测乱码和无效内容
 */
public class ContentValidationUtil {

    // 检测常见UTF-8解码错误导致的乱码（如ç»¼å等特征字符）
    // 改进：增加更精确的乱码特征组合，避免误杀单个有效特殊字符
    private static final Pattern GARBAGE_CHAR_PATTERN = Pattern.compile("(ç[»¼åèè])|(å[])|(ï¼[ï])");
    
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

        // 规则1：检测是否包含典型乱码特征（Mojibake）
        // 改进：使用 find() 时增加对乱码片段长度的判断，或者使用更精确的正则
        if (GARBAGE_CHAR_PATTERN.matcher(content).find()) {
            return false;
        }

        // 规则2：确保中文占比（过滤大部分乱码情况）
        // 改进：对于技术分析文档，JSON 结构占比较大，中文比例会显著下降。
        // 同时，对于极短的内容（如仅包含成功/失败字样），不应过分强调占比。
        if (content.length() > 50) {
            int chineseCount = (int) CHINESE_CHAR_PATTERN.matcher(content).results().count();
            double chineseRatio = (double) chineseCount / content.length();
            
            // 如果是 JSON 格式（通常以 { 开头），阈值进一步降低
            double threshold = content.trim().startsWith("{") ? 0.1 : 0.2;
            
            if (chineseRatio < threshold) {
                return false;
            }
        }

        return true;
    }
}
