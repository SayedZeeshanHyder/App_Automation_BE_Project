package com.flutomapp.app.service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.mail.javamail.*;
import org.springframework.stereotype.Service;

import jakarta.mail.internet.MimeMessage;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String userName;
    private Environment env;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendVerificationEmail(String toEmail, String code) {
        String subject = "Zapp Verification Code";
        String body = "<h2>Your Verification Code</h2><p>Use the code below to verify your account:</p>" +
                "<h3>" + code + "</h3>";

        sendHtmlEmail(toEmail, subject, body);
    }

    public void sendWelcomeEmail(String toEmail, String username) {
        String subject = "Welcome to Our App!";
        String body = "<h2>Hi " + username + ",</h2><p>Welcome to our app! We're glad to have you.</p>";
        sendHtmlEmail(toEmail, subject, body);
    }

    public void sendCustomEmail(String toEmail, String subject, String messageBody) {
        sendHtmlEmail(toEmail, subject, messageBody);
    }

    public void sendEmailWithButton(String toEmail, String buttonText, String deepLinkUrl) {
        String subject = "Action Required";
        String body = "<p>Please click the button below to proceed:</p>" +
                "<a href=\"" + deepLinkUrl + "\" " +
                "style=\"background-color:#28a745;color:white;padding:10px 20px;text-decoration:none;border-radius:5px;\">" +
                buttonText + "</a>";

        sendHtmlEmail(toEmail, subject, body);
    }

    private void sendHtmlEmail(String to, String subject, String htmlBody) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(userName);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlBody, true);

            mailSender.send(message);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
