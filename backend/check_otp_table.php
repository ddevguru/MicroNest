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
        'message' => 'Database connection successful'
    ]);
    
    // Check if email_otps table exists
    $query = "SHOW TABLES LIKE 'email_otps'";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    if ($stmt->rowCount() == 0) {
        echo json_encode([
            'error' => 'email_otps table does not exist',
            'solution' => 'Run the database schema creation script'
        ]);
        exit;
    }
    
    // Check table structure
    $query = "DESCRIBE email_otps";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'table_structure' => $columns
    ]);
    
    // Check if required columns exist
    $requiredColumns = ['id', 'email', 'otp', 'expires_at', 'created_at', 'used', 'used_at'];
    $existingColumns = array_column($columns, 'Field');
    $missingColumns = array_diff($requiredColumns, $existingColumns);
    
    if (!empty($missingColumns)) {
        echo json_encode([
            'warning' => 'Missing required columns',
            'missing' => $missingColumns
        ]);
    }
    
    // Check sample data
    $query = "SELECT * FROM email_otps ORDER BY created_at DESC LIMIT 5";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $sampleData = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'sample_data' => $sampleData
    ]);
    
    // Check users table for email_verified column
    $query = "SHOW COLUMNS FROM users LIKE 'email_verified'";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    if ($stmt->rowCount() == 0) {
        echo json_encode([
            'warning' => 'users table missing email_verified column',
            'solution' => 'Add email_verified column to users table'
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?> 