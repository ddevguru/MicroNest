<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Direct OTP Test Script</h1>";

try {
    // Include required files
    require_once 'config/database.php';
    require_once 'models/EmailService.php';
    require_once 'models/Auth.php';
    
    echo "<h2>1. Testing Database Connection</h2>";
    $database = new Database();
    $conn = $database->getConnection();
    
    if (!$conn) {
        throw new Exception("Database connection failed");
    }
    echo "<p style='color: green;'>✅ Database connection successful!</p>";
    
    echo "<h2>2. Testing EmailService</h2>";
    $emailService = new EmailService();
    echo "<p style='color: green;'>✅ EmailService created successfully!</p>";
    
    echo "<h2>3. Testing Auth Class</h2>";
    $auth = new Auth();
    echo "<p style='color: green;'>✅ Auth class created successfully!</p>";
    
    echo "<h2>4. Testing OTP Generation</h2>";
    $testEmail = "test@example.com";
    echo "<p>Testing with email: <strong>$testEmail</strong></p>";
    
    // Test OTP generation
    $result = $auth->sendEmailOTP($testEmail);
    echo "<p>OTP Result: <pre>" . json_encode($result, JSON_PRETTY_PRINT) . "</pre></p>";
    
    if ($result['success']) {
        echo "<p style='color: green;'>✅ OTP sent successfully!</p>";
        
        // Now test OTP verification
        echo "<h2>5. Testing OTP Verification</h2>";
        echo "<p>You'll need to check the database for the OTP value and test verification manually.</p>";
        
        // Show recent OTPs for this email
        $stmt = $conn->prepare("SELECT * FROM email_otps WHERE email = ? ORDER BY created_at DESC LIMIT 1");
        $stmt->execute([$testEmail]);
        $otpData = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($otpData) {
            echo "<p>Latest OTP data:</p>";
            echo "<pre>" . json_encode($otpData, JSON_PRETTY_PRINT) . "</pre>";
            
            // Test verification with the actual OTP
            $verifyResult = $auth->verifyEmailOTP($testEmail, $otpData['otp']);
            echo "<p>Verification Result: <pre>" . json_encode($verifyResult, JSON_PRETTY_PRINT) . "</pre></p>";
        } else {
            echo "<p style='color: red;'>❌ No OTP found in database!</p>";
        }
        
    } else {
        echo "<p style='color: red;'>❌ OTP sending failed: " . $result['message'] . "</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
}

echo "<hr>";
echo "<p><strong>Note:</strong> This script tests the OTP functionality directly without going through the API.</p>";
?> 