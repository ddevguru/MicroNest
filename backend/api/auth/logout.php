<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';
require_once __DIR__ . '/../../models/RefreshToken.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

try {
    // Get access token from Authorization header
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';

    if ($authHeader && preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        $accessToken = $matches[1];
        $userId = JWTHandler::getUserFromToken($accessToken);

        if ($userId) {
            // Delete all refresh tokens for this user
            $refreshTokenModel = new RefreshToken();
            $refreshTokenModel->deleteByUserId($userId);
        }
    }

    ApiResponse::success(null, 'Logged out successfully');

} catch (Exception $e) {
    error_log("Logout error: " . $e->getMessage());
    ApiResponse::success(null, 'Logged out successfully'); // Always return success for logout
}
?>
