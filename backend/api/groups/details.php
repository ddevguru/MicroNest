<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';
require_once __DIR__ . '/../../models/Group.php';
require_once __DIR__ . '/../../models/GroupMember.php';

header('Content-Type: application/json');

ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    error_log("Get group details error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Get group details error: Missing or invalid token");
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        error_log("Get group details error: Invalid or expired token");
        ApiResponse::error('Invalid or expired token', 401);
    }

    $groupId = $_GET['id'] ?? null;
    if (!$groupId) {
        error_log("Get group details error: Group ID required");
        ApiResponse::error('Group ID is required', 400);
    }

    $group = new Group();
    $groupData = $group->findById($groupId);
    if (!$groupData) {
        error_log("Get group details error: Group not found - ID: $groupId");
        ApiResponse::error('Group not found', 404);
    }

    $groupMember = new GroupMember();
    $members = $groupMember->getGroupMembers($groupId);
    $isMember = $groupMember->isMember($groupId, $userId);

    $responseData = [
        'group' => $groupData,
        'members' => $members,
        'is_member' => $isMember,
        'member_count' => count($members)
    ];

    error_log("Get group details successful: Group ID = $groupId, User ID = $userId");
    ApiResponse::success($responseData, 'Group details fetched successfully');

} catch (Exception $e) {
    error_log("Get group details error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}
?> 