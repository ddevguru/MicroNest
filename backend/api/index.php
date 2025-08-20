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

// Log all incoming requests
error_log("=== API REQUEST ===");
error_log("Method: " . $_SERVER['REQUEST_METHOD']);
error_log("URI: " . $_SERVER['REQUEST_URI']);
error_log("User Agent: " . ($_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'));
error_log("Remote IP: " . ($_SERVER['REMOTE_ADDR'] ?? 'Unknown'));

// Include required files
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/User.php';
require_once __DIR__ . '/../models/Auth.php';
require_once __DIR__ . '/../models/EmailService.php';
require_once __DIR__ . '/../utils/JWTUtil.php';
require_once __DIR__ . '/../utils/ResponseUtil.php';

// Get request method and URI
$method = $_SERVER['REQUEST_METHOD'];
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$path = explode('/', trim($uri, '/'));

error_log("Parsed path: " . json_encode($path));

// Remove 'api' from path if present
if ($path[0] === 'api') {
    array_shift($path);
    error_log("Removed 'api' from path, new path: " . json_encode($path));
}

// Route the request
try {
    error_log("Routing to: " . ($path[0] ?? 'default'));
    
    switch ($path[0]) {
        case 'auth':
            error_log("Handling auth route: " . ($path[1] ?? 'unknown'));
            handleAuthRoutes($method, $path);
            break;
        case 'users':
            error_log("Handling users route");
            handleUserRoutes($method, $path);
            break;
        case 'groups':
            error_log("Handling groups route");
            handleGroupRoutes($method, $path);
            break;
        case 'contributions':
            error_log("Handling contributions route");
            handleContributionRoutes($method, $path);
            break;
        case 'loans':
            error_log("Handling loans route");
            handleLoanRoutes($method, $path);
            break;
        case 'profile':
            error_log("Handling profile route");
            handleProfileRoutes($method, $path);
            break;
        case 'test':
            error_log("Handling test request");
            try {
                $database = new Database();
                $conn = $database->getConnection();
                if ($conn) {
                    echo json_encode(['success' => true, 'message' => 'Database connection successful']);
                } else {
                    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
                }
            } catch (Exception $e) {
                error_log("Test endpoint error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
            }
            break;
        default:
            error_log("No route found for: " . ($path[0] ?? 'empty'));
            ResponseUtil::sendError('Endpoint not found', 404);
    }
} catch (Exception $e) {
    error_log("=== API ERROR ===");
    error_log("Error: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    ResponseUtil::sendError('Internal server error: ' . $e->getMessage(), 500);
}

function handleAuthRoutes($method, $path) {
    $auth = new Auth();
    
    error_log("=== AUTH ROUTE HANDLER ===");
    error_log("Method: $method");
    error_log("Path: " . json_encode($path));
    
    switch ($path[1]) {
        case 'login':
            error_log("Handling login request");
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                error_log("Login data: " . json_encode($data));
                $result = $auth->login($data['email'], $data['password']);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'signup':
            error_log("Handling signup request");
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                error_log("Signup data: " . json_encode($data));
                $result = $auth->signup($data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'send-otp':
            error_log("Handling send-otp request");
            if ($method === 'POST') {
                try {
                    $data = json_decode(file_get_contents('php://input'), true);
                    error_log("Send OTP data: " . json_encode($data));
                    
                    if (!isset($data['email'])) {
                        error_log("Email field missing in request");
                        ResponseUtil::sendError('Email field is required', 400);
                        return;
                    }
                    
                    $result = $auth->sendEmailOTP($data['email']);
                    error_log("Send OTP result: " . json_encode($result));
                    echo json_encode($result);
                } catch (Exception $e) {
                    error_log("=== SEND OTP EXCEPTION ===");
                    error_log("Exception: " . $e->getMessage());
                    error_log("Stack trace: " . $e->getTraceAsString());
                    ResponseUtil::sendError('Internal server error: ' . $e->getMessage(), 500);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'verify-otp':
            error_log("Handling verify-otp request");
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                error_log("Verify OTP data: " . json_encode($data));
                $result = $auth->verifyEmailOTP($data['email'], $data['otp']);
                error_log("Verify OTP result: " . json_encode($result));
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'refresh':
            error_log("Handling refresh request");
            if ($method === 'POST') {
                $headers = getallheaders();
                $refreshToken = $headers['Authorization'] ?? '';
                $refreshToken = str_replace('Bearer ', '', $refreshToken);
                
                $result = $auth->refreshToken($refreshToken);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'logout':
            error_log("Handling logout request");
            if ($method === 'POST') {
                $headers = getallheaders();
                $accessToken = $headers['Authorization'] ?? '';
                $accessToken = str_replace('Bearer ', '', $accessToken);
                
                $result = $auth->logout($accessToken);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        default:
            error_log("Unknown auth endpoint: " . ($path[1] ?? 'empty'));
            ResponseUtil::sendError('Auth endpoint not found', 404);
    }
}

function handleUserRoutes($method, $path) {
    // Verify JWT token first
    $headers = getallheaders();
    $token = $headers['Authorization'] ?? '';
    $token = str_replace('Bearer ', '', $token);
    
    if (empty($token)) {
        ResponseUtil::sendError('Authorization token required', 401);
        return;
    }
    
    $jwtUtil = new JWTUtil();
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        ResponseUtil::sendError('Invalid or expired token', 401);
        return;
    }
    
    $user = new User();
    
    switch ($path[1]) {
        case 'profile':
            if ($method === 'GET') {
                $result = $user->getProfile($decoded->user_id);
                echo json_encode($result);
            } elseif ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $user->updateProfile($decoded->user_id, $data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'trust-score':
            if ($method === 'GET') {
                $result = $user->getTrustScore($decoded->user_id);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        default:
            ResponseUtil::sendError('User endpoint not found', 404);
    }
}

function handleGroupRoutes($method, $path) {
    // Verify JWT token first
    $headers = getallheaders();
    $token = $headers['Authorization'] ?? '';
    $token = str_replace('Bearer ', '', $token);
    
    if (empty($token)) {
        ResponseUtil::sendError('Authorization token required', 401);
        return;
    }
    
    $jwtUtil = new JWTUtil();
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        ResponseUtil::sendError('Invalid or expired token', 401);
        return;
    }
    
    // Group routes implementation will go here
    ResponseUtil::sendError('Group endpoints not implemented yet', 501);
}

function handleContributionRoutes($method, $path) {
    // Verify JWT token first
    $headers = getallheaders();
    $token = $headers['Authorization'] ?? '';
    $token = str_replace('Bearer ', '', $token);
    
    if (empty($token)) {
        ResponseUtil::sendError('Authorization token required', 401);
        return;
    }
    
    $jwtUtil = new JWTUtil();
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        ResponseUtil::sendError('Invalid or expired token', 401);
        return;
    }
    
    // Contribution routes implementation will go here
    ResponseUtil::sendError('Contribution endpoints not implemented yet', 501);
}

function handleLoanRoutes($method, $path) {
    // Verify JWT token first
    $headers = getallheaders();
    $token = $headers['Authorization'] ?? '';
    $token = str_replace('Bearer ', '', $token);
    
    if (empty($token)) {
        ResponseUtil::sendError('Authorization token required', 401);
        return;
    }
    
    $jwtUtil = new JWTUtil();
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        ResponseUtil::sendError('Invalid or expired token', 401);
        return;
    }
    
    // Loan routes implementation will go here
    ResponseUtil::sendError('Loan endpoints not implemented yet', 501);
}

function handleProfileRoutes($method, $path) {
    // Verify JWT token first
    $headers = getallheaders();
    $token = $headers['Authorization'] ?? '';
    $token = str_replace('Bearer ', '', $token);
    
    if (empty($token)) {
        ResponseUtil::sendError('Authorization token required', 401);
        return;
    }
    
    $jwtUtil = new JWTUtil();
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        ResponseUtil::sendError('Invalid or expired token', 401);
        return;
    }
    
    $userId = $decoded->user_id;
    
    // Include Profile model
    require_once __DIR__ . '/../models/Profile.php';
    $profile = new Profile($this->conn ?? null);
    
    // Route profile requests
    switch ($path[1] ?? '') {
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
            } elseif ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateProfile($userId, $data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
    }
}
?> 