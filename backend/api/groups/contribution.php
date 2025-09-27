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
    error_log("Make contribution error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Make contribution error: Missing or invalid token");
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        error_log("Make contribution error: Invalid or expired token");
        ApiResponse::error('Invalid or expired token', 401);
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        error_log("Make contribution error: Invalid JSON input");
        ApiResponse::error('Invalid JSON input', 400);
    }

    $groupId = $input['group_id'] ?? null;
    $amount = floatval($input['amount'] ?? 0);

    if (!$groupId || $amount <= 0) {
        error_log("Make contribution error: Missing or invalid fields");
        ApiResponse::error('Group ID and valid amount are required', 400);
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
        error_log("Make contribution error: User not member of group - User ID: $userId, Group ID: $groupId");
        ApiResponse::error('You are not a member of this group', 403);
    }

    // Insert contribution record
    $insertQuery = "INSERT INTO group_contributions (group_id, user_id, amount, payment_method, status) 
                    VALUES (:group_id, :user_id, :amount, 'razorpay', 'pending')";
    $insertStmt = $conn->prepare($insertQuery);
    $insertStmt->bindParam(':group_id', $groupId);
    $insertStmt->bindParam(':user_id', $userId);
    $insertStmt->bindParam(':amount', $amount);
    
    if (!$insertStmt->execute()) {
        error_log("Make contribution error: Failed to insert contribution");
        ApiResponse::serverError('Failed to record contribution');
    }

    $contributionId = $conn->lastInsertId();

    error_log("Contribution recorded: Group ID = $groupId, User ID = $userId, Amount = $amount, Contribution ID = $contributionId");
    ApiResponse::success([
        'contribution_id' => $contributionId,
        'group_id' => $groupId,
        'amount' => $amount,
        'status' => 'pending'
    ], 'Contribution recorded successfully');

} catch (Exception $e) {
    error_log("Make contribution error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}
?> 