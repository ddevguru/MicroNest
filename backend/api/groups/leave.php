<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';
require_once __DIR__ . '/../../models/GroupMember.php';
require_once __DIR__ . '/../../models/Group.php';

header('Content-Type: application/json');

ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log("Leave group error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Leave group error: Missing or invalid token");
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        error_log("Leave group error: Invalid or expired token");
        ApiResponse::error('Invalid or expired token', 401);
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input || !isset($input['group_id'])) {
        error_log("Leave group error: Missing group_id");
        ApiResponse::error('Missing group_id', 400);
    }

    $groupId = $input['group_id'];
    $groupMember = new GroupMember();
    $isMember = $groupMember->isMember($groupId, $userId);
    if (!$isMember) {
        error_log("Leave group error: User is not a member of group ID: $groupId");
        ApiResponse::error('You are not a member of this group', 403);
    }

    $group = new Group();
    $groupData = $group->findById($groupId);
    if (!$groupData) {
        error_log("Leave group error: Group not found - ID: $groupId");
        ApiResponse::error('Group not found', 404);
    }

    if ($groupData['created_by'] == $userId) {
        error_log("Leave group error: Admin cannot leave group - ID: $groupId");
        ApiResponse::error('Group admin cannot leave the group', 403);
    }

    $groupMember->removeMember($groupId, $userId);
    $group->updateMemberCount($groupId, -1);

    error_log("Leave group successful: User ID = $userId, Group ID = $groupId");
    ApiResponse::success([], 'Successfully left the group');

} catch (Exception $e) {
    error_log("Leave group error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}
?>