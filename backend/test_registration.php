<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'config/database.php';
require_once 'utils/ResponseUtil.php';
require_once 'utils/JWTUtil.php';
require_once 'models/Auth.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        ResponseUtil::sendError('Only POST method allowed', 405);
    }
    
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    if (!$data) {
        ResponseUtil::sendError('Invalid JSON input', 400);
    }
    
    $action = $data['action'] ?? '';
    
    if (empty($action)) {
        ResponseUtil::sendError('Action is required', 400);
    }
    
    // Test database connection
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        ResponseUtil::sendError('Database connection failed', 500);
    }
    
    // Test Auth class
    $auth = new Auth($db);
    
    switch ($action) {
        case 'test-signup':
            // Test signup with sample data
            $testData = [
                'full_name' => 'Test User',
                'email' => 'test@example.com',
                'username' => 'testuser',
                'password' => 'password123',
                'phone' => '1234567890',
                'address' => 'Test Address'
            ];
            
            $result = $auth->signup($testData);
            echo json_encode($result);
            break;
            
        case 'test-otp-flow':
            $email = $data['email'] ?? 'test@example.com';
            
            // Step 1: Send OTP
            echo json_encode([
                'step' => '1. Sending OTP',
                'email' => $email
            ]);
            
            $otpResult = $auth->sendEmailOTP($email);
            echo json_encode([
                'step' => '2. OTP Send Result',
                'result' => $otpResult
            ]);
            
            // Step 2: Verify OTP (using test OTP if available)
            if (isset($otpResult['data']['otp'])) {
                $otp = $otpResult['data']['otp'];
            } else {
                // Check database for the OTP
                $query = "SELECT otp FROM email_otps WHERE email = ? ORDER BY created_at DESC LIMIT 1";
                $stmt = $db->prepare($query);
                $stmt->execute([$email]);
                $otpRecord = $stmt->fetch(PDO::FETCH_ASSOC);
                $otp = $otpRecord['otp'] ?? '123456'; // Fallback
            }
            
            echo json_encode([
                'step' => '3. Verifying OTP',
                'otp' => $otp
            ]);
            
            $verifyResult = $auth->verifyEmailOTP($email, $otp);
            echo json_encode([
                'step' => '4. OTP Verification Result',
                'result' => $verifyResult
            ]);
            
            // Step 3: Try to signup
            $signupData = [
                'full_name' => 'Test User',
                'email' => $email,
                'username' => 'testuser_' . time(),
                'password' => 'password123',
                'phone' => '1234567890',
                'address' => 'Test Address'
            ];
            
            echo json_encode([
                'step' => '5. Attempting Signup',
                'data' => $signupData
            ]);
            
            $signupResult = $auth->signup($signupData);
            echo json_encode([
                'step' => '6. Signup Result',
                'result' => $signupResult
            ]);
            break;
            
        default:
            ResponseUtil::sendError('Invalid action. Use "test-signup" or "test-otp-flow"', 400);
            break;
    }
    
} catch (Exception $e) {
    error_log("Test registration error: " . $e->getMessage());
    ResponseUtil::sendError('Test failed: ' . $e->getMessage(), 500);
}
?> 