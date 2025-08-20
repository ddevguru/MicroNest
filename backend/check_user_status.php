<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Test database connection
    require_once 'config/database.php';
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    $method = $_SERVER['REQUEST_METHOD'];
    
    if ($method === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (isset($input['action'])) {
            switch ($input['action']) {
                case 'check_user':
                    if (empty($input['email'])) {
                        echo json_encode([
                            'success' => false,
                            'message' => 'Email is required'
                        ]);
                        exit;
                    }
                    
                    $email = $input['email'];
                    
                    // Check user status
                    $query = "SELECT id, full_name, email, username, email_verified, email_verified_at, status, created_at 
                             FROM users WHERE email = ?";
                    $stmt = $conn->prepare($query);
                    $stmt->execute([$email]);
                    
                    if ($stmt->rowCount() == 0) {
                        echo json_encode([
                            'success' => false,
                            'message' => 'User not found',
                            'email' => $email
                        ]);
                        exit;
                    }
                    
                    $user = $stmt->fetch(PDO::FETCH_ASSOC);
                    
                    // Check OTP status
                    $otpQuery = "SELECT * FROM email_otps WHERE email = ? ORDER BY created_at DESC LIMIT 5";
                    $otpStmt = $conn->prepare($otpQuery);
                    $otpStmt->execute([$email]);
                    $otps = $otpStmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    echo json_encode([
                        'success' => true,
                        'user' => $user,
                        'otps' => $otps,
                        'current_time' => date('Y-m-d H:i:s'),
                        'current_utc_time' => gmdate('Y-m-d H:i:s')
                    ]);
                    break;
                    
                case 'fix_email_verification':
                    if (empty($input['email'])) {
                        echo json_encode([
                            'success' => false,
                            'message' => 'Email is required'
                        ]);
                        exit;
                    }
                    
                    $email = $input['email'];
                    
                    // Check if user has verified OTP
                    $otpQuery = "SELECT * FROM email_otps WHERE email = ? AND used = TRUE ORDER BY created_at DESC LIMIT 1";
                    $otpStmt = $conn->prepare($otpQuery);
                    $otpStmt->execute([$email]);
                    
                    if ($otpStmt->rowCount() > 0) {
                        // Mark user email as verified
                        $updateQuery = "UPDATE users SET email_verified = TRUE, email_verified_at = NOW() WHERE email = ?";
                        $updateStmt = $conn->prepare($updateQuery);
                        $updateStmt->execute([$email]);
                        
                        echo json_encode([
                            'success' => true,
                            'message' => 'Email verification status fixed',
                            'email' => $email
                        ]);
                    } else {
                        echo json_encode([
                            'success' => false,
                            'message' => 'No verified OTP found for this email',
                            'email' => $email
                        ]);
                    }
                    break;
                    
                default:
                    echo json_encode([
                        'success' => false,
                        'message' => 'Invalid action'
                    ]);
            }
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Action is required'
            ]);
        }
    } else {
        echo json_encode([
            'success' => true,
            'message' => 'User Status Check Endpoint',
            'usage' => [
                'check_user' => 'POST with {"action": "check_user", "email": "user@example.com"}',
                'fix_email_verification' => 'POST with {"action": "fix_email_verification", "email": "user@example.com"}'
            ]
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}
?> 