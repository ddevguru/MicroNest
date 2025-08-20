<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Database Check Script</h1>";

try {
    // Test database connection
    echo "<h2>1. Testing Database Connection</h2>";
    require_once 'config/database.php';
    
    $database = new Database();
    $conn = $database->getConnection();
    
    if ($conn) {
        echo "<p style='color: green;'>✅ Database connection successful!</p>";
        
        // Check if email_otps table exists
        echo "<h2>2. Checking email_otps Table</h2>";
        $stmt = $conn->query("SHOW TABLES LIKE 'email_otps'");
        if ($stmt->rowCount() > 0) {
            echo "<p style='color: green;'>✅ email_otps table exists</p>";
            
            // Show table structure
            echo "<h3>Table Structure:</h3>";
            $stmt = $conn->query("DESCRIBE email_otps");
            echo "<table border='1' style='border-collapse: collapse;'>";
            echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                echo "<tr>";
                echo "<td>" . htmlspecialchars($row['Field']) . "</td>";
                echo "<td>" . htmlspecialchars($row['Type']) . "</td>";
                echo "<td>" . htmlspecialchars($row['Null']) . "</td>";
                echo "<td>" . htmlspecialchars($row['Key']) . "</td>";
                echo "<td>" . htmlspecialchars($row['Default']) . "</td>";
                echo "<td>" . htmlspecialchars($row['Extra']) . "</td>";
                echo "</tr>";
            }
            echo "</table>";
            
            // Check if table has data
            $stmt = $conn->query("SELECT COUNT(*) as count FROM email_otps");
            $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            echo "<p>Total OTPs in table: <strong>$count</strong></p>";
            
        } else {
            echo "<p style='color: red;'>❌ email_otps table does not exist!</p>";
            echo "<p>You need to create the table first.</p>";
        }
        
        // Check users table
        echo "<h2>3. Checking users Table</h2>";
        $stmt = $conn->query("SHOW TABLES LIKE 'users'");
        if ($stmt->rowCount() > 0) {
            echo "<p style='color: green;'>✅ users table exists</p>";
            
            // Check if table has data
            $stmt = $conn->query("SELECT COUNT(*) as count FROM users");
            $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            echo "<p>Total users in table: <strong>$count</strong></p>";
            
        } else {
            echo "<p style='color: red;'>❌ users table does not exist!</p>";
        }
        
    } else {
        echo "<p style='color: red;'>❌ Database connection failed!</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
}

echo "<hr>";
echo "<p><strong>Note:</strong> This script helps diagnose database issues. Check the output above for any errors.</p>";
?> 