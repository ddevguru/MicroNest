<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';
require_once __DIR__ . '/../../models/User.php';
require_once __DIR__ . '/../../models/RefreshToken.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

try {
    // Get refresh token from Authorization header
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';

    if (!$authHeader || !preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        ApiResponse::unauthorized('Refresh token required');
    }

    $refreshToken = $matches[1];

    // Verify refresh token
    $refreshTokenModel = new RefreshToken();
    $userId = $refreshTokenModel->verify($refreshToken);

    if (!$userId) {
        ApiResponse::unauthorized('Invalid or expired refresh token');
    }

    // Get user data
    $user = new User();
    $userData = $user->findById($userId);

    if (!$userData) {
        ApiResponse::unauthorized('User not found');
    }

    // Generate new tokens
    $newAccessToken = JWTHandler::generateAccessToken($userData['id'], $userData['email']);
    $newRefreshToken = JWTHandler::generateRefreshToken($userData['id']);

    // Store new refresh token and delete old one
    $refreshTokenModel->deleteByToken($refreshToken);
    $refreshTokenModel->store($userData['id'], $newRefreshToken);

    ApiResponse::success([
        'access_token' => $newAccessToken,
        'refresh_token' => $newRefreshToken
    ], 'Tokens refreshed successfully');

} catch (Exception $e) {
    error_log("Refresh token error: " . $e->getMessage());
    ApiResponse::serverError('An unexpected error occurred');
}
?>
