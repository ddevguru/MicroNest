<?php
require_once '../config/database.php';
require_once '../utils/JWTUtil.php';
require_once '../utils/ResponseUtil.php';
require_once '../models/EmailService.php';

class Auth {
    private $conn;
    private $jwtUtil;
    private $emailService;
    
    public function __construct() {
        $database = new Database();
        $this->conn = $database->getConnection();
        $this->jwtUtil = new JWTUtil();
        $this->emailService = new EmailService();
    }
    
    public function login($email, $password) {
        try {
            error_log("=== LOGIN START ===");
            error_log("Email: $email");
            
            // Check if user exists and email is verified
            $query = "SELECT id, full_name, email, username, password_hash, email_verified, status, trust_score 
                     FROM users WHERE email = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$email]);
            
            if ($stmt->rowCount() == 0) {
                error_log("User not found or inactive");
                return ResponseUtil::error('Invalid email or password', 401);
            }
            
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            error_log("User found: " . json_encode($user));
            
            // Check if email is verified
            if (!$user['email_verified']) {
                error_log("Email not verified for user: " . $user['id']);
                return ResponseUtil::error('Please verify your email first', 401);
            }
            
            error_log("Email verified, checking password");
            
            // Verify password
            if (!password_verify($password, $user['password_hash'])) {
                error_log("Invalid password for user: " . $user['id']);
                return ResponseUtil::error('Invalid email or password', 401);
            }
            
            error_log("Password verified, generating tokens");
            
            // Generate JWT tokens
            $accessToken = $this->jwtUtil->generateAccessToken($user['id']);
            $refreshToken = $this->jwtUtil->generateRefreshToken($user['id']);
            
            // Store refresh token in database
            $this->storeRefreshToken($user['id'], $refreshToken);
            
            // Remove sensitive data and ensure all fields are strings
            unset($user['password_hash']);
            
            // Ensure all user data fields are properly formatted (no null values)
            $cleanUser = [
                'id' => (string)$user['id'],
                'full_name' => $user['full_name'] ?? '',
                'email' => $user['email'] ?? '',
                'username' => $user['username'] ?? '',
                'phone' => $user['phone'] ?? '',
                'address' => $user['address'] ?? '',
                'profile_image' => $user['profile_image'] ?? '',
                'email_verified' => (bool)$user['email_verified'],
                'email_verified_at' => $user['email_verified_at'] ?? null,
                'status' => $user['status'] ?? 'active',
                'trust_score' => (float)($user['trust_score'] ?? 0.0),
                'created_at' => $user['created_at'] ?? null,
                'updated_at' => $user['updated_at'] ?? null
            ];
            
            error_log("=== LOGIN SUCCESS ===");
            error_log("Clean user data: " . json_encode($cleanUser));
            
