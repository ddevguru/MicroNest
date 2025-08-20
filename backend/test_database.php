<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config/database.php';

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Database connection successful',
        'data' => []
    ]);
    
    // Test if users table exists
    $stmt = $conn->query("SHOW TABLES LIKE 'users'");
    if ($stmt->rowCount() > 0) {
        echo "\nUsers table exists\n";
        
        // Test if wallet_transactions table exists
        $stmt = $conn->query("SHOW TABLES LIKE 'wallet_transactions'");
        if ($stmt->rowCount() > 0) {
            echo "Wallet transactions table exists\n";
            
            // Test if we can query the users table
            $stmt = $conn->query("SELECT COUNT(*) as count FROM users");
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            echo "Users count: " . $result['count'] . "\n";
            
            // Test if we can query wallet_transactions
            $stmt = $conn->query("SELECT COUNT(*) as count FROM wallet_transactions");
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            echo "Wallet transactions count: " . $result['count'] . "\n";
            
        } else {
            echo "Wallet transactions table does NOT exist\n";
        }
    } else {
        echo "Users table does NOT exist\n";
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
        'data' => []
    ]);
}
?> 