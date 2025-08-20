<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Quick Fix Email Verification Status</h1>";

try {
    // Include database configuration
    require_once 'config/database.php';
    
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception("Database connection failed");
    }
    echo "<p style='color: green;'>✅ Database connection successful!</p>";
    
    // Find users who have verified OTPs but email_verified is still FALSE
    echo "<h2>1. Finding Users with Verified OTPs</h2>";
    
    $query = "
        SELECT DISTINCT u.id, u.full_name, u.email, u.email_verified, u.email_verified_at
        FROM users u
        INNER JOIN email_otps e ON u.email = e.email
        WHERE e.used = TRUE AND u.email_verified = FALSE
        ORDER BY u.id
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        echo "<p>Found <strong>" . $stmt->rowCount() . "</strong> users with verified OTPs but unverified emails:</p>";
        
        echo "<table border='1' style='border-collapse: collapse;'>";
        echo "<tr><th>ID</th><th>Name</th><th>Email</th><th>Current Status</th><th>Action</th></tr>";
        
        while ($user = $stmt->fetch(PDO::FETCH_ASSOC)) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($user['id']) . "</td>";
            echo "<td>" . htmlspecialchars($user['full_name']) . "</td>";
            echo "<td>" . htmlspecialchars($user['email']) . "</td>";
            echo "<td>" . ($user['email_verified'] ? '✅ Verified' : '❌ Not Verified') . "</td>";
            echo "<td>";
            
            // Fix button
            echo "<form method='post' style='display: inline;'>";
            echo "<input type='hidden' name='fix_user_id' value='" . $user['id'] . "'>";
            echo "<input type='hidden' name='fix_user_email' value='" . htmlspecialchars($user['email']) . "'>";
            echo "<button type='submit' name='fix_user' style='background: #4CAF50; color: white; border: none; padding: 5px 10px; cursor: pointer;'>Fix This User</button>";
            echo "</form>";
            
            echo "</td>";
            echo "</tr>";
        }
        echo "</table>";
        
    } else {
        echo "<p style='color: green;'>✅ All users have correct email verification status!</p>";
    }
    
    // Handle fix requests
    if (isset($_POST['fix_user']) && isset($_POST['fix_user_id']) && isset($_POST['fix_user_email'])) {
        $userId = $_POST['fix_user_id'];
        $userEmail = $_POST['fix_user_email'];
        
        echo "<h2>2. Fixing User Email Verification</h2>";
        echo "<p>Fixing user ID: <strong>$userId</strong> with email: <strong>$userEmail</strong></p>";
        
        // Update the user's email verification status
        $updateQuery = "UPDATE users SET email_verified = TRUE, email_verified_at = NOW() WHERE id = ?";
        $updateStmt = $conn->prepare($updateQuery);
        $updateStmt->execute([$userId]);
        
        if ($updateStmt->rowCount() > 0) {
            echo "<p style='color: green;'>✅ User email verification status updated successfully!</p>";
            
            // Verify the update
            $verifyStmt = $conn->prepare("SELECT email_verified, email_verified_at FROM users WHERE id = ?");
            $verifyStmt->execute([$userId]);
            $verifyResult = $verifyStmt->fetch(PDO::FETCH_ASSOC);
            
            echo "<p>New status - email_verified: <strong>" . ($verifyResult['email_verified'] ? 'TRUE' : 'FALSE') . "</strong></p>";
            echo "<p>New status - email_verified_at: <strong>" . $verifyResult['email_verified_at'] . "</strong></p>";
            
        } else {
            echo "<p style='color: red;'>❌ Failed to update user email verification status!</p>";
        }
        
        // Refresh the page to show updated status
        echo "<script>setTimeout(function(){ location.reload(); }, 2000);</script>";
    }
    
    // Show current status of all users
    echo "<h2>3. Current Status of All Users</h2>";
    $stmt = $conn->query("SELECT id, full_name, email, email_verified, email_verified_at FROM users ORDER BY id");
    
    if ($stmt->rowCount() > 0) {
        echo "<table border='1' style='border-collapse: collapse;'>";
        echo "<tr><th>ID</th><th>Name</th><th>Email</th><th>Email Verified</th><th>Verified At</th></tr>";
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $verifiedStatus = $row['email_verified'] ? '✅ YES' : '❌ NO';
            $verifiedAt = $row['email_verified_at'] ? $row['email_verified_at'] : 'Never';
            $rowColor = $row['email_verified'] ? 'background-color: #d4edda;' : 'background-color: #f8d7da;';
            
            echo "<tr style='$rowColor'>";
            echo "<td>" . htmlspecialchars($row['id']) . "</td>";
            echo "<td>" . htmlspecialchars($row['full_name']) . "</td>";
            echo "<td>" . htmlspecialchars($row['email']) . "</td>";
            echo "<td>" . $verifiedStatus . "</td>";
            echo "<td>" . htmlspecialchars($verifiedAt) . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
}

echo "<hr>";
echo "<p><strong>Instructions:</strong></p>";
echo "<ol>";
echo "<li>This script will show you all users with verified OTPs but unverified emails</li>";
echo "<li>Click 'Fix This User' button to update their email verification status</li>";
echo "<li>After fixing, try logging in with those users again</li>";
echo "</ol>";
?> 