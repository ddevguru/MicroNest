<?php
require_once __DIR__ . '/../config/database.php';

class RefreshToken {
    private $conn;
    private $table = 'refresh_tokens';

    public function __construct() {
        $database = new Database();
        $this->conn = $database->getConnection();
        if (!$this->conn instanceof PDO) {
            error_log("RefreshToken construct error: Invalid database connection");
            throw new Exception("Database connection failed");
        }
    }

    public function getConnection() {
        return $this->conn;
    }

    public function store($userId, $token) {
        $tokenHash = hash('sha256', $token);
        $expiresAt = date('Y-m-d H:i:s', time() + REFRESH_TOKEN_EXPIRY);

        // Delete any existing refresh tokens for this user
        $this->deleteByUserId($userId);

        $query = "INSERT INTO " . $this->table . " (user_id, token_hash, expires_at) VALUES (:user_id, :token_hash, :expires_at)";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindParam(':token_hash', $tokenHash);
        $stmt->bindParam(':expires_at', $expiresAt);

        try {
            if ($stmt->execute()) {
                error_log("Refresh token stored successfully for user ID: $userId");
                return true;
            }
            $errorInfo = $stmt->errorInfo();
            error_log("RefreshToken store error: Failed to insert token for user ID = $userId. SQL Error: " . json_encode($errorInfo));
            return false;
        } catch (PDOException $e) {
            error_log("RefreshToken store error: " . $e->getMessage() . " | User ID: $userId | Trace: " . $e->getTraceAsString());
            return false;
        }
    }

    public function verify($token) {
        $tokenHash = hash('sha256', $token);
        
        $query = "SELECT user_id FROM " . $this->table . " 
                  WHERE token_hash = :token_hash AND expires_at > NOW() LIMIT 1";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':token_hash', $tokenHash);
        
        try {
            $stmt->execute();
            $result = $stmt->fetch();
            if ($result) {
                error_log("Refresh token verified for user ID: {$result['user_id']}");
                return $result['user_id'];
            }
            error_log("Refresh token verification failed: No valid token found");
            return false;
        } catch (PDOException $e) {
            error_log("RefreshToken verify error: " . $e->getMessage());
            return false;
        }
    }

    public function deleteByToken($token) {
        $tokenHash = hash('sha256', $token);
        
        $query = "DELETE FROM " . $this->table . " WHERE token_hash = :token_hash";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':token_hash', $tokenHash);
        
        try {
            $result = $stmt->execute();
            if ($result) {
                error_log("Refresh token deleted for token hash: $tokenHash");
            }
            return $result;
        } catch (PDOException $e) {
            error_log("RefreshToken deleteByToken error: " . $e->getMessage());
            return false;
        }
    }

    public function deleteByUserId($userId) {
        $query = "DELETE FROM " . $this->table . " WHERE user_id = :user_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        
        try {
            $result = $stmt->execute();
            if ($result) {
                error_log("Deleted existing refresh tokens for user ID: $userId");
            }
            return $result;
        } catch (PDOException $e) {
            error_log("RefreshToken deleteByUserId error: " . $e->getMessage());
            return false;
        }
    }

    public function cleanup() {
        $query = "DELETE FROM " . $this->table . " WHERE expires_at < NOW()";
        $stmt = $this->conn->prepare($query);
        
        try {
            $result = $stmt->execute();
            if ($result) {
                error_log("Cleaned up expired refresh tokens");
            }
            return $result;
        } catch (PDOException $e) {
            error_log("RefreshToken cleanup error: " . $e->getMessage());
            return false;
        }
    }
}
?>