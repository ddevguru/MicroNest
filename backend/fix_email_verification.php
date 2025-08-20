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
                case 'fix_all_users':
                    // Fix all users who have verified OTPs but unverified emails
                    $query = "SELECT DISTINCT u.id, u.email, u.full_name, u.email_verified 
                             FROM users u 
                             INNER JOIN email_otps e ON u.email = e.email 
                             WHERE e.used = TRUE AND u.email_verified = FALSE";
                    
                    $stmt = $conn->prepare($query);
                    $stmt->execute();
                    $usersToFix = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    $fixedCount = 0;
                    foreach ($usersToFix as $user) {
                        $updateQuery = "UPDATE users SET email_verified = TRUE, email_verified_at = NOW() WHERE id = ?";
                        $updateStmt = $conn->prepare($updateQuery);
                        $updateStmt->execute([$user['id']]);
                        $fixedCount++;
                    }
                    
                    echo json_encode([
                        'success' => true,
                        'message' => "Fixed email verification for $fixedCount users",
                        'fixed_users' => $usersToFix
                    ]);
                    break;
                    
                case 'fix_specific_user':
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
                            'email' => $email,
                            'otp_info' => $otpStmt->fetch(PDO::FETCH_ASSOC)
                        ]);
                    } else {
                        echo json_encode([
                            'success' => false,
                            'message' => 'No verified OTP found for this email',
                            'email' => $email
                        ]);
                    }
                    break;
                    
                case 'check_database_status':
                    // Check overall database status
                    $userQuery = "SELECT 
                                    COUNT(*) as total_users,
                                    SUM(CASE WHEN email_verified = TRUE THEN 1 ELSE 0 END) as verified_users,
                                    SUM(CASE WHEN email_verified = FALSE THEN 1 ELSE 0 END) as unverified_users
                                 FROM users";
                    $userStmt = $conn->prepare($userQuery);
                    $userStmt->execute();
                    $userStats = $userStmt->fetch(PDO::FETCH_ASSOC);
                    
                    $otpQuery = "SELECT 
                                    COUNT(*) as total_otps,
                                    SUM(CASE WHEN used = TRUE THEN 1 ELSE 0 END) as used_otps,
                                    SUM(CASE WHEN used = FALSE THEN 1 ELSE 0 END) as unused_otps
                                 FROM email_otps";
                    $otpStmt = $conn->prepare($otpQuery);
                    $otpStmt->execute();
                    $otpStats = $otpStmt->fetch(PDO::FETCH_ASSOC);
                    
                    echo json_encode([
                        'success' => true,
                        'user_stats' => $userStats,
                        'otp_stats' => $otpStats,
                        'current_time' => date('Y-m-d H:i:s'),
                        'current_utc_time' => gmdate('Y-m-d H:i:s')
                    ]);
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
            'message' => 'Email Verification Fix Tool',
            'usage' => [
                'fix_all_users' => 'POST with {"action": "fix_all_users"} - Fixes all users with verified OTPs',
                'fix_specific_user' => 'POST with {"action": "fix_specific_user", "email": "user@example.com"}',
                'check_database_status' => 'POST with {"action": "check_database_status"} - Shows overall stats'
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