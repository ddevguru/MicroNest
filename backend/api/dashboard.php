<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';
require_once '../models/Wallet.php';
require_once '../models/Group.php';
require_once '../utils/JWTUtil.php';
require_once '../utils/ResponseUtil.php';

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    $method = $_SERVER['REQUEST_METHOD'];
    
    if ($method === 'GET') {
        // Get authorization header
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        
        if (empty($authHeader) || !str_starts_with($authHeader, 'Bearer ')) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'Authorization token required'
            ]);
            exit;
        }
        
        $token = substr($authHeader, 7); // Remove 'Bearer ' prefix
        
        // Verify JWT token
        $jwtUtil = new JWTUtil();
        $decoded = $jwtUtil->verifyAccessToken($token);
        
        if (!$decoded) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'Invalid or expired token'
            ]);
            exit;
        }
        
        $userId = $decoded->user_id;
        
        // Get dashboard data
        $wallet = new Wallet($conn);
        $group = new Group($conn);
        
        $walletData = $wallet->getUserWallet($userId);
        $userGroups = $group->getUserGroups($userId);
        
        // Format wallet data for Indian Rupees
        if ($walletData) {
            $walletData['net_balance_formatted'] = '₹' . number_format($walletData['net_balance'], 2);
            $walletData['total_credits_formatted'] = '₹' . number_format($walletData['total_credits'], 2);
            $walletData['total_debits_formatted'] = '₹' . number_format($walletData['total_debits'], 2);
        }
        
        // Format group data
        foreach ($userGroups as &$groupData) {
            $groupData['target_amount_formatted'] = '₹' . number_format($groupData['target_amount'], 2);
            $groupData['current_amount_formatted'] = '₹' . number_format($groupData['current_amount'], 2);
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Dashboard data retrieved successfully',
            'data' => [
                'wallet' => $walletData,
                'groups' => $userGroups,
                'timestamp' => date('Y-m-d H:i:s')
            ]
        ]);
        
    } else {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'Method not allowed'
        ]);
    }
    
} catch (Exception $e) {
    error_log("Dashboard API Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Internal server error: ' . $e->getMessage()
    ]);
}
?> 