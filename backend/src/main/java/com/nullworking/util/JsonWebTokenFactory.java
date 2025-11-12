package com.nullworking.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import io.jsonwebtoken.*;
import io.jsonwebtoken.lang.Maps;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.interfaces.RSAPrivateKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import java.util.Map;

public class JsonWebTokenFactory {

    // 实际开发时请将公网地址存储在配置文件或数据库
    private static final String AUD = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";

    public static String createJwt() throws NoSuchAlgorithmException, InvalidKeySpecException, IOException, NullPointerException {
        // 读取配置文件
        ObjectMapper mapper = new ObjectMapper();
        // 上述private.json文件放置于工程的src/main/resources路径下
        URL url = JsonWebTokenFactory.class.getClassLoader().getResource("private.json");
        if (url == null) {
            throw new NullPointerException("File not exist");
        }
        JsonNode rootNode = mapper.readTree(new File(url.getPath()));

        RSAPrivateKey privateKey = (RSAPrivateKey) generatePrivateKey(rootNode.get("private_key").asText()
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", ""));
        long iat = System.currentTimeMillis() / 1000;
        long exp = iat + 3600;

        Map<String, Object> header = Maps.<String, Object>of(JwsHeader.KEY_ID, rootNode.get("key_id").asText())
                .and(JwsHeader.TYPE, JwsHeader.JWT_TYPE)
                .and(JwsHeader.ALGORITHM, SignatureAlgorithm.PS256.getValue())
                .build();

        Map<String, Object> payload = Maps.<String, Object>of(Claims.ISSUER, rootNode.get("sub_account").asText())
                .and(Claims.ISSUED_AT, iat)
                .and(Claims.EXPIRATION, exp)
                .and(Claims.AUDIENCE, AUD)
                .build();

        return Jwts.builder()
                .setHeader(header)
                .setPayload(new ObjectMapper().writeValueAsString(payload))
                .signWith(privateKey, SignatureAlgorithm.PS256)
                .compact();
    }

    private static PrivateKey generatePrivateKey(String base64Key) throws NoSuchAlgorithmException, InvalidKeySpecException {
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(Base64.getDecoder().decode(base64Key.getBytes(StandardCharsets.UTF_8)));
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        return keyFactory.generatePrivate(keySpec);
    }

    public static void main(String[] args) {
        try {
            // 获取鉴权令牌
            String jwt = createJwt();
        } catch (NoSuchAlgorithmException e) {
            // 异常处理流程1
        } catch (InvalidKeySpecException e) {
            // 异常处理流程2
        } catch (IOException e) {
            // 异常处理流程3
        } catch (NullPointerException e) {
            // 异常处理流程4
        }
    }
}
