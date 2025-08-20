<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include required files
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/User.php';
require_once __DIR__ . '/../models/Auth.php';
require_once __DIR__ . '/../models/EmailService.php';
require_once __DIR__ . '/../utils/JWTUtil.php';
require_once __DIR__ . '/../utils/ResponseUtil.php';

// Get request method and action
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

// Route the request based on action parameter
try {
    switch ($action) {
        case 'login':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $auth = new Auth();
                $result = $auth->login($data['email'], $data['password']);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'signup':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $auth = new Auth();
                $result = $auth->signup($data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'send-otp':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $auth = new Auth();
                $result = $auth->sendEmailOTP($data['email']);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'verify-otp':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $auth = new Auth();
                $result = $auth->verifyEmailOTP($data['email'], $data['otp']);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'refresh':
            if ($method === 'POST') {
                $headers = getallheaders();
                $authHeader = $headers['Authorization'] ?? '';
                $refreshToken = str_replace('Bearer ', '', $authHeader);
                
                $auth = new Auth();
                $result = $auth->refreshToken($refreshToken);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'logout':
            if ($method === 'POST') {
                $headers = getallheaders();
                $authHeader = $headers['Authorization'] ?? '';
                $accessToken = str_replace('Bearer ', '', $authHeader);
                
                $auth = new Auth();
                $result = $auth->logout($accessToken);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'test':
            // Simple test endpoint
            echo json_encode([
                'success' => true,
                'message' => 'API is working!',
                'timestamp' => date('Y-m-d H:i:s'),
                'action' => $action,
                'method' => $method
            ]);
            break;
            
        default:
            // Show available endpoints
            echo json_encode([
                'success' => false,
                'message' => 'Invalid action. Available actions:',
                'available_actions' => [
                    'login' => 'POST - Login with email and password',
                    'signup' => 'POST - Signup with user data',
                    'send-otp' => 'POST - Send OTP to email',
                    'verify-otp' => 'POST - Verify OTP',
                    'refresh' => 'POST - Refresh access token',
                    'logout' => 'POST - Logout user',
                    'test' => 'GET - Test API connectivity'
                ],
                'usage' => 'Add ?action=ACTION_NAME to the URL',
                'example' => 'api_direct.php?action=login'
            ]);
    }
} catch (Exception $e) {
    ResponseUtil::sendError('Internal server error: ' . $e->getMessage(), 500);
}
?> 