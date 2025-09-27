<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/cors.php';
require_once __DIR__ . '/../includes/response.php';

header('Content-Type: application/json');

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Get all tables in the database
    $stmt = $conn->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    // Check if groups table exists (case insensitive)
    $groupsTableExists = false;
    foreach ($tables as $table) {
        if (strtolower($table) === 'groups') {
            $groupsTableExists = true;
            break;
        }
    }
    
    if ($groupsTableExists) {
        $stmt = $conn->query("SELECT COUNT(*) as count FROM `groups`");
        $count = $stmt->fetch()['count'];
        
        ApiResponse::success([
            'database_connected' => true,
            'groups_table_exists' => true,
            'groups_count' => $count,
            'all_tables' => $tables
        ], 'Database connection successful');
    } else {
        ApiResponse::error('Groups table does not exist. Available tables: ' . implode(', ', $tables), 500);
    }
    
} catch (Exception $e) {
    ApiResponse::error('Database error: ' . $e->getMessage(), 500);
}
?> 