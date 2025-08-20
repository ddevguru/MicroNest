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
require_once '../models/Group.php';

$database = new Database();
$db = $database->getConnection();
$group = new Group($db);
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
        case 'create':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['created_by'] = $userId;
                $result = $group->createGroup($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'join':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['user_id'] = $userId;
                $result = $group->joinGroup($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'leave':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['user_id'] = $userId;
                $result = $group->leaveGroup($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'list':
            if ($method === 'GET') {
                $result = $group->getUserGroups($userId);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'available':
            if ($method === 'GET') {
                $result = $group->getAvailableGroups();
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'details':
            if ($method === 'GET') {
                $groupId = $_GET['group_id'] ?? null;
                if (!$groupId) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'message' => 'Group ID required']);
                    exit;
                }
                $result = $group->getGroupDetails($groupId, $userId);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'members':
            if ($method === 'GET') {
                $groupId = $_GET['group_id'] ?? null;
                if (!$groupId) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'message' => 'Group ID required']);
                    exit;
                }
                $result = $group->getGroupMembers($groupId);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'contribute':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['user_id'] = $userId;
                $result = $group->makeContribution($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'withdraw':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['user_id'] = $userId;
                $result = $group->requestWithdrawal($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'deposit':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['user_id'] = $userId;
                $result = $group->requestDeposit($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'request-loan':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['user_id'] = $userId;
                $result = $group->requestLoan($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
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
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
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
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'chat':
            if ($method === 'GET') {
                $groupId = $_GET['group_id'] ?? null;
                if (!$groupId) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'message' => 'Group ID required']);
                    exit;
                }
                $result = $group->getGroupChat($groupId);
                echo json_encode($result);
            } else if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['user_id'] = $userId;
                $result = $group->sendMessage($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'approve-contribution':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['admin_id'] = $userId;
                $result = $group->approveContribution($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'approve-withdrawal':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['admin_id'] = $userId;
                $result = $group->approveWithdrawal($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        case 'approve-loan':
            if ($method === 'POST') {
                $data = json_decode(file_get_contents('php://input'), true);
                $data['admin_id'] = $userId;
                $result = $group->approveLoan($data);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
            
        default:
            // Get user's groups by default
            if ($method === 'GET') {
                $result = $group->getUserGroups($userId);
                echo json_encode($result);
            } else {
                http_response_code(405);
                echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            }
            break;
    }
    
} catch (Exception $e) {
    error_log("Groups API Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Internal server error: ' . $e->getMessage()]);
}
?> 