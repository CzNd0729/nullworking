package com.nullworking.util;

import java.util.Random;
import java.util.concurrent.locks.ReentrantLock;

/**
 * 短码生成工具类
 * 生成6位唯一、无易混淆字符的短码，解决并发重复问题
 */
public class ShortCodeGenerator {
    // 字符池：排除0/O、1/I等易混淆字符，降低用户输入错误率
    private static final String CHAR_POOL = "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjklmnpqrstuvwxyz";
    private static final int CODE_LENGTH = 6; // 6位短码
    private static final ReentrantLock LOCK = new ReentrantLock(); // 防并发重复
    private static final Random RANDOM = new Random();

    /**
     * 生成唯一短码（加锁保证并发安全）
     */
    public static String generate() {
        LOCK.lock();
        try {
            StringBuilder sb = new StringBuilder(CODE_LENGTH);
            for (int i = 0; i < CODE_LENGTH; i++) {
                sb.append(CHAR_POOL.charAt(RANDOM.nextInt(CHAR_POOL.length())));
            }
            return sb.toString();
        } finally {
            LOCK.unlock(); // 确保锁释放
        }
    }
}