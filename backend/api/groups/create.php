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
    error_log("Create group error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    error_log("Create group attempt: Raw input = " . file_get_contents('php://input'));

    if (!$input) {
        error_log("Create group error: Invalid JSON input");
        ApiResponse::error('Invalid JSON input', 400);
    }

    if (empty($input['name']) || empty($input['description']) || empty($input['contribution_amount']) || empty($input['max_members'])) {
        error_log("Create group error: Missing required fields");
        ApiResponse::error('Name, description, contribution amount, and max members are required', 400);
    }

    $name = trim($input['name']);
    $description = trim($input['description']);
    $contribution_amount = floatval($input['contribution_amount']);
    $max_members = intval($input['max_members']);

    if ($contribution_amount <= 0) {
        error_log("Create group error: Invalid contribution amount");
        ApiResponse::error('Contribution amount must be greater than 0', 400);
    }

    if ($max_members <= 0) {
        error_log("Create group error: Invalid max members");
        ApiResponse::error('Max members must be greater than 0', 400);
    }

    // Verify JWT token
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Create group error: Missing or invalid token");
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        error_log("Create group error: Invalid or expired token");
        ApiResponse::error('Invalid or expired token', 401);
    }

    $user = new User();
    $userData = $user->findById($userId);
    if (!$userData || $userData['status'] !== 'active' || $userData['email_verified'] != 1) {
        error_log("Create group error: User not found or not active/verified");
        ApiResponse::error('User not found or not authorized', 403);
    }

    $group = new Group();
    $groupData = [
        'name' => $name,
        'description' => $description,
        'contribution_amount' => $contribution_amount,
        'max_members' => $max_members,
        'total_funds' => 0.00,
        'created_by' => $userId,
        'created_at' => date('Y-m-d H:i:s'),
    ];

    $groupId = $group->create($groupData);
    if (!$groupId) {
        error_log("Create group error: Failed to create group");
        ApiResponse::serverError('Failed to create group');
    }

    // Try to add creator as admin, but don't fail if it doesn't work
    try {
        $groupMember = new GroupMember();
        $memberAdded = $groupMember->addMember($groupId, $userId, 0.00, 'admin');
        if ($memberAdded) {
            error_log("Creator added as admin successfully");
        } else {
            error_log("Warning: Failed to add creator as admin, but group was created");
        }
    } catch (Exception $e) {
        error_log("Warning: Exception adding creator as admin: " . $e->getMessage());
    }

    error_log("Create group successful: Group ID = $groupId, User ID = $userId");
    ApiResponse::success([
        'group_id' => $groupId,
        'name' => $name,
        'description' => $description,
        'contribution_amount' => $contribution_amount,
        'max_members' => $max_members,
        'created_by' => $userId,
    ], 'Group created successfully');

} catch (Exception $e) {
    error_log("Create group error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}
?>