            return ResponseUtil::success('Login successful', [
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'user' => $cleanUser
            ]);
            
        } catch (Exception $e) {
            error_log("=== LOGIN ERROR ===");
            error_log("Error: " . $e->getMessage());
            return ResponseUtil::error('Login failed: ' . $e->getMessage(), 500);
        }
    }
    
    public function signup($data) {
        try {
            // Validate required fields
            $requiredFields = ['full_name', 'email', 'username', 'password', 'phone', 'address'];
            foreach ($requiredFields as $field) {
                if (empty($data[$field])) {
                    return ResponseUtil::error("Field '$field' is required", 400);
                }
            }
            
            // Check if email already exists
            $query = "SELECT id FROM users WHERE email = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['email']]);
            
            if ($stmt->rowCount() > 0) {
                return ResponseUtil::error('Email already registered', 400);
            }
            
            // Check if username already exists
            $query = "SELECT id FROM users WHERE username = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['username']]);
            
            if ($stmt->rowCount() > 0) {
                return ResponseUtil::error('Username already taken', 400);
            }
            
            // Check if email was verified through OTP (recently used, within last 30 minutes)
            error_log("=== SIGNUP OTP CHECK ===");
            error_log("Checking OTP verification for email: " . $data['email']);
            
            $query = "SELECT id FROM email_otps WHERE email = ? AND used = TRUE AND used_at > DATE_SUB(NOW(), INTERVAL 30 MINUTE)";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['email']]);
            
            error_log("OTP verification query: " . $query);
            error_log("OTP verification result count: " . $stmt->rowCount());
            
            if ($stmt->rowCount() == 0) {
                // Debug: Check what OTPs exist for this email
                $debugQuery = "SELECT * FROM email_otps WHERE email = ? ORDER BY created_at DESC LIMIT 3";
                $debugStmt = $this->conn->prepare($debugQuery);
                $debugStmt->execute([$data['email']]);
                $debugResults = $debugStmt->fetchAll(PDO::FETCH_ASSOC);
                
                error_log("OTP verification failed. Available OTPs: " . json_encode($debugResults));
                return ResponseUtil::error('Please verify your email with OTP before signing up. OTP verification must be completed within 30 minutes.', 400);
            }
            
            error_log("OTP verification successful for email: " . $data['email']);
            
            // Hash password
            $passwordHash = password_hash($data['password'], PASSWORD_DEFAULT);
            
            // Insert new user with verified email
            $query = "INSERT INTO users (full_name, email, username, password_hash, phone, address, profile_image, email_verified, email_verified_at) 
                     VALUES (?, ?, ?, ?, ?, ?, ?, TRUE, NOW())";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $data['full_name'],
                $data['email'],
                $data['username'],
                $passwordHash,
                $data['phone'],
                $data['address'],
                $data['profile_image'] ?? null
            ]);
            
            $userId = $this->conn->lastInsertId();
            
            // Get user data
            $query = "SELECT id, full_name, email, username, phone, address, profile_image, email_verified, trust_score 
                     FROM users WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Generate JWT tokens
            $accessToken = $this->jwtUtil->generateAccessToken($userId);
            $refreshToken = $this->jwtUtil->generateRefreshToken($userId);
            
            // Store refresh token
            $this->storeRefreshToken($userId, $refreshToken);
            
            return ResponseUtil::success('Account created successfully', [
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
                'user' => $user
            ]);
            
        } catch (Exception $e) {
            return ResponseUtil::error('Signup failed: ' . $e->getMessage(), 500);
        }
    }
    
    public function sendEmailOTP($email) {
        try {
            error_log("=== SEND OTP START ===");
            error_log("Email: $email");
            
            // Check if user exists
            $query = "SELECT id, full_name FROM users WHERE email = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$email]);
            
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            $fullName = $user ? $user['full_name'] : 'User'; // Use 'User' as default for new signups
            
            error_log("User found: " . ($user ? 'YES' : 'NO'));
            error_log("Full name: $fullName");
            
            // Generate OTP
            $otp = $this->generateOTP();
            error_log("Generated OTP: $otp");
            
            // Fix timezone issue - use UTC time
            $expiresAt = gmdate('Y-m-d H:i:s', strtotime('+10 minutes'));
            error_log("OTP expires at: $expiresAt");
            
            // Delete existing OTPs for this email
            $query = "DELETE FROM email_otps WHERE email = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$email]);
            $deletedCount = $stmt->rowCount();
            error_log("Deleted $deletedCount existing OTPs");
            
            // Store new OTP with current UTC time
            $query = "INSERT INTO email_otps (email, otp, expires_at, created_at) VALUES (?, ?, ?, NOW())";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$email, $otp, $expiresAt]);
            $insertId = $this->conn->lastInsertId();
            error_log("Inserted new OTP with ID: $insertId");
            
            // Send email using EmailService
            $emailResult = $this->emailService->sendOtpEmail($email, $fullName, $otp);
            error_log("Email result: " . json_encode($emailResult));
            
            if (!$emailResult['success']) {
                error_log("Email sending failed: " . $emailResult['message']);
                return ResponseUtil::error('Failed to send OTP email: ' . $emailResult['message'], 500);
            }
            
            error_log("=== SEND OTP SUCCESS ===");
            return ResponseUtil::success('OTP sent successfully');
            
        } catch (Exception $e) {
            error_log("=== SEND OTP ERROR ===");
            error_log("Error: " . $e->getMessage());
            error_log("Stack trace: " . $e->getTraceAsString());
            return ResponseUtil::error('Failed to send OTP: ' . $e->getMessage(), 500);
        }
    }

    public function verifyEmailOTP($email, $otp) {
        try {
            error_log("=== VERIFY OTP START ===");
            error_log("Email: $email");
            error_log("OTP: $otp");
            
            // Fix timezone issue - use UTC time for comparison
            $currentTime = gmdate('Y-m-d H:i:s');
            error_log("Current UTC time: $currentTime");
            
            // First, let's check what OTPs exist for this email
            $debugQuery = "SELECT * FROM email_otps WHERE email = ? ORDER BY created_at DESC LIMIT 5";
            $debugStmt = $this->conn->prepare($debugQuery);
            $debugStmt->execute([$email]);
            $debugResults = $debugStmt->fetchAll(PDO::FETCH_ASSOC);
            error_log("All OTPs for email: " . json_encode($debugResults));
            
            // Check if OTP exists and is valid
            $query = "SELECT id, expires_at, created_at, used FROM email_otps 
                     WHERE email = ? AND otp = ? AND used = FALSE AND expires_at > ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$email, $otp, $currentTime]);
            
            error_log("Query executed: $query");
            error_log("Query parameters: " . json_encode([$email, $otp, $currentTime]));
            error_log("Query result count: " . $stmt->rowCount());
            
            if ($stmt->rowCount() == 0) {
                // Debug: Check what's in the database
                $debugQuery = "SELECT * FROM email_otps WHERE email = ? ORDER BY created_at DESC LIMIT 3";
                $debugStmt = $this->conn->prepare($debugQuery);
                $debugStmt->execute([$email]);
                $debugResults = $debugStmt->fetchAll(PDO::FETCH_ASSOC);
                
                error_log("=== OTP VERIFICATION FAILED ===");
                error_log("OTP Verification Failed for email: $email, OTP: $otp");
                error_log("Current UTC time: $currentTime");
                error_log("Debug results: " . json_encode($debugResults));
                
                // Check if OTP exists but is used
                $usedQuery = "SELECT * FROM email_otps WHERE email = ? AND otp = ? AND used = TRUE";
                $usedStmt = $this->conn->prepare($usedQuery);
                $usedStmt->execute([$email, $otp]);
                if ($usedStmt->rowCount() > 0) {
                    error_log("OTP exists but is already used");
                    return ResponseUtil::error('OTP has already been used. Please request a new one.', 400);
                }
                
                // Check if OTP exists but is expired
                $expiredQuery = "SELECT * FROM email_otps WHERE email = ? AND otp = ? AND expires_at <= ?";
                $expiredStmt = $this->conn->prepare($expiredQuery);
                $expiredStmt->execute([$email, $otp, $currentTime]);
                if ($expiredStmt->rowCount() > 0) {
                    error_log("OTP exists but is expired");
                    return ResponseUtil::error('OTP has expired. Please request a new one.', 400);
                }
                
                // Check if OTP doesn't exist at all
                $existsQuery = "SELECT * FROM email_otps WHERE email = ? AND otp = ?";
                $existsStmt = $this->conn->prepare($existsQuery);
                $existsStmt->execute([$email, $otp]);
                if ($existsStmt->rowCount() == 0) {
                    error_log("OTP does not exist for this email");
                    return ResponseUtil::error('Invalid OTP. Please check the code and try again.', 400);
                }
                
                return ResponseUtil::error('Invalid or expired OTP. Please try sending a new OTP.', 400);
            }
            
            $otpRecord = $stmt->fetch(PDO::FETCH_ASSOC);
            error_log("OTP record found: " . json_encode($otpRecord));
            
            // Mark OTP as used
            $query = "UPDATE email_otps SET used = TRUE, used_at = NOW() WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$otpRecord['id']]);
            error_log("OTP marked as used");
            
            // Check if user exists, if yes, mark email as verified
            $query = "SELECT id FROM users WHERE email = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$email]);
            
            if ($stmt->rowCount() > 0) {
                // User exists, mark email as verified
                $updateQuery = "UPDATE users SET email_verified = TRUE, email_verified_at = NOW() WHERE email = ?";
                $updateStmt = $this->conn->prepare($updateQuery);
                $updateStmt->execute([$email]);
                
                // Check if update was successful
                if ($updateStmt->rowCount() > 0) {
                    error_log("User email marked as verified successfully. Rows affected: " . $updateStmt->rowCount());
                    
                    // Verify the update by checking the current status
                    $verifyQuery = "SELECT email_verified FROM users WHERE email = ?";
                    $verifyStmt = $this->conn->prepare($verifyQuery);
                    $verifyStmt->execute([$email]);
                    $verifyResult = $verifyStmt->fetch(PDO::FETCH_ASSOC);
                    error_log("Verification check result: " . json_encode($verifyResult));
                } else {
                    error_log("WARNING: Update query executed but no rows were affected!");
                }
            } else {
                error_log("No user found with email: $email during OTP verification");
            }
            
            error_log("=== VERIFY OTP SUCCESS ===");
            return ResponseUtil::success('Email verified successfully');
            
        } catch (Exception $e) {
            error_log("=== VERIFY OTP ERROR ===");
            error_log("Error: " . $e->getMessage());
            error_log("Stack trace: " . $e->getTraceAsString());
            return ResponseUtil::error('OTP verification failed: ' . $e->getMessage(), 500);
        }
    }
    
    public function refreshToken($refreshToken) {
        try {
            // Verify refresh token
            $decoded = $this->jwtUtil->verifyRefreshToken($refreshToken);
            if (!$decoded) {
                return ResponseUtil::error('Invalid refresh token', 401);
            }
            
            // Check if refresh token exists in database
            $query = "SELECT id FROM user_tokens WHERE refresh_token = ? AND expires_at > NOW()";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$refreshToken]);
            
            if ($stmt->rowCount() == 0) {
                return ResponseUtil::error('Refresh token not found or expired', 401);
            }
            
            // Generate new tokens
            $accessToken = $this->jwtUtil->generateAccessToken($decoded->user_id);
            $newRefreshToken = $this->jwtUtil->generateRefreshToken($decoded->user_id);
            
            // Update refresh token in database
            $query = "UPDATE user_tokens SET refresh_token = ?, expires_at = ? WHERE refresh_token = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $newRefreshToken,
                date('Y-m-d H:i:s', strtotime('+30 days')),
                $refreshToken
            ]);
            
            return ResponseUtil::success('Token refreshed successfully', [
                'access_token' => $accessToken,
                'refresh_token' => $newRefreshToken
            ]);
            
        } catch (Exception $e) {
            return ResponseUtil::error('Token refresh failed: ' . $e->getMessage(), 500);
        }
    }
    
    public function logout($accessToken) {
        try {
            // Verify access token
            $decoded = $this->jwtUtil->verifyAccessToken($accessToken);
            if (!$decoded) {
                return ResponseUtil::error('Invalid access token', 401);
            }
            
            // Remove refresh token from database
            $query = "DELETE FROM user_tokens WHERE user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$decoded->user_id]);
            
            return ResponseUtil::success('Logged out successfully');
            
        } catch (Exception $e) {
            return ResponseUtil::error('Logout failed: ' . $e->getMessage(), 500);
        }
    }
    
    private function generateOTP() {
        return str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
    }
    
    private function storeRefreshToken($userId, $refreshToken) {
        try {
            $expiresAt = date('Y-m-d H:i:s', strtotime('+30 days'));
            
            $query = "INSERT INTO user_tokens (user_id, access_token, refresh_token, expires_at) 
                     VALUES (?, ?, ?, ?)";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId, '', $refreshToken, $expiresAt]);
            
        } catch (Exception $e) {
            throw new Exception('Failed to store refresh token: ' . $e->getMessage());
        }
    }
    
    private function sendEmailViaSMTP2GO($email, $fullName, $otp) {
        try {
            // SMTP2GO API configuration
            $apiKey = 'YOUR_SMTP2GO_API_KEY'; // Replace with your actual API key
            $apiUrl = 'https://api.smtp2go.com/v3/email/send';
            
            $emailData = [
                'api_key' => $apiKey,
                'to' => [$email],
                'sender' => 'noreply@micronest.com',
                'subject' => 'MicroNest - Email Verification OTP',
                'html_body' => $this->generateOTPEmailHTML($fullName, $otp),
                'text_body' => $this->generateOTPEmailText($fullName, $otp)
            ];
            
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $apiUrl);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($emailData));
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json'
            ]);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            if ($httpCode === 200) {
                $responseData = json_decode($response, true);
                if (isset($responseData['data']['succeeded']) && $responseData['data']['succeeded'] == 1) {
                    return ['success' => true, 'message' => 'Email sent successfully'];
                } else {
                    return ['success' => false, 'message' => 'SMTP2GO API error'];
                }
            } else {
                return ['success' => false, 'message' => 'HTTP Error: ' . $httpCode];
            }
            
        } catch (Exception $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }
    
    private function generateOTPEmailHTML($fullName, $otp) {
        return "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='utf-8'>
            <title>Email Verification - MicroNest</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #52B788, #40916C); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .otp-box { background: #52B788; color: white; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0; font-size: 24px; font-weight: bold; letter-spacing: 5px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h1>μN</h1>
                    <h2>Email Verification</h2>
                </div>
                <div class='content'>
                    <p>Hello $fullName!</p>
                    <p>Thank you for signing up with MicroNest. To complete your registration, please use the verification code below:</p>
                    <div class='otp-box'>$otp</div>
                    <p>This code will expire in 10 minutes for security reasons.</p>
                    <p>If you didn't request this verification, please ignore this email.</p>
                    <p>Best regards,<br>The MicroNest Team</p>
                </div>
            </div>
        </body>
        </html>
        ";
    }
    
    private function generateOTPEmailText($fullName, $otp) {
        return "
Email Verification - MicroNest

Hello $fullName!

Thank you for signing up with MicroNest. To complete your registration, please use the verification code below:

$otp

This code will expire in 10 minutes for security reasons.

If you didn't request this verification, please ignore this email.

Best regards,
The MicroNest Team

© 2024 MicroNest. All rights reserved.
        ";
    }
}
?> 