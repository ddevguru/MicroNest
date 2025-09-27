<?php
class EmailService {
    public static function sendOTP($email, $otp, $fullName = '') {
        $subject = 'Your MicroNest Verification Code';
        $htmlContent = self::getOTPEmailTemplate($otp, $fullName);
        
        return self::sendEmail($email, $subject, $htmlContent);
    }

    private static function sendEmail($to, $subject, $htmlContent) {
        $data = [
            'api_key' => SMTP2GO_API_KEY,
            'to' => [$to],
            'sender' => FROM_EMAIL,
            'subject' => $subject,
            'html_body' => $htmlContent,
            'text_body' => strip_tags($htmlContent)
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, SMTP2GO_API_URL);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'X-Smtp2go-Api-Key: ' . SMTP2GO_API_KEY
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode === 200) {
            $result = json_decode($response, true);
            return $result['data']['succeeded'] > 0;
        }

        error_log("Email sending failed: HTTP $httpCode - $response");
        return false;
    }

    private static function getOTPEmailTemplate($otp, $fullName) {
        return "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='utf-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>Email Verification - MicroNest</title>
        </head>
        <body style='margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f4f4f4;'>
            <div style='max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 20px;'>
                <div style='text-align: center; padding: 20px 0; background: linear-gradient(135deg, #1B4332, #2D6A4F); border-radius: 10px; margin-bottom: 30px;'>
                    <h1 style='color: #ffffff; margin: 0; font-size: 28px; font-weight: bold;'>μN MicroNest</h1>
                    <p style='color: #95D5B2; margin: 10px 0 0 0; font-size: 16px;'>Email Verification</p>
                </div>
                
                <div style='padding: 0 20px;'>
                    <h2 style='color: #1B4332; margin-bottom: 20px;'>Hello" . ($fullName ? " $fullName" : "") . "!</h2>
                    
                    <p style='color: #333333; font-size: 16px; line-height: 1.6; margin-bottom: 25px;'>
                        Thank you for signing up with MicroNest! To complete your registration, please verify your email address using the verification code below:
                    </p>
                    
                    <div style='text-align: center; margin: 30px 0;'>
                        <div style='background: linear-gradient(135deg, #52B788, #40916C); color: white; font-size: 32px; font-weight: bold; padding: 20px; border-radius: 10px; letter-spacing: 8px; display: inline-block; box-shadow: 0 4px 15px rgba(82, 183, 136, 0.3);'>
                            $otp
                        </div>
                    </div>
                    
                    <p style='color: #666666; font-size: 14px; line-height: 1.6; margin-bottom: 20px;'>
                        This verification code will expire in 5 minutes for security reasons. If you didn't request this verification, please ignore this email.
                    </p>
                    
                    <div style='background-color: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #52B788; margin: 20px 0;'>
                        <p style='color: #495057; margin: 0; font-size: 14px;'>
                            <strong>Security Tip:</strong> Never share this code with anyone. MicroNest will never ask for your verification code via phone or email.
                        </p>
                    </div>
                </div>
                
                <div style='text-align: center; padding: 30px 20px; border-top: 1px solid #e9ecef; margin-top: 40px;'>
                    <p style='color: #6c757d; font-size: 14px; margin: 0;'>
                        Best regards,<br>
                        <strong style='color: #1B4332;'>The MicroNest Team</strong>
                    </p>
                    
                    <div style='margin-top: 20px;'>
                        <p style='color: #adb5bd; font-size: 12px; margin: 0;'>
                            This is an automated message, please do not reply to this email.
                        </p>
                    </div>
                </div>
            </div>
        </body>
        </html>";
    }
}
?>
