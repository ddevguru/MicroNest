<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit(0); }

require_once 'config/database.php';
require_once 'utils/ResponseUtil.php';
require_once 'models/Profile.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        ResponseUtil::sendError('Database connection failed', 500);
        exit;
    }
    
    $profile = new Profile($db);
    
    // Test getting profile data for user ID 1
    $result = $profile->getCompleteProfile(1);
    
    echo json_encode($result);
    
} catch (Exception $e) {
    ResponseUtil::sendError('Test failed: ' . $e->getMessage(), 500);
}
?> 