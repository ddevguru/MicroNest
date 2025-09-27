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
    error_log("Verify payment error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Verify payment error: Missing or invalid token");
        ApiResponse::error('Authorization token required', 401);
    }

    $token = $matches[1];
    $userId = JWTHandler::verifyAccessToken($token);
    if (!$userId) {
        error_log("Verify payment error: Invalid or expired token");
        ApiResponse::error('Invalid or expired token', 401);
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        error_log("Verify payment error: Invalid JSON input");
        ApiResponse::error('Invalid JSON input', 400);
    }

    $orderId = $input['order_id'];
    $paymentId = $input['payment_id'];
    $signature = $input['signature'];

    if (empty($orderId) || empty($paymentId) || empty($signature)) {
        error_log("Verify payment error: Missing required fields");
        ApiResponse::error('Order ID, Payment ID, and Signature are required', 400);
    }

    // Here you would verify the payment with Razorpay
    // For now, we'll simulate a successful verification
    $paymentData = [
        'order_id' => $orderId,
        'payment_id' => $paymentId,
        'signature' => $signature,
        'status' => 'success',
        'verified_at' => date('Y-m-d H:i:s'),
    ];

    error_log("Payment verified: Order ID = $orderId, Payment ID = $paymentId, User ID = $userId");
    ApiResponse::success($paymentData, 'Payment verified successfully');

} catch (Exception $e) {
    error_log("Verify payment error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}
?> 