<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/email.php';
require_once __DIR__ . '/../../models/OTP.php';
require_once __DIR__ . '/../../models/User.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || empty($input['email'])) {
        error_log("Send OTP error: Email missing");
        ApiResponse::error('Email is required', 400);
    }

    $email = strtolower(trim($input['email']));

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        error_log("Send OTP error: Invalid email format - $email");
        ApiResponse::error('Invalid email format', 400);
    }

    // Optional: Remove user existence check to allow OTP for signup
    $user = new User();
    $existingUser = $user->findByEmail($email);
    /*
    if (!$existingUser) {
        error_log("Send OTP error: User not found for email - $email");
        ApiResponse::error('User not found', 404);
    }
    */

    $otpModel = new OTP();
    $otp = $otpModel->generate($email);

    if (!$otp) {
        error_log("Send OTP error: Failed to generate OTP for $email");
        ApiResponse::serverError('Failed to generate OTP');
    }

    $fullName = $existingUser ? $existingUser['full_name'] : 'User';
    $emailSent = EmailService::sendOTP($email, $otp, $fullName);

    if (!$emailSent) {
        error_log("Send OTP error: Failed to send OTP email to $email");
        ApiResponse::serverError('Failed to send OTP email');
    }

    error_log("OTP sent successfully to $email: $otp");
    ApiResponse::success(null, 'OTP sent successfully to your email');

} catch (Exception $e) {
    error_log("Send OTP error: " . $e->getMessage());
    ApiResponse::serverError('An unexpected error occurred');
}