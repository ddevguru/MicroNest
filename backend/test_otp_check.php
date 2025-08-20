<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Test OTP Check for Signup</h1>";

try {
    // Include database configuration
    require_once 'config/database.php';
    
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception("Database connection failed");
    }
    echo "<p style='color: green;'>✅ Database connection successful!</p>";
    
    $testEmail = "amulyaambreofficial@gmail.com";
    
    echo "<h2>1. Testing OTP Verification Check</h2>";
    echo "<p>Testing email: <strong>$testEmail</strong></p>";
    
    // Check current time
    $currentTime = gmdate('Y-m-d H:i:s');
    echo "<p>Current UTC time: <strong>$currentTime</strong></p>";
    
    // Test the OTP verification query that's used in signup
    $query = "SELECT id FROM email_otps WHERE email = ? AND used = TRUE AND used_at > DATE_SUB(NOW(), INTERVAL 30 MINUTE)";
    $stmt = $conn->prepare($query);
    $stmt->execute([$testEmail]);
    
    echo "<p><strong>Query:</strong> $query</p>";
    echo "<p><strong>Result count:</strong> " . $stmt->rowCount() . "</p>";
    
    if ($stmt->rowCount() > 0) {
        echo "<p style='color: green;'>✅ OTP verification check PASSED! User can proceed with signup.</p>";
        
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        echo "<p>OTP ID: <strong>" . $result['id'] . "</strong></p>";
        
    } else {
        echo "<p style='color: red;'>❌ OTP verification check FAILED! User cannot proceed with signup.</p>";
        
        // Show why it failed
        echo "<h3>Debug Information:</h3>";
        
        // Check all OTPs for this email
        $debugQuery = "SELECT * FROM email_otps WHERE email = ? ORDER BY created_at DESC";
        $debugStmt = $conn->prepare($debugQuery);
        $debugStmt->execute([$testEmail]);
        
        if ($debugStmt->rowCount() > 0) {
            echo "<table border='1' style='border-collapse: collapse;'>";
            echo "<tr><th>ID</th><th>OTP</th><th>Expires At</th><th>Used</th><th>Used At</th><th>Created At</th><th>Status</th></tr>";
            
            while ($row = $debugStmt->fetch(PDO::FETCH_ASSOC)) {
                $isExpired = strtotime($row['expires_at']) < strtotime($currentTime);
                $isUsed = $row['used'] == 1;
                $usedAt = $row['used_at'] ? $row['used_at'] : 'Never';
                
                $status = '';
                $rowColor = '';
                
                if ($isUsed) {
                    if ($row['used_at'] && strtotime($row['used_at']) > strtotime('-30 minutes')) {
                        $status = '✅ Recently Used (Valid for signup)';
                        $rowColor = 'background-color: #d4edda;';
                    } else {
                        $status = '⏰ Used but Too Old (Not valid for signup)';
                        $rowColor = 'background-color: #f8d7da;';
                    }
                } elseif ($isExpired) {
                    $status = '⏰ Expired';
                    $rowColor = 'background-color: #f8d7da;';
                } else {
                    $status = '🆕 Active (Not used)';
                    $rowColor = 'background-color: #fff3cd;';
                }
                
                echo "<tr style='$rowColor'>";
                echo "<td>" . htmlspecialchars($row['id']) . "</td>";
                echo "<td>" . htmlspecialchars($row['otp']) . "</td>";
                echo "<td>" . htmlspecialchars($row['expires_at']) . "</td>";
                echo "<td>" . ($isUsed ? '✅ YES' : '❌ NO') . "</td>";
                echo "<td>" . htmlspecialchars($usedAt) . "</td>";
                echo "<td>" . htmlspecialchars($row['created_at']) . "</td>";
                echo "<td>" . $status . "</td>";
                echo "</tr>";
            }
            echo "</table>";
        }
        
        // Check the 30-minute window
        echo "<h3>30-Minute Window Check:</h3>";
        $thirtyMinutesAgo = date('Y-m-d H:i:s', strtotime('-30 minutes'));
        echo "<p>30 minutes ago: <strong>$thirtyMinutesAgo</strong></p>";
        
        $stmt = $conn->prepare("SELECT COUNT(*) as count FROM email_otps WHERE email = ? AND used = TRUE AND used_at > ?");
        $stmt->execute([$testEmail, $thirtyMinutesAgo]);
        $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        echo "<p>OTPs used within last 30 minutes: <strong>$count</strong></p>";
    }
    
    // Test the exact query that will be used in signup
    echo "<h2>2. Testing Exact Signup Query</h2>";
    
    $signupQuery = "SELECT id FROM email_otps WHERE email = ? AND used = TRUE AND used_at > DATE_SUB(NOW(), INTERVAL 30 MINUTE)";
    $signupStmt = $conn->prepare($signupQuery);
    $signupStmt->execute([$testEmail]);
    
    echo "<p><strong>Signup Query:</strong> $signupQuery</p>";
    echo "<p><strong>Parameters:</strong> email = $testEmail</p>";
    echo "<p><strong>Result:</strong> " . $signupStmt->rowCount() . " rows found</p>";
    
    if ($signupStmt->rowCount() > 0) {
        echo "<p style='color: green;'>✅ Signup should work! OTP verification is valid.</p>";
    } else {
        echo "<p style='color: red;'>❌ Signup will fail! OTP verification is not valid.</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
}

echo "<hr>";
echo "<p><strong>Summary:</strong></p>";
echo "<ul>";
echo "<li>This script tests the exact OTP verification logic used in signup</li>";
echo "<li>It shows whether a user can proceed with signup after OTP verification</li>";
echo "<li>If the check passes, signup should work</li>";
echo "<li>If the check fails, you'll see exactly why</li>";
echo "</ul>";
?> 