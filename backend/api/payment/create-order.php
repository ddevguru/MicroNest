<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';

header('Content-Type: application/json');

ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log("Create payment order error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Create payment order error: Missing or invalid token");
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        error_log("Create payment order error: Invalid or expired token");
        ApiResponse::error('Invalid or expired token', 401);
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        error_log("Create payment order error: Invalid JSON input");
        ApiResponse::error('Invalid JSON input', 400);
    }

    $amount = intval($input['amount']);
    $currency = $input['currency'] ?? 'INR';
    $receipt = $input['receipt'] ?? 'receipt_' . time();
    $notes = $input['notes'] ?? [];

    if ($amount <= 0) {
        error_log("Create payment order error: Invalid amount");
        ApiResponse::error('Amount must be greater than 0', 400);
    }

    // Here you would integrate with Razorpay API
    // For now, we'll create a mock order
    $orderData = [
        'id' => 'order_' . time() . '_' . $userId,
        'amount' => $amount,
        'currency' => $currency,
        'receipt' => $receipt,
        'status' => 'created',
        'created_at' => date('Y-m-d H:i:s'),
    ];

    error_log("Payment order created: Order ID = {$orderData['id']}, Amount = $amount, User ID = $userId");
    ApiResponse::success($orderData, 'Payment order created successfully');

} catch (Exception $e) {
    error_log("Create payment order error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}
?> 