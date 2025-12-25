package com.nullworking.util;

import org.springframework.util.StringUtils;

import java.util.regex.Pattern;

/**
 * 文本内容验证工具类，用于检测乱码和无效内容
 */
public class ContentValidationUtil {

    // 识别有效中文字符的正则
    private static final Pattern CHINESE_CHAR_PATTERN = Pattern.compile("[\u4e00-\u9fa5]");
    
    // 识别典型 Mojibake (UTF-8 bytes misread as ISO-8859-1) 的正则
    // 常见的乱码起始字符：æ, ç, å, é, è, ï, ¼, ,  等连续出现
    private static final Pattern MOJIBAKE_PATTERN = Pattern.compile("[æçåéèï][¼ï»¼]{2,}");

    /**
     * 验证AI分析结果是否有效（无乱码）
     * 改进：结合 Mojibake 特征检测与中文占比校验，精准拦截编码错误。
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

        // 1. 结构化特征：如果内容包含明显的 Mojibake 连续序列，直接判定为乱码
        // 这里要求至少出现两次连续的乱码特征，以减少对包含欧洲语言字符（如 æ）的正常文本的误杀
        if (MOJIBAKE_PATTERN.matcher(trimmedContent).results().count() >= 2) {
            return false;
        }

        // 2. 中文存在性与占比判断
        boolean isJson = trimmedContent.startsWith("{") && trimmedContent.endsWith("}");
        long chineseCount = CHINESE_CHAR_PATTERN.matcher(trimmedContent).results().count();
        
        if (length > 100) {
            double chineseRatio = (double) chineseCount / length;
            // 正常的 AI 分析结果即便包含大量 JSON 结构，中文描述也会超过一定的底线
            double threshold = isJson ? 0.08 : 0.15;
            if (chineseRatio < threshold) {
                return false;
            }
        } else if (length > 10) {
            // 中等长度内容必须包含至少一个中文字符
            if (chineseCount < 1) {
                return false;
            }
        }

        return true;
    }
}
