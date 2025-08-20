<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        echo json_encode([
            'success' => false,
            'message' => 'Database connection failed'
        ]);
        exit;
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Database connection successful',
        'database' => [
            'host' => '103.120.179.212',
            'name' => 'devlope4_bharat'
        ]
    ]);
    
    // Check if required tables exist
    $tables = ['users', 'email_otps', 'user_security', 'user_preferences'];
    $existingTables = [];
    $missingTables = [];
    
    foreach ($tables as $table) {
        $query = "SHOW TABLES LIKE ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$table]);
        
        if ($stmt->rowCount() > 0) {
            $existingTables[] = $table;
        } else {
            $missingTables[] = $table;
        }
    }
    
    echo json_encode([
        'tables' => [
            'existing' => $existingTables,
            'missing' => $missingTables
        ]
    ]);
    
    // Check email_otps table structure
    if (in_array('email_otps', $existingTables)) {
        $query = "DESCRIBE email_otps";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'email_otps_structure' => $columns
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?> 