<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Fix Users Table Script</h1>";

try {
    // Include database configuration
    require_once 'config/database.php';
    
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception("Database connection failed");
    }
    echo "<p style='color: green;'>✅ Database connection successful!</p>";
    
    // Check if users table exists
    echo "<h2>1. Checking users Table</h2>";
    $stmt = $conn->query("SHOW TABLES LIKE 'users'");
    
    if ($stmt->rowCount() == 0) {
        echo "<p style='color: red;'>❌ users table does not exist!</p>";
        echo "<p>Creating users table...</p>";
        
        // Create the users table
        $createTableSQL = "
        CREATE TABLE users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            full_name VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            username VARCHAR(100) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            phone VARCHAR(20),
            address TEXT,
            profile_image TEXT,
            email_verified BOOLEAN DEFAULT FALSE,
            email_verified_at TIMESTAMP NULL,
            status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
            trust_score DECIMAL(5,2) DEFAULT 0.00,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_email (email),
            INDEX idx_username (username),
            INDEX idx_status (status),
            INDEX idx_email_verified (email_verified)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ";
        
        $conn->exec($createTableSQL);
        echo "<p style='color: green;'>✅ users table created successfully!</p>";
        
    } else {
        echo "<p style='color: green;'>✅ users table exists</p>";
        
        // Check table structure
        echo "<h3>Current Table Structure:</h3>";
        $stmt = $conn->query("DESCRIBE users");
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
        
        // Check if email_verified column exists
        $stmt = $conn->query("SHOW COLUMNS FROM users LIKE 'email_verified'");
        if ($stmt->rowCount() == 0) {
            echo "<p style='color: orange;'>⚠️ email_verified column missing. Adding it...</p>";
            $conn->exec("ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE AFTER password_hash");
            echo "<p style='color: green;'>✅ email_verified column added successfully!</p>";
        } else {
            echo "<p style='color: green;'>✅ email_verified column exists</p>";
        }
        
        // Check if email_verified_at column exists
        $stmt = $conn->query("SHOW COLUMNS FROM users LIKE 'email_verified_at'");
        if ($stmt->rowCount() == 0) {
            echo "<p style='color: orange;'>⚠️ email_verified_at column missing. Adding it...</p>";
            $conn->exec("ALTER TABLE users ADD COLUMN email_verified_at TIMESTAMP NULL AFTER email_verified");
            echo "<p style='color: green;'>✅ email_verified_at column added successfully!</p>";
        } else {
            echo "<p style='color: green;'>✅ email_verified_at column exists</p>";
        }
    }
    
    // Check current users and their email verification status
    echo "<h2>2. Checking Current Users</h2>";
    $stmt = $conn->query("SELECT id, full_name, email, email_verified, email_verified_at FROM users ORDER BY id");
    
    if ($stmt->rowCount() > 0) {
        echo "<h3>Current Users:</h3>";
        echo "<table border='1' style='border-collapse: collapse;'>";
        echo "<tr><th>ID</th><th>Name</th><th>Email</th><th>Email Verified</th><th>Verified At</th></tr>";
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $verifiedStatus = $row['email_verified'] ? '✅ YES' : '❌ NO';
            $verifiedAt = $row['email_verified_at'] ? $row['email_verified_at'] : 'Never';
            echo "<tr>";
            echo "<td>" . htmlspecialchars($row['id']) . "</td>";
            echo "<td>" . htmlspecialchars($row['full_name']) . "</td>";
            echo "<td>" . htmlspecialchars($row['email']) . "</td>";
            echo "<td>" . $verifiedStatus . "</td>";
            echo "<td>" . htmlspecialchars($verifiedAt) . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p>No users found in the database.</p>";
    }
    
    // Test updating email_verified for a specific user
    echo "<h2>3. Testing Email Verification Update</h2>";
    $testEmail = "amulyaambreofficial@gmail.com"; // Use the email from your logs
    
    $stmt = $conn->prepare("SELECT id, email, email_verified FROM users WHERE email = ?");
    $stmt->execute([$testEmail]);
    
    if ($stmt->rowCount() > 0) {
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        echo "<p>Found user: <strong>" . htmlspecialchars($user['full_name'] ?? 'Unknown') . "</strong></p>";
        echo "<p>Current email_verified status: <strong>" . ($user['email_verified'] ? 'TRUE' : 'FALSE') . "</strong></p>";
        
        // Test the update query
        echo "<p>Testing update query...</p>";
        $updateQuery = "UPDATE users SET email_verified = TRUE, email_verified_at = NOW() WHERE email = ?";
        $updateStmt = $conn->prepare($updateQuery);
        $updateStmt->execute([$testEmail]);
        
        if ($updateStmt->rowCount() > 0) {
            echo "<p style='color: green;'>✅ Update successful! Rows affected: " . $updateStmt->rowCount() . "</p>";
            
            // Verify the update
            $verifyStmt = $conn->prepare("SELECT email_verified, email_verified_at FROM users WHERE email = ?");
            $verifyStmt->execute([$testEmail]);
            $verifyResult = $verifyStmt->fetch(PDO::FETCH_ASSOC);
            
            echo "<p>After update - email_verified: <strong>" . ($verifyResult['email_verified'] ? 'TRUE' : 'FALSE') . "</strong></p>";
            echo "<p>After update - email_verified_at: <strong>" . ($verifyResult['email_verified_at']) . "</strong></p>";
            
        } else {
            echo "<p style='color: orange;'>⚠️ Update query executed but no rows were affected!</p>";
        }
        
    } else {
        echo "<p style='color: orange;'>⚠️ User with email '$testEmail' not found.</p>";
        echo "<p>This might be why the OTP verification isn't working.</p>";
    }
    
    // Check if there are any recent OTPs for this email
    echo "<h2>4. Checking Recent OTPs</h2>";
    $stmt = $conn->prepare("SELECT * FROM email_otps WHERE email = ? ORDER BY created_at DESC LIMIT 5");
    $stmt->execute([$testEmail]);
    
    if ($stmt->rowCount() > 0) {
        echo "<h3>Recent OTPs for $testEmail:</h3>";
        echo "<table border='1' style='border-collapse: collapse;'>";
        echo "<tr><th>ID</th><th>OTP</th><th>Expires At</th><th>Used</th><th>Used At</th><th>Created At</th></tr>";
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $usedStatus = $row['used'] ? '✅ YES' : '❌ NO';
            $usedAt = $row['used_at'] ? $row['used_at'] : 'Never';
            echo "<tr>";
            echo "<td>" . htmlspecialchars($row['id']) . "</td>";
            echo "<td>" . htmlspecialchars($row['otp']) . "</td>";
            echo "<td>" . htmlspecialchars($row['expires_at']) . "</td>";
            echo "<td>" . $usedStatus . "</td>";
            echo "<td>" . htmlspecialchars($usedAt) . "</td>";
            echo "<td>" . htmlspecialchars($row['created_at']) . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p>No OTPs found for email '$testEmail'.</p>";
    }
    
    echo "<h2>5. Summary</h2>";
    echo "<p style='color: green;'>✅ Users table check completed!</p>";
    echo "<p>If there were any issues, they should now be resolved.</p>";
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
}

echo "<hr>";
echo "<p><strong>Next Steps:</strong></p>";
echo "<ol>";
echo "<li>Run this script to check and fix the users table</li>";
echo "<li>Try the OTP verification again from your Flutter app</li>";
echo "<li>Check if the email_verified column is now properly updated</li>";
echo "</ol>";
?> 