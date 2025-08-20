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
        ResponseUtil::sendError('Authorization header required', 401);
        exit;
    }
    
    $token = substr($authHeader, 7);
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        ResponseUtil::sendError('Invalid or expired token', 401);
        exit;
    }
    
    $userId = $decoded['user_id'];
    
    switch ($action) {
        case 'get':
            if ($method === 'GET') {
                $result = $profile->getCompleteProfile($userId);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'update':
            if ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateProfile($userId, $data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'notifications':
            if ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateNotificationSettings($userId, $data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'security':
            if ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateSecuritySettings($userId, $data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'trust-score':
            if ($method === 'GET') {
                $result = $profile->getTrustScoreDetails($userId);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'awards':
            if ($method === 'GET') {
                $result = $profile->getAwardsAndAchievements($userId);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        default:
            // Get complete profile data
            if ($method === 'GET') {
                $result = $profile->getCompleteProfile($userId);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
    }
    
} catch (Exception $e) {
    error_log("Profile API Error: " . $e->getMessage());
    ResponseUtil::sendError('Internal server error: ' . $e->getMessage(), 500);
}
?> 