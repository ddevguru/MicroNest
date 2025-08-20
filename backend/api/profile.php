<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/database.php';
require_once '../utils/JWTUtil.php';
require_once '../utils/ResponseUtil.php';
require_once '../models/Profile.php';

$database = new Database();
$db = $database->getConnection();
$profile = new Profile($db);
$jwtUtil = new JWTUtil();

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

try {
    // Verify JWT token
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    if (empty($authHeader) || !str_starts_with($authHeader, 'Bearer ')) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Authorization header required']);
        exit;
    }
    
    $token = substr($authHeader, 7);
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid or expired token']);
        exit;
    }
    
    $userId = $decoded['user_id'];
    
    switch ($action) {
        case 'get':
            if ($method === 'GET') {
                $result = $profile->getCompleteProfile($userId);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'update':
            if ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateProfile($userId, $data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'notifications':
            if ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateNotificationSettings($userId, $data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'security':
            if ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateSecuritySettings($userId, $data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'trust-score':
            if ($method === 'GET') {
                $result = $profile->getTrustScoreDetails($userId);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'awards':
            if ($method === 'GET') {
                $result = $profile->getAwardsAndAchievements($userId);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'pin':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->setPin($userId, $data);
                echo json_encode($result);
            } else if ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updatePin($userId, $data);
                echo json_encode($result);
            } else if ($method === 'DELETE') {
                $result = $profile->removePin($userId);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'verify-pin':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->verifyPin($userId, $data['pin']);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        default:
            // Get complete profile data
            if ($method === 'GET') {
                $result = $profile->getCompleteProfile($userId);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
    }
    
} catch (Exception $e) {
    error_log("Profile API Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Internal server error: ' . $e->getMessage()]);
}
?> 