<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/includes/cors.php';
require_once __DIR__ . '/includes/response.php';

header('Content-Type: application/json');

// Simple router
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];

// Remove query string and leading slash
$path = strtok($requestUri, '?');
$path = trim($path, '/');

// API routes
$routes = [
    // Auth routes
    'POST /api/auth/signup' => 'api/auth/signup.php',
    'POST /api/auth/login' => 'api/auth/login.php',
    'POST /api/auth/send-otp' => 'api/auth/send-otp.php',
    'POST /api/auth/verify-otp' => 'api/auth/verify-otp.php',
    'POST /api/auth/refresh' => 'api/auth/refresh.php',
    'POST /api/auth/logout' => 'api/auth/logout.php',
    
    // Groups routes
    'GET /api/groups/available' => 'api/groups/available.php',
    'GET /api/groups/user-groups' => 'api/groups/user-groups.php',
    'GET /api/groups/details' => 'api/groups/details.php',
    'POST /api/groups/create' => 'api/groups/create.php',
    'POST /api/groups/join' => 'api/groups/join.php',
    'POST /api/groups/leave' => 'api/groups/leave.php',
    
    // Payment routes
    'POST /api/payment/create-order' => 'api/payment/create-order.php',
    'POST /api/payment/verify' => 'api/payment/verify.php',
    
    // Group actions routes
    'POST /api/groups/contribution' => 'api/groups/contribution.php',
    'POST /api/groups/withdrawal' => 'api/groups/withdrawal.php',
    'POST /api/groups/loan' => 'api/groups/loan.php',
    
    // Chat routes
    'GET /api/chat/messages' => 'api/chat/messages.php',
    'POST /api/chat/send' => 'api/chat/send.php',
    
    // Direct file access routes (for backward compatibility)
    'GET /groups/available.php' => 'api/groups/available.php',
    'GET /groups/user-groups.php' => 'api/groups/user-groups.php',
    'GET /groups/details.php' => 'api/groups/details.php',
    'POST /groups/create.php' => 'api/groups/create.php',
    'POST /groups/join.php' => 'api/groups/join.php',
    'POST /groups/leave.php' => 'api/groups/leave.php',
];

$routeKey = $requestMethod . ' /' . $path;

if (isset($routes[$routeKey])) {
    require_once __DIR__ . '/' . $routes[$routeKey];
} else {
    // Default response for root path
    if ($path === '' || $path === 'api') {
        ApiResponse::success([
            'name' => 'MicroNest API',
            'version' => '1.0.0',
            'endpoints' => [
                'POST /api/auth/signup' => 'Create new user account',
                'POST /api/auth/login' => 'User login',
                'POST /api/auth/send-otp' => 'Send email OTP',
                'POST /api/auth/verify-otp' => 'Verify email OTP',
                'POST /api/auth/refresh' => 'Refresh access token',
                'POST /api/auth/logout' => 'User logout',
                'GET /api/groups/available' => 'Get available groups',
                'GET /api/groups/user-groups' => 'Get user groups',
                'GET /api/groups/details' => 'Get group details',
                'POST /api/groups/create' => 'Create new group',
                'POST /api/groups/join' => 'Join a group',
                'POST /api/groups/leave' => 'Leave a group',
                'POST /api/payment/create-order' => 'Create payment order',
                'POST /api/payment/verify' => 'Verify payment',
                'POST /api/groups/contribution' => 'Make contribution',
                'POST /api/groups/withdrawal' => 'Request withdrawal',
                'POST /api/groups/loan' => 'Request loan',
                'GET /api/chat/messages' => 'Get chat messages',
                'POST /api/chat/send' => 'Send chat message'
            ]
        ], 'MicroNest API');
    } else {
        ApiResponse::notFound('Endpoint not found');
    }
}
?>
