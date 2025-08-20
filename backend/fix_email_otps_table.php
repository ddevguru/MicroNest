<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Fix email_otps Table Script</h1>";

try {
    // Include database configuration
    require_once 'config/database.php';
    
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception("Database connection failed");
    }
    echo "<p style='color: green;'>✅ Database connection successful!</p>";
    
    // Check if email_otps table exists
    echo "<h2>1. Checking email_otps Table</h2>";
    $stmt = $conn->query("SHOW TABLES LIKE 'email_otps'");
    
    if ($stmt->rowCount() == 0) {
        echo "<p style='color: orange;'>⚠️ email_otps table does not exist. Creating it...</p>";
        
        // Create the table
        $createTableSQL = "
        CREATE TABLE email_otps (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(255) NOT NULL,
            otp VARCHAR(10) NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            used BOOLEAN DEFAULT FALSE,
            used_at TIMESTAMP NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_email (email),
            INDEX idx_expires_at (expires_at),
            INDEX idx_used (used)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ";
        
        $conn->exec($createTableSQL);
        echo "<p style='color: green;'>✅ email_otps table created successfully!</p>";
        
    } else {
        echo "<p style='color: green;'>✅ email_otps table already exists</p>";
        
        // Check table structure
        echo "<h3>Current Table Structure:</h3>";
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
        
        // Check if used_at column exists
        $stmt = $conn->query("SHOW COLUMNS FROM email_otps LIKE 'used_at'");
        if ($stmt->rowCount() == 0) {
            echo "<p style='color: orange;'>⚠️ used_at column missing. Adding it...</p>";
            $conn->exec("ALTER TABLE email_otps ADD COLUMN used_at TIMESTAMP NULL AFTER used");
            echo "<p style='color: green;'>✅ used_at column added successfully!</p>";
        } else {
            echo "<p style='color: green;'>✅ used_at column exists</p>";
        }
    }
    
    // Test inserting a sample OTP
    echo "<h2>2. Testing OTP Insertion</h2>";
    $testEmail = "test@example.com";
    $testOtp = "123456";
    $expiresAt = date('Y-m-d H:i:s', strtotime('+10 minutes'));
    
    // Delete existing test OTPs
    $stmt = $conn->prepare("DELETE FROM email_otps WHERE email = ?");
    $stmt->execute([$testEmail]);
    
    // Insert test OTP
    $stmt = $conn->prepare("INSERT INTO email_otps (email, otp, expires_at) VALUES (?, ?, ?)");
    $stmt->execute([$testEmail, $testOtp, $expiresAt]);
    
    $insertId = $conn->lastInsertId();
    echo "<p style='color: green;'>✅ Test OTP inserted with ID: $insertId</p>";
    
    // Verify the OTP was inserted
    $stmt = $conn->prepare("SELECT * FROM email_otps WHERE id = ?");
    $stmt->execute([$insertId]);
    $otpData = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($otpData) {
        echo "<p>Inserted OTP data:</p>";
        echo "<pre>" . json_encode($otpData, JSON_PRETTY_PRINT) . "</pre>";
    }
    
    // Clean up test data
    $stmt = $conn->prepare("DELETE FROM email_otps WHERE id = ?");
    $stmt->execute([$insertId]);
    echo "<p style='color: green;'>✅ Test OTP cleaned up</p>";
    
    echo "<h2>3. Summary</h2>";
    echo "<p style='color: green;'>✅ email_otps table is ready for use!</p>";
    echo "<p>The table structure is correct and can handle OTP operations.</p>";
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
}

echo "<hr>";
echo "<p><strong>Next Steps:</strong></p>";
echo "<ol>";
echo "<li>Run this script to ensure the table exists</li>";
echo "<li>Test the OTP functionality with the test script</li>";
echo "<li>Check the API logs for any remaining errors</li>";
echo "</ol>";
?> 