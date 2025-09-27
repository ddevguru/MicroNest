<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/cors.php';
require_once __DIR__ . '/../includes/response.php';
require_once __DIR__ . '/../models/Group.php';

header('Content-Type: application/json');

try {
    $group = new Group();
    
    // Test getAvailableGroups with a dummy user ID (no JWT required)
    $userId = 1;
    $groups = $group->getAvailableGroups($userId);
    
    ApiResponse::success([
        'user_id' => $userId,
        'available_groups' => $groups,
        'groups_count' => count($groups)
    ], 'Available groups fetched successfully (no auth)');
    
} catch (Exception $e) {
    ApiResponse::error('Error: ' . $e->getMessage(), 500);
}
?> 