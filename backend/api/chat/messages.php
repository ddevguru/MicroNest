<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';

header('Content-Type: application/json');

ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    error_log("Get chat messages error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Get chat messages error: Missing or invalid token");
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        error_log("Get chat messages error: Invalid or expired token");
        ApiResponse::error('Invalid or expired token', 401);
    }

    $groupId = $_GET['group_id'] ?? null;
    if (!$groupId) {
        error_log("Get chat messages error: Group ID required");
        ApiResponse::error('Group ID is required', 400);
    }

    $database = new Database();
    $conn = $database->getConnection();

    // Check if user is member of the group
    $checkQuery = "SELECT id FROM group_members WHERE group_id = :group_id AND user_id = :user_id";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':group_id', $groupId);
    $checkStmt->bindParam(':user_id', $userId);
    $checkStmt->execute();
    
    if (!$checkStmt->fetch()) {
        error_log("Get chat messages error: User not member of group - User ID: $userId, Group ID: $groupId");
        ApiResponse::error('You are not a member of this group', 403);
    }

    // Get messages with user details
    $query = "SELECT gm.*, u.full_name as sender_name 
              FROM group_messages gm 
              LEFT JOIN users u ON gm.user_id = u.id 
              WHERE gm.group_id = :group_id 
              ORDER BY gm.created_at ASC";
    
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':group_id', $groupId);
    $stmt->execute();
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    error_log("Get chat messages successful: Group ID = $groupId, User ID = $userId, Messages count = " . count($messages));
    ApiResponse::success($messages, 'Messages fetched successfully');

} catch (Exception $e) {
    error_log("Get chat messages error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}
?> 