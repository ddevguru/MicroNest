<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

echo json_encode([
    'message' => 'API Endpoints Test',
    'timestamp' => date('Y-m-d H:i:s'),
    'available_endpoints' => [
        'auth' => [
            'POST /api/auth/signup' => 'Create new account',
            'POST /api/auth/register' => 'Create new account (alternative)',
            'POST /api/auth/login' => 'User login',
            'POST /api/auth/send-otp' => 'Send OTP email',
            'POST /api/auth/verify-otp' => 'Verify OTP',
            'POST /api/auth/refresh' => 'Refresh JWT token'
        ],
        'profile' => [
            'GET /api/profile' => 'Get user profile',
            'PUT /api/profile' => 'Update profile',
            'POST /api/profile/notifications' => 'Update notification settings',
            'POST /api/profile/security' => 'Update security settings'
        ],
        'dashboard' => [
            'GET /api/dashboard' => 'Get dashboard data'
        ],
        'groups' => [
            'GET /api/groups' => 'Get user groups'
        ]
    ],
    'test_urls' => [
        'base_url' => 'https://micronest.devloperwala.in',
        'api_base' => 'https://micronest.devloperwala.in/api',
        'auth_base' => 'https://micronest.devloperwala.in/api/auth'
    ]
]);

// Test database connection
try {
    require_once 'config/database.php';
    $database = new Database();
    $db = $database->getConnection();
    
    if ($db) {
        echo json_encode([
            'database' => 'Connected successfully'
        ]);
    } else {
        echo json_encode([
            'database' => 'Connection failed'
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'database_error' => $e->getMessage()
    ]);
}
?> 