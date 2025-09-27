<?php
// Application configuration
define('JWT_SECRET', 'your-super-secret-jwt-key-change-this-in-production');
define('JWT_ALGORITHM', 'HS256');
define('ACCESS_TOKEN_EXPIRY', 3600); // 1 hour
define('REFRESH_TOKEN_EXPIRY', 604800); // 7 days
define('OTP_EXPIRY', 300); // 5 minutes

// SMTP2GO Configuration
define('SMTP2GO_API_KEY', 'api-5C5BC5F363E84C4D9C9302E57F873F57');
define('SMTP2GO_API_URL', 'https://api.smtp2go.com/v3/email/send');
define('FROM_EMAIL', '121deepak2104@sjcem.edu.in');
define('FROM_NAME', 'MicroNest');

// CORS settings
define('ALLOWED_ORIGINS', [
    'http://localhost:3000',
    'https://micronest.devloperwala.in'
]);

// Error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/../logs/error.log');

// Timezone
date_default_timezone_set('UTC');
?>
