<?php
require_once __DIR__ . '/../vendor/autoload.php';
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class JWTHandler {
    public static function generateAccessToken($userId, $email) {
        $payload = [
            'iss' => 'micronest-api',
            'aud' => 'micronest-app',
            'iat' => time(),
            'exp' => time() + ACCESS_TOKEN_EXPIRY,
            'user_id' => $userId,
            'email' => $email,
            'type' => 'access'
        ];

        return JWT::encode($payload, JWT_SECRET, JWT_ALGORITHM);
    }

    public static function generateRefreshToken($userId) {
        $payload = [
            'iss' => 'micronest-api',
            'aud' => 'micronest-app',
            'iat' => time(),
            'exp' => time() + REFRESH_TOKEN_EXPIRY,
            'user_id' => $userId,
            'type' => 'refresh'
        ];

        return JWT::encode($payload, JWT_SECRET, JWT_ALGORITHM);
    }

    public static function validateToken($token) {
        try {
            $decoded = JWT::decode($token, new Key(JWT_SECRET, JWT_ALGORITHM));
            return (array) $decoded;
        } catch (Exception $e) {
            return false;
        }
    }

    public static function getUserFromToken($token) {
        $decoded = self::validateToken($token);
        if ($decoded && isset($decoded['user_id'])) {
            return $decoded['user_id'];
        }
        return false;
    }

    public static function verifyAccessToken($token) {
        try {
            $decoded = JWT::decode($token, new Key(JWT_SECRET, JWT_ALGORITHM));
            $decodedArray = (array) $decoded;
            
            // Check if it's an access token
            if (isset($decodedArray['type']) && $decodedArray['type'] === 'access') {
                return $decodedArray['user_id'];
            }
            
            return false;
        } catch (Exception $e) {
            error_log("JWT verification error: " . $e->getMessage());
            return false;
        }
    }
}
?>
