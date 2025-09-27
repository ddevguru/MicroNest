<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';
require_once __DIR__ . '/../../models/Group.php';
require_once __DIR__ . '/../../models/GroupMember.php';

header('Content-Type: application/json');

ini_set('display_errors', 1);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $decoded = JWTHandler::verifyAccessToken($token);
    $userId = $decoded['user_id'];

    // Accept both 'id' and 'group_id' parameters
    $groupId = $_GET['group_id'] ?? $_GET['id'] ?? null;
    if (!$groupId) {
        ApiResponse::error('Group ID is required', 400);
    }

    // Test database connection
    $database = new Database();
    $conn = $database->getConnection();
    
    // Check if groups table exists
    $stmt = $conn->query("SHOW TABLES LIKE 'groups'");
    $groupsTableExists = $stmt->fetch();
    
    // Check if group_members table exists
    $stmt = $conn->query("SHOW TABLES LIKE 'group_members'");
    $groupMembersTableExists = $stmt->fetch();

    $group = new Group();
    $groupData = $group->findById($groupId);
    
    if (!$groupData) {
        ApiResponse::error('Group not found', 404);
    }

    // Try to get members if table exists
    $members = [];
    $isMember = false;
    
    if ($groupMembersTableExists) {
        $groupMember = new GroupMember();
        $members = $groupMember->getGroupMembers($groupId);
        $isMember = $groupMember->isMember($groupId, $userId);
    }

    $responseData = [
        'group' => $groupData,
        'members' => $members,
        'is_member' => $isMember,
        'member_count' => count($members),
        'debug' => [
            'groups_table_exists' => $groupsTableExists ? true : false,
            'group_members_table_exists' => $groupMembersTableExists ? true : false,
            'group_id' => $groupId,
            'user_id' => $userId
        ]
    ];

    ApiResponse::success($responseData, 'Group details fetched successfully');

} catch (Exception $e) {
    ApiResponse::error('Error: ' . $e->getMessage() . ' | File: ' . $e->getFile() . ' | Line: ' . $e->getLine(), 500);
}
?> 