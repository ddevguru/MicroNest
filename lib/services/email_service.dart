import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class EmailService {
  // SMTP2GO Configuration
  static const String smtp2goApiKey = 'api-5C5BC5F363E84C4D9C9302E57F873F57'; // Replace with your actual API key
  static const String smtp2goEndpoint = 'https://api.smtp2go.com/v3/email/send';
  static const String fromEmail = '121deepak2104@sjcem.edu.in'; // Replace with your verified sender email
  static const String fromName = 'MicroNest';
  
  // Generate a random 6-digit OTP
  static String generateOTP() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  // Send email OTP
  static Future<Map<String, dynamic>> sendEmailOTP(String toEmail, String otp) async {
    try {
      final emailData = {
        'api_key': smtp2goApiKey,
        'to': [toEmail],
        'sender': fromEmail,
        'subject': 'MicroNest - Email Verification OTP',
        'html_body': _generateOTPEmailHTML(otp),
        'text_body': _generateOTPEmailText(otp),
        'custom_headers': [
          {
            'header': 'Reply-To',
            'value': fromEmail
          }
        ]
      };

      final response = await http.post(
        Uri.parse(smtp2goEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data']['succeeded'] == 1) {
          return {
            'success': true,
            'message': 'OTP sent successfully',
            'otp': otp,
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to send email: ${responseData['data']?['error'] ?? 'Unknown error'}',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Send welcome email
  static Future<Map<String, dynamic>> sendWelcomeEmail(String toEmail, String fullName) async {
    try {
      final emailData = {
        'api_key': smtp2goApiKey,
        'to': [toEmail],
        'sender': fromEmail,
        'subject': 'Welcome to MicroNest!',
        'html_body': _generateWelcomeEmailHTML(fullName),
        'text_body': _generateWelcomeEmailText(fullName),
        'custom_headers': [
          {
            'header': 'Reply-To',
            'value': fromEmail
          }
        ]
      };

      final response = await http.post(
        Uri.parse(smtp2goEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data']['succeeded'] == 1) {
          return {
            'success': true,
            'message': 'Welcome email sent successfully',
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to send welcome email: ${responseData['data']?['error'] ?? 'Unknown error'}',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Send password reset email
  static Future<Map<String, dynamic>> sendPasswordResetEmail(String toEmail, String resetToken) async {
    try {
      final resetLink = 'https://micronest.devloperwala.in/reset-password?token=$resetToken';
      
      final emailData = {
        'api_key': smtp2goApiKey,
        'to': [toEmail],
        'sender': fromEmail,
        'subject': 'MicroNest - Password Reset Request',
        'html_body': _generatePasswordResetEmailHTML(resetLink),
        'text_body': _generatePasswordResetEmailText(resetLink),
        'custom_headers': [
          {
            'header': 'Reply-To',
            'value': fromEmail
          }
        ]
      };

      final response = await http.post(
        Uri.parse(smtp2goEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data']['succeeded'] == 1) {
          return {
            'success': true,
            'message': 'Password reset email sent successfully',
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to send password reset email: ${responseData['data']?['error'] ?? 'Unknown error'}',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Generate HTML email template for OTP
  static String _generateOTPEmailHTML(String otp) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Email Verification - MicroNest</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #52B788, #40916C); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .otp-box { background: #52B788; color: white; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0; font-size: 24px; font-weight: bold; letter-spacing: 5px; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>μN</h1>
                <h2>Email Verification</h2>
            </div>
            <div class="content">
                <p>Hello!</p>
                <p>Thank you for signing up with MicroNest. To complete your registration, please use the verification code below:</p>
                
                <div class="otp-box">$otp</div>
                
                <p>This code will expire in 10 minutes for security reasons.</p>
                <p>If you didn't request this verification, please ignore this email.</p>
                
                <p>Best regards,<br>The MicroNest Team</p>
            </div>
            <div class="footer">
                <p>© 2024 MicroNest. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Generate text email template for OTP
  static String _generateOTPEmailText(String otp) {
    return '''
Email Verification - MicroNest

Hello!

Thank you for signing up with MicroNest. To complete your registration, please use the verification code below:

$otp

This code will expire in 10 minutes for security reasons.

If you didn't request this verification, please ignore this email.

Best regards,
The MicroNest Team

© 2024 MicroNest. All rights reserved.
    ''';
  }

  // Generate HTML email template for welcome email
  static String _generateWelcomeEmailHTML(String fullName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to MicroNest!</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #52B788, #40916C); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .feature { background: white; padding: 20px; margin: 15px 0; border-radius: 8px; border-left: 4px solid #52B788; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>μN</h1>
                <h2>Welcome to MicroNest!</h2>
            </div>
            <div class="content">
                <p>Hello $fullName!</p>
                <p>Welcome to MicroNest! Your account has been successfully created and verified.</p>
                
                <div class="feature">
                    <h3>🚀 What's Next?</h3>
                    <p>• Complete your profile setup<br>
                    • Join or create savings groups<br>
                    • Start building your financial future</p>
                </div>
                
                <div class="feature">
                    <h3>🔒 Your Account is Secure</h3>
                    <p>• Email verified successfully<br>
                    • Password encrypted and secure<br>
                    • Two-factor authentication available</p>
                </div>
                
                <p>Ready to get started? Log in to your account and explore the features!</p>
                
                <p>Best regards,<br>The MicroNest Team</p>
            </div>
            <div class="footer">
                <p>© 2024 MicroNest. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Generate text email template for welcome email
  static String _generateWelcomeEmailText(String fullName) {
    return '''
Welcome to MicroNest!

Hello $fullName!

Welcome to MicroNest! Your account has been successfully created and verified.

What's Next?
• Complete your profile setup
• Join or create savings groups
• Start building your financial future

Your Account is Secure
• Email verified successfully
• Password encrypted and secure
• Two-factor authentication available

Ready to get started? Log in to your account and explore the features!

Best regards,
The MicroNest Team

© 2024 MicroNest. All rights reserved.
    ''';
  }

  // Generate HTML email template for password reset
  static String _generatePasswordResetEmailHTML(String resetLink) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset - MicroNest</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #52B788, #40916C); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .reset-button { background: #52B788; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>μN</h1>
                <h2>Password Reset Request</h2>
            </div>
            <div class="content">
                <p>Hello!</p>
                <p>We received a request to reset your MicroNest account password. Click the button below to create a new password:</p>
                
                <a href="$resetLink" class="reset-button">Reset Password</a>
                
                <p>If the button doesn't work, copy and paste this link into your browser:</p>
                <p>$resetLink</p>
                
                <p>This link will expire in 1 hour for security reasons.</p>
                <p>If you didn't request a password reset, please ignore this email and your password will remain unchanged.</p>
                
                <p>Best regards,<br>The MicroNest Team</p>
            </div>
            <div class="footer">
                <p>© 2024 MicroNest. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Generate text email template for password reset
  static String _generatePasswordResetEmailText(String resetLink) {
    return '''
Password Reset - MicroNest

Hello!

We received a request to reset your MicroNest account password. Click the link below to create a new password:

$resetLink

This link will expire in 1 hour for security reasons.

If you didn't request a password reset, please ignore this email and your password will remain unchanged.

Best regards,
The MicroNest Team

© 2024 MicroNest. All rights reserved.
    ''';
  }
} 