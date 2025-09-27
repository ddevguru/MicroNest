<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';
require_once __DIR__ . '/../../models/User.php';
require_once __DIR__ . '/../../models/Group.php';
require_once __DIR__ . '/../../models/GroupMember.php';

header('Content-Type: application/json');

ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log("Withdrawal request error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Withdrawal request error: No token provided");
        ApiResponse::error('Access token required', 401);
    }

    $token = $matches[1];
    $decoded = JWTHandler::verifyAccessToken($token);
    $userId = $decoded['user_id'];

    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        error_log("Withdrawal request error: Invalid JSON input");
        ApiResponse::error('Invalid JSON input', 400);
    }

    $groupId = $input['group_id'] ?? null;
    $amount = $input['amount'] ?? null;
    $purpose = $input['purpose'] ?? null;

    if (!$groupId || !$amount || !$purpose) {
        error_log("Withdrawal request error: Missing required fields");
        ApiResponse::error('Missing required fields', 400);
    }

    $group = new Group();
    $groupData = $group->findById($groupId);
    if (!$groupData) {
        error_log("Withdrawal request error: Group not found");
        ApiResponse::error('Group not found', 404);
    }

    $groupMember = new GroupMember();
    if (!$groupMember->isMember($groupId, $userId)) {
        error_log("Withdrawal request error: User not a member of group");
        ApiResponse::error('You are not a member of this group', 400);
    }

    // Check if group has sufficient funds
    if ($groupData['total_funds'] < $amount) {
        error_log("Withdrawal request error: Insufficient group funds");
        ApiResponse::error('Insufficient group funds', 400);
    }

    // Get database connection
    $database = new Database();
    $conn = $database->getConnection();

    // Create withdrawal request
    $query = "INSERT INTO withdrawal_requests (user_id, group_id, amount, purpose) 
              VALUES (:user_id, :group_id, :amount, :purpose)";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $userId);
    $stmt->bindParam(':group_id', $groupId);
    $stmt->bindParam(':amount', $amount);
    $stmt->bindParam(':purpose', $purpose);
    
    if ($stmt->execute()) {
        error_log("Withdrawal request success: User $userId requested $amount from group $groupId");
        ApiResponse::success(['message' => 'Withdrawal request submitted successfully'], 'Withdrawal request submitted');
    } else {
        error_log("Withdrawal request error: Failed to create request");
        ApiResponse::error('Failed to create withdrawal request', 500);
    }

} catch (Exception $e) {
    error_log("Withdrawal request error: " . $e->getMessage());
    ApiResponse::error('Internal server error: ' . $e->getMessage(), 500);
}
?> 