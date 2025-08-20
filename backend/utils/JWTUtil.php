<?php
class JWTUtil {
    private $secretKey;
    private $algorithm = 'HS256';
    
    public function __construct() {
        // In production, use environment variable for secret key
        $this->secretKey = 'your-secret-key-here-change-in-production';
    }
    
    public function generateAccessToken($userId) {
        $payload = [
            'user_id' => $userId,
            'token_type' => 'access',
            'iat' => time(),
            'exp' => time() + (15 * 60), // 15 minutes
            'iss' => 'micronest-api'
        ];
        
        return $this->encode($payload);
    }
    
    public function generateRefreshToken($userId) {
        $payload = [
            'user_id' => $userId,
            'token_type' => 'refresh',
            'iat' => time(),
            'exp' => time() + (30 * 24 * 60 * 60), // 30 days
            'iss' => 'micronest-api'
        ];
        
        return $this->encode($payload);
    }
    
    public function verifyAccessToken($token) {
        try {
            $decoded = $this->decode($token);
            
            if ($decoded->token_type !== 'access') {
                return false;
            }
            
            if ($decoded->exp < time()) {
                return false;
            }
            
            return $decoded;
        } catch (Exception $e) {
            return false;
        }
    }
    
    public function verifyRefreshToken($token) {
        try {
            $decoded = $this->decode($token);
            
            if ($decoded->token_type !== 'refresh') {
                return false;
            }
            
            if ($decoded->exp < time()) {
                return false;
            }
            
            return $decoded;
        } catch (Exception $e) {
            return false;
        }
    }
    
    private function encode($payload) {
        $header = [
            'typ' => 'JWT',
            'alg' => $this->algorithm
        ];
        
        $headerEncoded = $this->base64UrlEncode(json_encode($header));
        $payloadEncoded = $this->base64UrlEncode(json_encode($payload));
        
        $signature = hash_hmac('sha256', $headerEncoded . '.' . $payloadEncoded, $this->secretKey, true);
        $signatureEncoded = $this->base64UrlEncode($signature);
        
        return $headerEncoded . '.' . $payloadEncoded . '.' . $signatureEncoded;
    }
    
    private function decode($token) {
        $parts = explode('.', $token);
        
        if (count($parts) !== 3) {
            throw new Exception('Invalid token format');
        }
        
        list($headerEncoded, $payloadEncoded, $signatureEncoded) = $parts;
        
        $header = json_decode($this->base64UrlDecode($headerEncoded));
        $payload = json_decode($this->base64UrlDecode($payloadEncoded));
        
        if (!$header || !$payload) {
            throw new Exception('Invalid token data');
        }
        
        // Verify signature
        $expectedSignature = hash_hmac('sha256', $headerEncoded . '.' . $payloadEncoded, $this->secretKey, true);
        $expectedSignatureEncoded = $this->base64UrlEncode($expectedSignature);
        
        if (!hash_equals($signatureEncoded, $expectedSignatureEncoded)) {
            throw new Exception('Invalid token signature');
        }
        
        return $payload;
    }
    
    private function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
    
    private function base64UrlDecode($data) {
        $base64 = strtr($data, '-_', '+/');
        $pad = strlen($base64) % 4;
        
        if ($pad) {
            $base64 .= str_repeat('=', 4 - $pad);
        }
        
        return base64_decode($base64);
    }
}
?> 