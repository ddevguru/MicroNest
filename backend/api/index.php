<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Include required files
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/ResponseUtil.php';
require_once __DIR__ . '/../utils/JWTUtil.php';

// Get request method and path
$method = $_SERVER['REQUEST_METHOD'];
$requestUri = $_SERVER['REQUEST_URI'];
$path = parse_url($requestUri, PHP_URL_PATH);
$pathParts = explode('/', trim($path, '/'));

// Remove the base path (api) from the path parts
if (isset($pathParts[0]) && $pathParts[0] === 'api') {
    array_shift($pathParts);
}

// Route the request
if (empty($pathParts)) {
    ResponseUtil::sendError('API endpoint not specified', 404);
}

$endpoint = $pathParts[0] ?? '';

switch ($endpoint) {
    case 'auth':
        handleAuthRoutes($method, array_slice($pathParts, 1));
        break;
        
    case 'profile':
        handleProfileRoutes($method, array_slice($pathParts, 1));
        break;
        
    case 'dashboard':
        handleDashboardRoutes($method, array_slice($pathParts, 1));
        break;
        
    case 'groups':
        handleGroupRoutes($method, array_slice($pathParts, 1));
        break;
        
    default:
        ResponseUtil::sendError('Endpoint not found', 404);
        break;
}

function handleAuthRoutes($method, $path) {
    require_once __DIR__ . '/../models/User.php';
    require_once __DIR__ . '/../models/Auth.php';
    
    $database = new Database();
    $db = $database->getConnection();
    $auth = new Auth($db);
    
    switch ($path[0] ?? '') {
        case 'register':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $auth->signup($data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'signup':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $auth->signup($data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'login':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $auth->login($data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'send-otp':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                if (!isset($data['email'])) {
                    ResponseUtil::sendError('Email is required', 400);
                    break;
                }
                $result = $auth->sendEmailOTP($data['email']);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'verify-otp':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                if (!isset($data['email']) || !isset($data['otp'])) {
                    ResponseUtil::sendError('Email and OTP are required', 400);
                    break;
                }
                $result = $auth->verifyEmailOTP($data['email'], $data['otp']);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'refresh':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $auth->refreshToken($data);
                echo json_encode($result);
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        default:
            ResponseUtil::sendError('Auth endpoint not found', 404);
            break;
    }
}

function handleProfileRoutes($method, $path) {
    // Verify JWT token
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    if (!preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        ResponseUtil::sendUnauthorized('No token provided');
        return;
    }
    
    $token = $matches[1];
    $jwtUtil = new JWTUtil();
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        ResponseUtil::sendUnauthorized('Invalid or expired token');
        return;
    }
    
    $userId = $decoded->user_id;
    
    // Include Profile model and create database connection
    require_once __DIR__ . '/../models/Profile.php';
    $database = new Database();
    $db = $database->getConnection();
    $profile = new Profile($db);
    
    // Route profile requests
    switch ($path[0] ?? '') {
        case 'notifications':
            if ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateNotificationSettings($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'security':
            if ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateSecuritySettings($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'pin':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->setPin($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } elseif ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updatePin($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } elseif ($method === 'DELETE') {
                $result = $profile->removePin($userId);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'verify-pin':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->verifyPin($userId, $data['pin']);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'trust-score':
            if ($method === 'GET') {
                $result = $profile->getTrustScoreDetails($userId);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'awards':
            if ($method === 'GET') {
                $result = $profile->getAwardsAndAchievements($userId);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        default:
            // Get complete profile data
            if ($method === 'GET') {
                $result = $profile->getCompleteProfile($userId);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } elseif ($method === 'PUT') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $profile->updateProfile($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
    }
}

function handleDashboardRoutes($method, $path) {
    // Verify JWT token
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    if (!preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        ResponseUtil::sendUnauthorized('No token provided');
        return;
    }
    
    $token = $matches[1];
    $jwtUtil = new JWTUtil();
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        ResponseUtil::sendUnauthorized('Invalid or expired token');
        return;
    }
    
    $userId = $decoded->user_id;
    
    if ($method === 'GET') {
        require_once __DIR__ . '/../models/Dashboard.php';
        $database = new Database();
        $db = $database->getConnection();
        $dashboard = new Dashboard($db);
        
        $result = $dashboard->getDashboardData($userId);
        if ($result['success']) {
            ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
        } else {
            ResponseUtil::sendError($result['message'], 400);
        }
    } else {
        ResponseUtil::sendError('Method not allowed', 405);
    }
}

function handleGroupRoutes($method, $path) {
    // Verify JWT token
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    if (!preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        ResponseUtil::sendUnauthorized('No token provided');
        return;
    }
    
    $token = $matches[1];
    $jwtUtil = new JWTUtil();
    $decoded = $jwtUtil->verifyToken($token);
    
    if (!$decoded) {
        ResponseUtil::sendUnauthorized('Invalid or expired token');
        return;
    }
    
    $userId = $decoded->user_id;
    
    require_once __DIR__ . '/../models/Group.php';
    $database = new Database();
    $db = $database->getConnection();
    $group = new Group($db);
    
    // Get action from query parameters
    $action = $_GET['action'] ?? '';
    
    switch ($action) {
        case 'list':
            if ($method === 'GET') {
                $result = $group->getUserGroups($userId);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'available':
            if ($method === 'GET') {
                $result = $group->getAvailableGroups();
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'create':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->createGroup($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'join':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->joinGroup($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'leave':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->leaveGroup($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'details':
            if ($method === 'GET') {
                $groupId = $_GET['group_id'] ?? null;
                if (!$groupId) {
                    ResponseUtil::sendError('Group ID is required', 400);
                    break;
                }
                $result = $group->getGroupDetails($groupId);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'members':
            if ($method === 'GET') {
                $groupId = $_GET['group_id'] ?? null;
                if (!$groupId) {
                    ResponseUtil::sendError('Group ID is required', 400);
                    break;
                }
                $result = $group->getGroupMembers($groupId);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'contribute':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->makeContribution($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'withdraw':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->requestWithdrawal($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'deposit':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->requestDeposit($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'request-loan':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->requestLoan($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'loans':
            if ($method === 'GET') {
                $groupId = $_GET['group_id'] ?? null;
                if ($groupId) {
                    $result = $group->getGroupLoans($groupId);
                } else {
                    $result = $group->getUserLoans($userId);
                }
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'transactions':
            if ($method === 'GET') {
                $groupId = $_GET['group_id'] ?? null;
                if ($groupId) {
                    $result = $group->getGroupTransactions($groupId);
                } else {
                    $result = $group->getUserTransactions($userId);
                }
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'chat':
            if ($method === 'GET') {
                $groupId = $_GET['group_id'] ?? null;
                if (!$groupId) {
                    ResponseUtil::sendError('Group ID is required', 400);
                    break;
                }
                $result = $group->getGroupChat($groupId);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'approve-contribution':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->approveContribution($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'approve-withdrawal':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->approveWithdrawal($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        case 'approve-loan':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $result = $group->approveLoan($userId, $data);
                if ($result['success']) {
                    ResponseUtil::sendSuccess($result['message'], $result['data'] ?? null);
                } else {
                    ResponseUtil::sendError($result['message'], 400);
                }
            } else {
                ResponseUtil::sendError('Method not allowed', 405);
            }
            break;
            
        default:
            ResponseUtil::sendError('Group action not found', 404);
            break;
    }
}
?> 