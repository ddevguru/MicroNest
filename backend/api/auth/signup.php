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
    error_log("Signup error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    error_log("Signup attempt: Raw input = " . file_get_contents('php://input'));

    if (!$input) {
        error_log("Signup error: Invalid JSON input");
        ApiResponse::error('Invalid JSON input', 400);
    }

    $requiredFields = ['full_name', 'email', 'username', 'password', 'phone', 'address'];
    foreach ($requiredFields as $field) {
        if (!isset($input[$field]) || empty(trim($input[$field]))) {
            error_log("Signup error: Missing or empty required field - $field");
            ApiResponse::error("Missing required field: $field", 400);
        }
    }

    $email = strtolower(trim($input['email']));
    $username = trim($input['username']);
    $password = $input['password'];

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        error_log("Signup error: Invalid email format - $email");
        ApiResponse::error('Invalid email format', 400);
    }

    $user = new User();
    error_log("Checking if email exists: $email");
    if ($user->emailExists($email)) {
        error_log("Signup error: Email already exists - $email");
        ApiResponse::error('Email already exists', 409);
    }

    error_log("Checking if username exists: $username");
    if ($user->usernameExists($username)) {
        error_log("Signup error: Username already exists - $username");
        ApiResponse::error('Username already exists', 409);
    }

    $userData = [
        'full_name' => $input['full_name'],
        'email' => $email,
        'username' => $username,
        'password' => $password,
        'phone' => $input['phone'],
        'address' => $input['address'],
        'profile_image' => $input['profile_image'] ?? null,
    ];

    error_log("Attempting to create user: Email = $email, Username = $username");
    $userId = $user->create($userData);

    if (!$userId) {
        error_log("Signup error: Failed to create user for email = $email. Check database logs for SQL errors.");
        ApiResponse::serverError('Failed to create user');
    }

    error_log("User created successfully: User ID = $userId");
    $userData = $user->findById($userId);
    if (!$userData) {
        error_log("Signup error: Failed to retrieve user data for ID = $userId");
        ApiResponse::success(['user_id' => $userId], 'User created but failed to retrieve user data', 201);
    }

    $userResponse = $user->getUserData($userData);

    error_log("Generating access token for user ID = $userId, Email = {$userData['email']}");
    try {
        $accessToken = JWTHandler::generateAccessToken($userData['id'], $userData['email']);
        if (!$accessToken) {
            error_log("Signup error: Failed to generate access token for user ID = $userId");
            ApiResponse::success(['user_id' => $userId, 'user' => $userResponse], 'User created but failed to generate access token', 201);
        }
    } catch (Exception $e) {
        error_log("Signup error: Access token generation failed: " . $e->getMessage());
        ApiResponse::success(['user_id' => $userId, 'user' => $userResponse], 'User created but failed to generate access token', 201);
    }

    error_log("Generating refresh token for user ID = $userId");
    try {
        $refreshToken = JWTHandler::generateRefreshToken($userData['id']);
        if (!$refreshToken) {
            error_log("Signup error: Failed to generate refresh token for user ID = $userId");
            ApiResponse::success(['user_id' => $userId, 'access_token' => $accessToken, 'user' => $userResponse], 'User created but failed to generate refresh token', 201);
        }
    } catch (Exception $e) {
        error_log("Signup error: Refresh token generation failed: " . $e->getMessage());
        ApiResponse::success(['user_id' => $userId, 'access_token' => $accessToken, 'user' => $userResponse], 'User created but failed to generate refresh token', 201);
    }

    error_log("Storing refresh token for user ID = $userId");
    try {
        $refreshTokenModel = new RefreshToken();
        if (!$refreshTokenModel->store($userData['id'], $refreshToken)) {
            $errorInfo = $refreshTokenModel->getConnection()->errorInfo();
            error_log("Signup error: Failed to store refresh token for user ID = $userId. SQL Error: " . json_encode($errorInfo));
            ApiResponse::success(
                ['user_id' => $userId, 'access_token' => $accessToken, 'user' => $userResponse],
                'User created but failed to store refresh token',
                201
            );
        }
    } catch (Exception $e) {
        error_log("Signup error: Refresh token storage failed: " . $e->getMessage() . " | Trace: " . $e->getTraceAsString());
        ApiResponse::success(
            ['user_id' => $userId, 'access_token' => $accessToken, 'user' => $userResponse],
            'User created but failed to store refresh token',
            201
        );
    }

    error_log("Signup successful: Email = $email, User ID = $userId");
    ApiResponse::success([
        'access_token' => $accessToken,
        'refresh_token' => $refreshToken,
        'user' => $userResponse
    ], 'Account created successfully', 201);

} catch (Exception $e) {
    error_log("Signup error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine() . " | Trace: " . $e->getTraceAsString());
    ApiResponse::serverError('An unexpected error occurred');
}
?>