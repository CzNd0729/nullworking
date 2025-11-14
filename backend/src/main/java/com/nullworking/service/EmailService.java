package com.nullworking.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.internet.MimeMessage;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    // SMTP 授权使用的邮箱（用于 envelope MAIL FROM）
    @Value("${spring.mail.username:}")
    private String mailUsername;

    // 收件端显示的发件名称
    @Value("${app.mail.from:NullWorking}")
    private String fromDisplayName;

    /**
     * 发送简单文本邮件，收件方看到的发件人为：NullWorking <授权邮箱>
     * 实现策略：
     *  - SMTP envelope 使用授权邮箱（由 spring.mail.properties.mail.smtp.from 控制或 mailUsername）以避免 501 错误
     *  - 通过 helper.setFrom(envelope, personal) + 设置 header From 来让客户端显示为 NullWorking <授权邮箱>
     */
    public void sendSimpleMail(String to, String subject, String text) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, "UTF-8");

            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(text, false);

            // 优先使用授权邮箱作为 envelope 发件人
            String envelopeFrom = (mailUsername != null && !mailUsername.isEmpty()) ? mailUsername : null;

            if (envelopeFrom != null) {
                try {
                    helper.setFrom(envelopeFrom, fromDisplayName != null ? fromDisplayName : envelopeFrom);
                } catch (Exception ex) {
                    // 回退为不带显示名的 from
                    helper.setFrom(envelopeFrom);
                }

                // 同时设置邮件头 From，确保收件端显示格式为：NullWorking <授权邮箱>
                try {
                    String headerFrom = String.format("%s <%s>", (fromDisplayName != null ? fromDisplayName : ""), envelopeFrom);
                    message.setHeader("From", headerFrom);
                } catch (Exception ignored) {
                }
            }

            mailSender.send(message);
        } catch (Exception e) {
            throw new RuntimeException("发送邮件失败: " + e.getMessage(), e);
        }
    }
}
