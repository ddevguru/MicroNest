<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    require_once 'config/database.php';
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    // Direct fix for deepakm7778@gmail.com
    $email = 'deepakm7778@gmail.com';
    
    echo "=== QUICK FIX FOR EMAIL VERIFICATION ===\n";
    echo "Email: $email\n\n";
    
    // Check current status
    $checkQuery = "SELECT id, full_name, email, email_verified, email_verified_at FROM users WHERE email = ?";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->execute([$email]);
    
    if ($checkStmt->rowCount() == 0) {
        echo "❌ User not found!\n";
        exit;
    }
    
    $user = $checkStmt->fetch(PDO::FETCH_ASSOC);
    echo "Current User Status:\n";
    echo "- ID: " . $user['id'] . "\n";
    echo "- Name: " . $user['full_name'] . "\n";
    echo "- Email Verified: " . ($user['email_verified'] ? 'YES' : 'NO') . "\n";
    echo "- Verified At: " . ($user['email_verified_at'] ?? 'NULL') . "\n\n";
    
    // Check OTP status
    $otpQuery = "SELECT * FROM email_otps WHERE email = ? AND used = TRUE ORDER BY created_at DESC LIMIT 1";
    $otpStmt = $conn->prepare($otpQuery);
    $otpStmt->execute([$email]);
    
    if ($otpStmt->rowCount() > 0) {
        $otp = $otpStmt->fetch(PDO::FETCH_ASSOC);
        echo "OTP Status:\n";
        echo "- OTP: " . $otp['otp'] . "\n";
        echo "- Used: " . ($otp['used'] ? 'YES' : 'NO') . "\n";
        echo "- Used At: " . $otp['used_at'] . "\n";
        echo "- Expires At: " . $otp['expires_at'] . "\n\n";
        
        // Fix the email verification
        if (!$user['email_verified']) {
            echo "🔧 Fixing email verification...\n";
            
            $fixQuery = "UPDATE users SET email_verified = TRUE, email_verified_at = NOW() WHERE email = ?";
            $fixStmt = $conn->prepare($fixQuery);
            $fixStmt->execute([$email]);
            
            if ($fixStmt->rowCount() > 0) {
                echo "✅ Email verification fixed successfully!\n";
                
                // Verify the fix
                $verifyQuery = "SELECT email_verified, email_verified_at FROM users WHERE email = ?";
                $verifyStmt = $conn->prepare($verifyQuery);
                $verifyStmt->execute([$email]);
                $verifyResult = $verifyStmt->fetch(PDO::FETCH_ASSOC);
                
                echo "Verification Result:\n";
                echo "- Email Verified: " . ($verifyResult['email_verified'] ? 'YES' : 'NO') . "\n";
                echo "- Verified At: " . $verifyResult['email_verified_at'] . "\n";
                
            } else {
                echo "❌ Failed to fix email verification!\n";
            }
        } else {
            echo "✅ Email is already verified!\n";
        }
        
    } else {
        echo "❌ No verified OTP found for this email!\n";
    }
    
    echo "\n=== END ===\n";
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
?> 