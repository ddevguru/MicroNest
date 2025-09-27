<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';
require_once __DIR__ . '/../../models/User.php';
require_once __DIR__ . '/../../models/RefreshToken.php';

header('Content-Type: application/json');

// Enable error logging, disable display
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log("Login error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    error_log("Login attempt: Raw input = " . file_get_contents('php://input'));

    if (!$input) {
        error_log("Login error: Invalid JSON input");
        ApiResponse::error('Invalid JSON input', 400);
    }

    if (empty($input['email']) || empty($input['password'])) {
        error_log("Login error: Email or password missing");
        ApiResponse::error('Email and password are required', 400);
    }

    $email = strtolower(trim($input['email']));
    $password = $input['password'];

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        error_log("Login error: Invalid email format - $email");
        ApiResponse::error('Invalid email format', 400);
    }

    error_log("Login attempt: Email = $email");

    $user = new User();
    $userData = $user->findByEmail($email);

    if (!$userData) {
        error_log("Login error: No user found for email = $email");
        ApiResponse::error('Invalid email or password', 401);
    }

    error_log("User found: ID = {$userData['id']}, Email = {$userData['email']}");

    // Verify password using MD5 (WARNING: MD5 is insecure; consider Argon2 or bcrypt for production)
    if (md5($password) !== $userData['password_hash']) {
        error_log("Login error: Password verification failed for email = $email");
        ApiResponse::error('Invalid email or password', 401);
    }

    if ($userData['email_verified'] != 1) {
        error_log("Login error: Email not verified for email = $email");
        ApiResponse::error('Email not verified. Please verify your email.', 403);
    }

    if ($userData['status'] !== 'active') {
        error_log("Login error: Account not active for email = $email");
        ApiResponse::error('Account is not active. Please contact support.', 403);
    }

    error_log("Generating access token for user ID = {$userData['id']}");
    $accessToken = JWTHandler::generateAccessToken($userData['id'], $userData['email']);
    if (!$accessToken) {
        error_log("Login error: Failed to generate access token for user ID = {$userData['id']}");
        ApiResponse::serverError('Failed to generate access token');
    }

    error_log("Generating refresh token for user ID = {$userData['id']}");
    $refreshToken = JWTHandler::generateRefreshToken($userData['id']);
    if (!$refreshToken) {
        error_log("Login error: Failed to generate refresh token for user ID = {$userData['id']}");
        ApiResponse::serverError('Failed to generate refresh token');
    }

    error_log("Storing refresh token for user ID = {$userData['id']}");
    $refreshTokenModel = new RefreshToken();
    if (!$refreshTokenModel->store($userData['id'], $refreshToken)) {
        $errorInfo = $refreshTokenModel->getConnection()->errorInfo();
        error_log("Login error: Failed to store refresh token for user ID = {$userData['id']}. SQL Error: " . json_encode($errorInfo));
        ApiResponse::serverError('Failed to store refresh token');
    }

    $userResponse = $user->getUserData($userData);

    error_log("Login successful: Email = $email, User ID = {$userData['id']}");

    ApiResponse::success([
        'access_token' => $accessToken,
        'refresh_token' => $refreshToken,
        'user' => $userResponse
    ], 'Login successful');

} catch (Exception $e) {
    error_log("Login error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine() . " | Trace: " . $e->getTraceAsString());
    ApiResponse::serverError('An unexpected error occurred');
}
?>