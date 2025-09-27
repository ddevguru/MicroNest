<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/response.php';

header('Content-Type: application/json');

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Get all groups where created_by is not in group_members
    $query = "SELECT g.id, g.created_by FROM `groups` g 
              LEFT JOIN group_members gm ON g.id = gm.group_id AND g.created_by = gm.user_id 
              WHERE gm.id IS NULL";
    
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $groups = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $fixed = 0;
    foreach ($groups as $group) {
        // Add creator as admin
        $insertQuery = "INSERT INTO group_members (group_id, user_id, role, total_contributed, joined_at, status) 
                        VALUES (:group_id, :user_id, 'admin', 0.00, :joined_at, 'active')";
        $insertStmt = $conn->prepare($insertQuery);
        $insertStmt->bindParam(':group_id', $group['id']);
        $insertStmt->bindParam(':user_id', $group['created_by']);
        $insertStmt->bindParam(':joined_at', $group['created_at'] ?? date('Y-m-d H:i:s'));
        
        if ($insertStmt->execute()) {
            $fixed++;
        }
    }
    
    ApiResponse::success([
        'groups_checked' => count($groups),
        'groups_fixed' => $fixed
    ], 'Group members fixed successfully');
    
} catch (Exception $e) {
    ApiResponse::error('Error: ' . $e->getMessage(), 500);
}
?> 