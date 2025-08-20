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
                case 'send_otp':
                    if (empty($input['email'])) {
                        echo json_encode([
                            'success' => false,
                            'message' => 'Email is required'
                        ]);
                        exit;
                    }
                    
                    // Generate a simple OTP (123456 for testing)
                    $otp = '123456';
                    $email = $input['email'];
                    $expiresAt = date('Y-m-d H:i:s', strtotime('+10 minutes'));
                    
                    // Delete existing OTPs for this email
                    $query = "DELETE FROM email_otps WHERE email = ?";
                    $stmt = $conn->prepare($query);
                    $stmt->execute([$email]);
                    
                    // Store new OTP
                    $query = "INSERT INTO email_otps (email, otp, expires_at) VALUES (?, ?, ?)";
                    $stmt = $conn->prepare($query);
                    $stmt->execute([$email, $otp, $expiresAt]);
                    
                    echo json_encode([
                        'success' => true,
                        'message' => 'OTP sent successfully (Test Mode: OTP is 123456)',
                        'otp' => $otp, // Only for testing - remove in production
                        'email' => $email
                    ]);
                    break;
                    
                case 'verify_otp':
                    if (empty($input['email']) || empty($input['otp'])) {
                        echo json_encode([
                            'success' => false,
                            'message' => 'Email and OTP are required'
                        ]);
                        exit;
                    }
                    
                    $email = $input['email'];
                    $otp = $input['otp'];
                    
                    // Check if OTP exists and is valid
                    $query = "SELECT id, expires_at FROM email_otps 
                             WHERE email = ? AND otp = ? AND used = FALSE AND expires_at > NOW()";
                    $stmt = $conn->prepare($query);
                    $stmt->execute([$email, $otp]);
                    
                    if ($stmt->rowCount() == 0) {
                        echo json_encode([
                            'success' => false,
                            'message' => 'Invalid or expired OTP'
                        ]);
                        exit;
                    }
                    
                    $otpRecord = $stmt->fetch(PDO::FETCH_ASSOC);
                    
                    // Mark OTP as used
                    $query = "UPDATE email_otps SET used = TRUE WHERE id = ?";
                    $stmt = $conn->prepare($query);
                    $stmt->execute([$otpRecord['id']]);
                    
                    // Mark user email as verified (if user exists)
                    $query = "UPDATE users SET email_verified = TRUE, email_verified_at = NOW() WHERE email = ?";
                    $stmt = $conn->prepare($query);
                    $stmt->execute([$email]);
                    
                    echo json_encode([
                        'success' => true,
                        'message' => 'Email verified successfully'
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
            'message' => 'OTP Test Endpoint',
            'usage' => [
                'send_otp' => 'POST with {"action": "send_otp", "email": "user@example.com"}',
                'verify_otp' => 'POST with {"action": "verify_otp", "email": "user@example.com", "otp": "123456"}'
            ],
            'note' => 'This is a test endpoint. In production, use the main API endpoints.'
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