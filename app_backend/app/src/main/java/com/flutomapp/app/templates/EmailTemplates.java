package com.flutomapp.app.templates;

public class EmailTemplates {

    public static String joinRequestTemplate(String organisationName, String userName, String role, String email) {
        return "<div style=\"font-family: Arial, sans-serif; font-size: 16px; color: #333;\">" +
                "<h2 style=\"color: #2c3e50;\">New Join Request</h2>" +
                "<p><strong>" + userName + "</strong> has requested to join your organisation <strong>" + organisationName + "</strong>.</p>" +
                "<table style=\"border-collapse: collapse; width: 100%; margin-top: 20px;\">" +
                "  <tr style=\"background-color: #f2f2f2;\">" +
                "    <th style=\"padding: 10px; text-align: left; border: 1px solid #ddd;\">Field</th>" +
                "    <th style=\"padding: 10px; text-align: left; border: 1px solid #ddd;\">Details</th>" +
                "  </tr>" +
                "  <tr><td style=\"padding: 10px; border: 1px solid #ddd;\">Username</td><td style=\"padding: 10px; border: 1px solid #ddd;\">" + userName + "</td></tr>" +
                "  <tr><td style=\"padding: 10px; border: 1px solid #ddd;\">Email</td><td style=\"padding: 10px; border: 1px solid #ddd;\">" + email + "</td></tr>" +
                "  <tr><td style=\"padding: 10px; border: 1px solid #ddd;\">Role</td><td style=\"padding: 10px; border: 1px solid #ddd;\">" + role + "</td></tr>" +
                "</table>" +
                "<p style=\"margin-top: 20px;\">Please log in to your dashboard to accept or reject the request.</p>" +
                "</div>";
    }

    public static String joinRequestApprovedTemplate(String organisationName, String userName, String ownerName) {
        return "<div style=\"font-family: Arial, sans-serif; font-size: 16px; color: #333;\">" +
                "<h2 style=\"color: #2c3e50;\">Join Request Approved</h2>" +
                "<p>Hi <strong>" + userName + "</strong>,</p>" +
                "<p>Your request to join the organisation <strong>" + organisationName + "</strong> has been approved by <strong>" + ownerName + "</strong>.</p>" +
                "<p style=\"margin-top: 20px;\">You now have access to the organisation's resources. Please log in to continue.</p>" +
                "</div>";
    }
}
