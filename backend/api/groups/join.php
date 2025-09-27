<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';
require_once __DIR__ . '/../../models/User.php';
require_once __DIR__ . '/../../models/Group.php';
require_once __DIR__ . '/../../models/GroupMember.php';

header('Content-Type: application/json');

// Enable error logging
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log("Join group error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    error_log("Join group attempt: Raw input = " . file_get_contents('php://input'));

    if (!$input || empty($input['group_id']) || empty($input['amount']) || empty($input['payment_method'])) {
        error_log("Join group error: Missing required fields");
        ApiResponse::error('Group ID, amount, and payment method are required', 400);
    }

    $groupId = intval($input['group_id']);
    $amount = floatval($input['amount']);
    $paymentMethod = trim($input['payment_method']);

    if ($amount <= 0) {
        error_log("Join group error: Invalid amount");
        ApiResponse::error('Amount must be greater than 0', 400);
    }

    $validPaymentMethods = ['cash', 'bank_transfer', 'mobile_money'];
    if (!in_array($paymentMethod, $validPaymentMethods)) {
        error_log("Join group error: Invalid payment method - $paymentMethod");
        ApiResponse::error('Invalid payment method', 400);
    }

    // Verify JWT token
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Join group error: Missing or invalid token");
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        error_log("Join group error: Invalid or expired token");
        ApiResponse::error('Invalid or expired token', 401);
    }

    $user = new User();
    $userData = $user->findById($userId);
    if (!$userData || $userData['status'] !== 'active' || $userData['email_verified'] != 1) {
        error_log("Join group error: User not found or not active/verified");
        ApiResponse::error('User not found or not authorized', 403);
    }

    $group = new Group();
    $groupData = $group->findById($groupId);
    if (!$groupData) {
        error_log("Join group error: Group not found - ID: $groupId");
        ApiResponse::error('Group not found', 404);
    }

    if ($groupData['current_members'] >= $groupData['max_members']) {
        error_log("Join group error: Group is full - ID: $groupId");
        ApiResponse::error('Group is full', 400);
    }

    if ($amount < $groupData['contribution_amount']) {
        error_log("Join group error: Amount less than required - $amount < {$groupData['contribution_amount']}");
        ApiResponse::error('Amount must be at least ₹' . $groupData['contribution_amount'], 400);
    }

    $groupMember = new GroupMember();
    if ($groupMember->isMember($groupId, $userId)) {
        error_log("Join group error: User already in group - User ID: $userId, Group ID: $groupId");
        ApiResponse::error('You are already a member of this group', 400);
    }

    // Begin transaction for atomic updates
    $group->getConnection()->beginTransaction();

    try {
        $memberData = [
            'group_id' => $groupId,
            'user_id' => $userId,
            'role' => 'member',
            'total_contributed' => $amount,
            'last_contribution_date' => date('Y-m-d H:i:s'),
            'joined_at' => date('Y-m-d H:i:s'),
        ];

        if (!$groupMember->create($memberData)) {
            throw new Exception('Failed to add user to group');
        }

        // Update group's current_members and total_funds
        $groupUpdate = [
            'current_members' => $groupData['current_members'] + 1,
            'total_funds' => $groupData['total_funds'] + $amount,
        ];

        if (!$group->update($groupId, $groupUpdate)) {
            throw new Exception('Failed to update group');
        }

        $group->getConnection()->commit();

        error_log("Join group successful: Group ID = $groupId, User ID = $userId, Amount = $amount");
        ApiResponse::success([
            'group_id' => $groupId,
            'user_id' => $userId,
            'amount' => $amount,
            'payment_method' => $paymentMethod,
        ], 'Successfully joined group');

    } catch (Exception $e) {
        $group->getConnection()->rollBack();
        error_log("Join group error: " . $e->getMessage());
        ApiResponse::serverError('Failed to join group');
    }

} catch (Exception $e) {
    error_log("Join group error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}
?>