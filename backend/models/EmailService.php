<?php

class EmailService {
    private $smtp2goApiKey;
    private $smtp2goApiUrl;
    private $fromEmail;
    private $fromName;
    
    public function __construct() {
        // SMTP2GO Configuration - Update these with your actual credentials
        $this->smtp2goApiKey = 'api-XXXXXXXXXXXX'; // Replace with your actual SMTP2GO API key
        $this->smtp2goApiUrl = 'https://api.smtp2go.com/v3/email/send';
        $this->fromEmail = 'noreply@micronest.com';
        $this->fromName = 'MicroNest';
        
        // For development/testing, you can also use environment variables
        if (getenv('SMTP2GO_API_KEY')) {
            $this->smtp2goApiKey = getenv('SMTP2GO_API_KEY');
        }
        if (getenv('SMTP2GO_FROM_EMAIL')) {
            $this->fromEmail = getenv('SMTP2GO_FROM_EMAIL');
        }
    }
    
    /**
     * Send email using SMTP2GO
     */
    public function sendEmail($to, $subject, $htmlBody, $textBody = null) {
        try {
            if (empty($this->smtp2goApiKey) || $this->smtp2goApiKey === 'YOUR_SMTP2GO_API_KEY') {
                // For testing purposes, log the email instead of sending
                error_log("Email would be sent to: $to");
                error_log("Subject: $subject");
                error_log("HTML Body: $htmlBody");
                return [
                    'success' => true,
                    'message' => 'Email logged (SMTP2GO not configured)',
                    'to' => $to,
                    'subject' => $subject
                ];
            }
            
            $emailData = [
                'api_key' => $this->smtp2goApiKey,
                'to' => [$to],
                'sender' => $this->fromEmail,
                'subject' => $subject,
                'html_body' => $htmlBody,
                'text_body' => $textBody ?: strip_tags($htmlBody)
            ];
            
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $this->smtp2goApiUrl);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($emailData));
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                'Accept: application/json'
            ]);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);
            curl_close($ch);
            
            if ($error) {
                throw new Exception("cURL Error: $error");
            }
            
            if ($httpCode !== 200) {
                throw new Exception("SMTP2GO API returned HTTP $httpCode: $response");
            }
            
            $result = json_decode($response, true);
            
            if (isset($result['data']['succeeded']) && $result['data']['succeeded'] > 0) {
                return [
                    'success' => true,
                    'message' => 'Email sent successfully',
                    'to' => $to,
                    'subject' => $subject
                ];
            } else {
                throw new Exception("SMTP2GO API error: " . json_encode($result));
            }
            
        } catch (Exception $e) {
            error_log("EmailService Error: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Failed to send email: ' . $e->getMessage(),
                'to' => $to,
                'subject' => $subject
            ];
        }
    }
    
    /**
     * Send OTP email
     */
    public function sendOtpEmail($email, $fullName, $otp) {
        $subject = 'MicroNest - Email Verification OTP';
        $htmlBody = $this->generateOtpEmailHTML($fullName, $otp);
        $textBody = $this->generateOtpEmailText($fullName, $otp);
        
        return $this->sendEmail($email, $subject, $htmlBody, $textBody);
    }
    
    /**
     * Generate HTML email template for OTP
     */
    private function generateOtpEmailHTML($fullName, $otp) {
        return "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>Email Verification OTP</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .otp-box { background: #fff; border: 2px solid #667eea; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0; }
                .otp-code { font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 5px; }
                .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h1>MicroNest</h1>
                    <p>Email Verification</p>
                </div>
                <div class='content'>
                    <h2>Hello $fullName!</h2>
                    <p>Thank you for signing up with MicroNest. To complete your registration, please use the following verification code:</p>
                    
                    <div class='otp-box'>
                        <div class='otp-code'>$otp</div>
                        <p><strong>This code will expire in 10 minutes.</strong></p>
                    </div>
                    
                    <p>If you didn't request this verification, please ignore this email.</p>
                    
                    <p>Best regards,<br>The MicroNest Team</p>
                </div>
                <div class='footer'>
                    <p>This is an automated message, please do not reply to this email.</p>
                </div>
            </div>
        </body>
        </html>
        ";
    }
    
    /**
     * Generate plain text email template for OTP
     */
    private function generateOtpEmailText($fullName, $otp) {
        return "
MicroNest - Email Verification OTP

Hello $fullName!

Thank you for signing up with MicroNest. To complete your registration, please use the following verification code:

OTP: $otp

This code will expire in 10 minutes.

If you didn't request this verification, please ignore this email.

Best regards,
The MicroNest Team

---
This is an automated message, please do not reply to this email.
        ";
    }
    
    /**
     * Send welcome email
     */
    public function sendWelcomeEmail($email, $fullName) {
        $subject = 'Welcome to MicroNest!';
        $htmlBody = $this->generateWelcomeEmailHTML($fullName);
        $textBody = $this->generateWelcomeEmailText($fullName);
        
        return $this->sendEmail($email, $subject, $htmlBody, $textBody);
    }
    
    /**
     * Generate HTML email template for welcome email
     */
    private function generateWelcomeEmailHTML($fullName) {
        return "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>Welcome to MicroNest</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .welcome-box { background: #fff; border: 2px solid #667eea; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0; }
                .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h1>MicroNest</h1>
                    <p>Welcome Aboard!</p>
                </div>
                <div class='content'>
                    <h2>Welcome to MicroNest, $fullName!</h2>
                    
                    <div class='welcome-box'>
                        <p>🎉 Your account has been successfully created and verified!</p>
                        <p>You can now access all the features of MicroNest and start building your financial future.</p>
                    </div>
                    
                    <p>Here's what you can do next:</p>
                    <ul>
                        <li>Complete your profile</li>
                        <li>Join or create savings groups</li>
                        <li>Start contributing to build your savings</li>
                        <li>Apply for loans when needed</li>
                    </ul>
                    
                    <p>If you have any questions, feel free to contact our support team.</p>
                    
                    <p>Best regards,<br>The MicroNest Team</p>
                </div>
                <div class='footer'>
                    <p>This is an automated message, please do not reply to this email.</p>
                </div>
            </div>
        </body>
        </html>
        ";
    }
    
    /**
     * Generate plain text email template for welcome email
     */
    private function generateWelcomeEmailText($fullName) {
        return "
Welcome to MicroNest!

Hello $fullName!

🎉 Your account has been successfully created and verified!

You can now access all the features of MicroNest and start building your financial future.

Here's what you can do next:
- Complete your profile
- Join or create savings groups
- Start contributing to build your savings
- Apply for loans when needed

If you have any questions, feel free to contact our support team.

Best regards,
The MicroNest Team

---
This is an automated message, please do not reply to this email.
        ";
    }
    
    /**
     * Set SMTP2GO API key
     */
    public function setApiKey($apiKey) {
        $this->smtp2goApiKey = $apiKey;
    }
    
    /**
     * Set sender email
     */
    public function setFromEmail($email) {
        $this->fromEmail = $email;
    }
    
    /**
     * Set sender name
     */
    public function setFromName($name) {
        $this->fromName = $name;
    }
}
?> 