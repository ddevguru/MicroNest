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
                case 'check_otp_status':
                    if (empty($input['email'])) {
                        echo json_encode([
                            'success' => false,
                            'message' => 'Email is required'
                        ]);
                        exit;
                    }
                    
                    $email = $input['email'];
                    
                    // Check all OTPs for this email
                    $query = "SELECT * FROM email_otps WHERE email = ? ORDER BY created_at DESC LIMIT 10";
                    $stmt = $conn->prepare($query);
                    $stmt->execute([$email]);
                    $otps = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    // Get current server time
                    $currentTime = date('Y-m-d H:i:s');
                    $currentUTCTime = gmdate('Y-m-d H:i:s');
                    
                    echo json_encode([
                        'success' => true,
                        'email' => $email,
                        'current_server_time' => $currentTime,
                        'current_utc_time' => $currentUTCTime,
                        'otps' => $otps,
                        'total_otps_found' => count($otps)
                    ]);
                    break;
                    
                case 'clear_expired_otps':
                    if (empty($input['email'])) {
                        echo json_encode([
                            'success' => false,
                            'message' => 'Email is required'
                        ]);
                        exit;
                    }
                    
                    $email = $input['email'];
                    
                    // Delete expired OTPs
                    $query = "DELETE FROM email_otps WHERE email = ? AND expires_at < NOW()";
                    $stmt = $conn->prepare($query);
                    $stmt->execute([$email]);
                    $deletedCount = $stmt->rowCount();
                    
                    echo json_encode([
                        'success' => true,
                        'message' => "Cleared $deletedCount expired OTPs for $email"
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
            'message' => 'OTP Debug Endpoint',
            'usage' => [
                'check_otp_status' => 'POST with {"action": "check_otp_status", "email": "user@example.com"}',
                'clear_expired_otps' => 'POST with {"action": "clear_expired_otps", "email": "user@example.com"}'
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