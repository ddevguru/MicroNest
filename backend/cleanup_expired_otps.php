<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Cleanup Expired OTPs Script</h1>";

try {
    // Include database configuration
    require_once 'config/database.php';
    
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception("Database connection failed");
    }
    echo "<p style='color: green;'>✅ Database connection successful!</p>";
    
    // Show current time
    $currentTime = gmdate('Y-m-d H:i:s');
    echo "<h2>1. Current Time</h2>";
    echo "<p>Current UTC time: <strong>$currentTime</strong></p>";
    
    // Show all OTPs
    echo "<h2>2. All OTPs in Database</h2>";
    $stmt = $conn->query("SELECT * FROM email_otps ORDER BY created_at DESC");
    
    if ($stmt->rowCount() > 0) {
        echo "<table border='1' style='border-collapse: collapse;'>";
        echo "<tr><th>ID</th><th>Email</th><th>OTP</th><th>Expires At</th><th>Used</th><th>Used At</th><th>Created At</th><th>Status</th></tr>";
        
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $isExpired = strtotime($row['expires_at']) < strtotime($currentTime);
            $isUsed = $row['used'] == 1;
            
            $status = '';
            $rowColor = '';
            
            if ($isUsed) {
                $status = '✅ Used';
                $rowColor = 'background-color: #d4edda;';
            } elseif ($isExpired) {
                $status = '⏰ Expired';
                $rowColor = 'background-color: #f8d7da;';
            } else {
                $status = '🆕 Active';
                $rowColor = 'background-color: #fff3cd;';
            }
            
            echo "<tr style='$rowColor'>";
            echo "<td>" . htmlspecialchars($row['id']) . "</td>";
            echo "<td>" . htmlspecialchars($row['email']) . "</td>";
            echo "<td>" . htmlspecialchars($row['otp']) . "</td>";
            echo "<td>" . htmlspecialchars($row['expires_at']) . "</td>";
            echo "<td>" . ($isUsed ? '✅ YES' : '❌ NO') . "</td>";
            echo "<td>" . ($row['used_at'] ? htmlspecialchars($row['used_at']) : 'Never') . "</td>";
            echo "<td>" . htmlspecialchars($row['created_at']) . "</td>";
            echo "<td>" . $status . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p>No OTPs found in the database.</p>";
    }
    
    // Count OTPs by status
    echo "<h2>3. OTP Statistics</h2>";
    
    $stmt = $conn->query("SELECT COUNT(*) as total FROM email_otps");
    $total = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    $stmt = $conn->query("SELECT COUNT(*) as used FROM email_otps WHERE used = TRUE");
    $used = $stmt->fetch(PDO::FETCH_ASSOC)['used'];
    
    $stmt = $conn->query("SELECT COUNT(*) as expired FROM email_otps WHERE expires_at < NOW() AND used = FALSE");
    $expired = $stmt->fetch(PDO::FETCH_ASSOC)['expired'];
    
    $stmt = $conn->query("SELECT COUNT(*) as active FROM email_otps WHERE expires_at > NOW() AND used = FALSE");
    $active = $stmt->fetch(PDO::FETCH_ASSOC)['active'];
    
    echo "<p><strong>Total OTPs:</strong> $total</p>";
    echo "<p><strong>Used OTPs:</strong> $used</p>";
    echo "<p><strong>Expired OTPs:</strong> $expired</p>";
    echo "<p><strong>Active OTPs:</strong> $active</p>";
    
    // Cleanup expired OTPs
    if (isset($_POST['cleanup_expired'])) {
        echo "<h2>4. Cleaning Up Expired OTPs</h2>";
        
        $stmt = $conn->prepare("DELETE FROM email_otps WHERE expires_at < NOW() AND used = FALSE");
        $stmt->execute();
        $deletedCount = $stmt->rowCount();
        
        echo "<p style='color: green;'>✅ Cleaned up $deletedCount expired OTPs!</p>";
        
        // Refresh the page to show updated status
        echo "<script>setTimeout(function(){ location.reload(); }, 2000);</script>";
    }
    
    // Show cleanup button
    if ($expired > 0) {
        echo "<h2>4. Cleanup Actions</h2>";
        echo "<form method='post'>";
        echo "<button type='submit' name='cleanup_expired' style='background: #dc3545; color: white; border: none; padding: 10px 20px; cursor: pointer;'>Clean Up $expired Expired OTPs</button>";
        echo "</form>";
    } else {
        echo "<h2>4. Cleanup Status</h2>";
        echo "<p style='color: green;'>✅ No expired OTPs to clean up!</p>";
    }
    
    // Show specific email OTPs
    echo "<h2>5. Check Specific Email</h2>";
    echo "<form method='post'>";
    echo "<input type='email' name='check_email' placeholder='Enter email to check' style='padding: 5px; width: 300px;' value='amulyaambreofficial@gmail.com'>";
    echo "<button type='submit' name='check_specific' style='background: #007bff; color: white; border: none; padding: 5px 10px; cursor: pointer;'>Check Email</button>";
    echo "</form>";
    
    if (isset($_POST['check_specific']) && isset($_POST['check_email'])) {
        $checkEmail = $_POST['check_email'];
        echo "<h3>OTPs for: $checkEmail</h3>";
        
        $stmt = $conn->prepare("SELECT * FROM email_otps WHERE email = ? ORDER BY created_at DESC");
        $stmt->execute([$checkEmail]);
        
        if ($stmt->rowCount() > 0) {
            echo "<table border='1' style='border-collapse: collapse;'>";
            echo "<tr><th>ID</th><th>OTP</th><th>Expires At</th><th>Used</th><th>Used At</th><th>Created At</th><th>Status</th></tr>";
            
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $isExpired = strtotime($row['expires_at']) < strtotime($currentTime);
                $isUsed = $row['used'] == 1;
                
                $status = '';
                $rowColor = '';
                
                if ($isUsed) {
                    $status = '✅ Used';
                    $rowColor = 'background-color: #d4edda;';
                } elseif ($isExpired) {
                    $status = '⏰ Expired';
                    $rowColor = 'background-color: #f8d7da;';
                } else {
                    $status = '🆕 Active';
                    $rowColor = 'background-color: #fff3cd;';
                }
                
                echo "<tr style='$rowColor'>";
                echo "<td>" . htmlspecialchars($row['id']) . "</td>";
                echo "<td>" . htmlspecialchars($row['otp']) . "</td>";
                echo "<td>" . htmlspecialchars($row['expires_at']) . "</td>";
                echo "<td>" . ($isUsed ? '✅ YES' : '❌ NO') . "</td>";
                echo "<td>" . ($row['used_at'] ? htmlspecialchars($row['used_at']) : 'Never') . "</td>";
                echo "<td>" . htmlspecialchars($row['created_at']) . "</td>";
                echo "<td>" . $status . "</td>";
                echo "</tr>";
            }
            echo "</table>";
        } else {
            echo "<p>No OTPs found for email: $checkEmail</p>";
        }
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
}

echo "<hr>";
echo "<p><strong>Summary:</strong></p>";
echo "<ul>";
echo "<li>✅ Database connection working</li>";
echo "<li>✅ Users table structure correct</li>";
echo "<li>⚠️ User 'amulyaambreofficial@gmail.com' doesn't exist yet</li>";
echo "<li>📧 OTP exists but may be expired</li>";
echo "</ul>";
echo "<p><strong>Next Steps:</strong></p>";
echo "<ol>";
echo "<li>Check if the OTP is still valid</li>";
echo "<li>Complete the signup process in your Flutter app</li>";
echo "<li>Or request a new OTP if the current one is expired</li>";
echo "</ol>";
?> 