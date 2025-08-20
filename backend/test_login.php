<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'config/database.php';
require_once 'utils/ResponseUtil.php';
require_once 'utils/JWTUtil.php';
require_once 'models/Auth.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        ResponseUtil::sendError('Only POST method allowed', 405);
    }
    
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    if (!$data) {
        ResponseUtil::sendError('Invalid JSON input', 400);
    }
    
    $email = $data['email'] ?? '';
    $password = $data['password'] ?? '';
    
    if (empty($email) || empty($password)) {
        ResponseUtil::sendError('Email and password are required', 400);
    }
    
    // Test database connection
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        ResponseUtil::sendError('Database connection failed', 500);
    }
    
    // Test Auth class
    $auth = new Auth($db);
    $result = $auth->login($data);
    
    echo json_encode($result);
    
} catch (Exception $e) {
    error_log("Test login error: " . $e->getMessage());
    ResponseUtil::sendError('Test failed: ' . $e->getMessage(), 500);
}
?> 