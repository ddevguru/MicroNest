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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log("Send chat message error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Send chat message error: Missing or invalid token");
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        error_log("Send chat message error: Invalid or expired token");
        ApiResponse::error('Invalid or expired token', 401);
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        error_log("Send chat message error: Invalid JSON input");
        ApiResponse::error('Invalid JSON input', 400);
    }

    $groupId = $input['group_id'] ?? null;
    $message = trim($input['message'] ?? '');

    if (!$groupId || empty($message)) {
        error_log("Send chat message error: Missing required fields");
        ApiResponse::error('Group ID and message are required', 400);
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
        error_log("Send chat message error: User not member of group - User ID: $userId, Group ID: $groupId");
        ApiResponse::error('You are not a member of this group', 403);
    }

    // Insert message
    $insertQuery = "INSERT INTO group_messages (group_id, user_id, message, message_type) 
                    VALUES (:group_id, :user_id, :message, 'text')";
    $insertStmt = $conn->prepare($insertQuery);
    $insertStmt->bindParam(':group_id', $groupId);
    $insertStmt->bindParam(':user_id', $userId);
    $insertStmt->bindParam(':message', $message);
    
    if (!$insertStmt->execute()) {
        error_log("Send chat message error: Failed to insert message");
        ApiResponse::serverError('Failed to send message');
    }

    $messageId = $conn->lastInsertId();

    // Get user details for response
    $userQuery = "SELECT full_name FROM users WHERE id = :user_id";
    $userStmt = $conn->prepare($userQuery);
    $userStmt->bindParam(':user_id', $userId);
    $userStmt->execute();
    $userData = $userStmt->fetch(PDO::FETCH_ASSOC);

    $messageData = [
        'id' => $messageId,
        'group_id' => $groupId,
        'user_id' => $userId,
        'message' => $message,
        'sender_name' => $userData['full_name'] ?? 'User',
        'created_at' => date('Y-m-d H:i:s'),
    ];

    error_log("Chat message sent: Group ID = $groupId, User ID = $userId, Message ID = $messageId");
    ApiResponse::success($messageData, 'Message sent successfully');

} catch (Exception $e) {
    error_log("Send chat message error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}
?> 