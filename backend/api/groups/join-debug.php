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
ini_set('display_errors', 1);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || empty($input['group_id']) || empty($input['amount']) || empty($input['payment_method'])) {
        ApiResponse::error('Group ID, amount, and payment method are required', 400);
    }

    $groupId = intval($input['group_id']);
    $amount = floatval($input['amount']);
    $paymentMethod = trim($input['payment_method']);

    if ($amount <= 0) {
        ApiResponse::error('Amount must be greater than 0', 400);
    }

    $validPaymentMethods = ['cash', 'bank_transfer', 'mobile_money', 'razorpay'];
    if (!in_array($paymentMethod, $validPaymentMethods)) {
        ApiResponse::error('Invalid payment method', 400);
    }

    // Verify JWT token
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        ApiResponse::error('Invalid or expired token', 401);
    }

    $user = new User();
    $userData = $user->findById($userId);
    if (!$userData || $userData['status'] !== 'active' || $userData['email_verified'] != 1) {
        ApiResponse::error('User not found or not authorized', 403);
    }

    $group = new Group();
    $groupData = $group->findById($groupId);
    if (!$groupData) {
        ApiResponse::error('Group not found', 404);
    }

    if ($groupData['current_members'] >= $groupData['max_members']) {
        ApiResponse::error('Group is full', 400);
    }

    if ($amount < $groupData['contribution_amount']) {
        ApiResponse::error('Amount must be at least ₹' . $groupData['contribution_amount'], 400);
    }

    $groupMember = new GroupMember();
    if ($groupMember->isMember($groupId, $userId)) {
        ApiResponse::error('You are already a member of this group', 400);
    }

    // Test database connection
    $database = new Database();
    $conn = $database->getConnection();
    
    // Test GroupMember creation
    $memberData = [
        'group_id' => $groupId,
        'user_id' => $userId,
        'role' => 'member',
        'total_contributed' => $amount,
        'last_contribution_date' => date('Y-m-d H:i:s'),
        'joined_at' => date('Y-m-d H:i:s'),
    ];

    $memberCreated = $groupMember->create($memberData);
    if (!$memberCreated) {
        ApiResponse::error('Failed to add user to group', 500);
    }

    // Test Group update
    $groupUpdate = [
        'current_members' => $groupData['current_members'] + 1,
        'total_funds' => $groupData['total_funds'] + $amount,
    ];

    $groupUpdated = $group->update($groupId, $groupUpdate);
    if (!$groupUpdated) {
        ApiResponse::error('Failed to update group', 500);
    }

    ApiResponse::success([
        'group_id' => $groupId,
        'user_id' => $userId,
        'amount' => $amount,
        'payment_method' => $paymentMethod,
        'debug' => 'All steps completed successfully'
    ], 'Successfully joined group');

} catch (Exception $e) {
    ApiResponse::error('Error: ' . $e->getMessage() . ' in ' . $e->getFile() . ' on line ' . $e->getLine(), 500);
}
?> 