package com.nullworking.service;

import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class VerificationCodeService {

    private static class CodeEntry {
        String code;
        Instant expireAt;
        CodeEntry(String code, Instant expireAt) { this.code = code; this.expireAt = expireAt; }
    }

    private final Map<String, CodeEntry> codes = new ConcurrentHashMap<>();

    @Value("${app.verification.code.expire-minutes:10}") int expireMinutes;

    public int getExpireMinutes() {
        return expireMinutes;
    }

    private final SecureRandom random = new SecureRandom();

    public String generateCode(String email) {
        String code = String.format("%06d", random.nextInt(1_000_000));
        Instant expireAt = Instant.now().plus(expireMinutes, ChronoUnit.MINUTES);
        codes.put(email, new CodeEntry(code, expireAt));
        return code;
    }

    public boolean verifyCode(String email, String code) {
        CodeEntry entry = codes.get(email);
        if (entry == null) return false;
        if (Instant.now().isAfter(entry.expireAt)) {
            codes.remove(email);
            return false;
        }
        boolean ok = entry.code.equals(code);
        if (ok) {
            codes.remove(email);
        }
        return ok;
    }
}
