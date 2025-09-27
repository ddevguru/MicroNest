<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../models/OTP.php';
require_once __DIR__ . '/../../models/User.php';

header('Content-Type: application/json');

// Enable error logging, disable display
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || empty($input['email']) || empty($input['otp'])) {
        error_log("Verify OTP error: Email or OTP missing");
        ApiResponse::error('Email and OTP are required', 400);
    }

    $email = strtolower(trim($input['email']));
    $otp = trim($input['otp']);

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        error_log("Verify OTP error: Invalid email format - $email");
        ApiResponse::error('Invalid email format', 400);
    }

    error_log("Verify OTP attempt: Email = $email, OTP = $otp");

    $otpModel = new OTP();
    if (!$otpModel->verify($email, $otp)) {
        error_log("Verify OTP error: Invalid OTP for email = $email");
        ApiResponse::error('Invalid OTP', 401);
    }

    // Optional: Update email_verified if user exists
    $user = new User();
    $userData = $user->findByEmail($email);
    if ($userData) {
        if (!$user->verifyEmail($email)) {
            error_log("Verify OTP error: Failed to update email_verified for $email");
            ApiResponse::error('Failed to verify email', 500);
        }
        error_log("Email verified successfully for $email");
    } else {
        error_log("Verify OTP warning: User not found for email = $email, but OTP verified");
    }

    // Delete OTPs for the email
    if (!$otpModel->deleteByEmail($email)) {
        error_log("Verify OTP warning: Failed to delete OTPs for $email");
    }

    ApiResponse::success([], 'OTP verified successfully');

} catch (Exception $e) {
    error_log("Verify OTP error: " . $e->getMessage() . " | File: " . $e->getFile() . " | Line: " . $e->getLine());
    ApiResponse::serverError('An unexpected error occurred');
}