<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

echo json_encode([
    'success' => true,
    'message' => 'Server is working!',
    'timestamp' => date('Y-m-d H:i:s'),
    'php_version' => PHP_VERSION,
    'server_info' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'
]);
?> 