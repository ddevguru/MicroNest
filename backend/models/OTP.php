<?php
require_once __DIR__ . '/../config/database.php';

class OTP {
    private $conn;
    private $table = 'email_otps';

    public function __construct() {
        $database = new Database();
        $this->conn = $database->getConnection();
        if (!$this->conn instanceof PDO) {
            error_log("OTP construct error: Invalid database connection");
            throw new Exception("Database connection failed");
        }
        $this->conn->exec("SET time_zone = '+00:00'");
    }

    public function generate($email) {
        $email = strtolower(trim($email));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            error_log("OTP generate error: Invalid email format - $email");
            return false;
        }
        $otp = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $currentTime = new DateTime('now', new DateTimeZone('UTC'));
        $expiresAt = $currentTime->modify('+5 minutes')->format('Y-m-d H:i:s');
        $createdAt = $currentTime->format('Y-m-d H:i:s');
        if (!$this->deleteByEmail($email)) {
            error_log("OTP generate error: Failed to delete existing OTPs for $email");
        }
        $query = "INSERT INTO " . $this->table . " (email, otp, expires_at, created_at, used) 
                  VALUES (:email, :otp, :expires_at, :created_at, 0)";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':otp', $otp);
        $stmt->bindParam(':expires_at', $expiresAt);
        $stmt->bindParam(':created_at', $createdAt);
        try {
            if ($stmt->execute()) {
                error_log("OTP generated for $email: $otp, expires at $expiresAt");
                return $otp;
            }
            error_log("OTP generate error: Failed to insert OTP for $email");
            return false;
        } catch (Exception $e) {
            error_log("OTP generate error: " . $e->getMessage());
            return false;
        }
    }

    public function verify($email, $otp) {
        $email = strtolower(trim($email));
        $otp = trim($otp);
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            error_log("OTP verify error: Invalid email format - $email");
            return false;
        }
        if (!preg_match('/^\d{6}$/', $otp)) {
            error_log("OTP verify error: Invalid OTP format - $otp");
            return false;
        }
        $dateTime = new DateTime('now', new DateTimeZone('UTC'));
        $currentTime = $dateTime->format('Y-m-d H:i:s');
        $query = "SELECT * FROM " . $this->table . " 
                  WHERE LOWER(email) = :email AND otp = :otp AND expires_at > :current_time AND used = 0 
                  ORDER BY created_at DESC LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':otp', $otp);
        $stmt->bindParam(':current_time', $currentTime);
        try {
            $stmt->execute();
            $otpRecord = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($otpRecord) {
                error_log("OTP verified for $email: $otp, expires at " . $otpRecord['expires_at']);
                $this->markAsUsed($otpRecord['id']);
                return true;
            }
            $debugQuery = "SELECT * FROM " . $this->table . " 
                           WHERE LOWER(email) = :email AND used = 0 
                           ORDER BY created_at DESC LIMIT 1";
            $debugStmt = $this->conn->prepare($debugQuery);
            $debugStmt->bindParam(':email', $email);
            $debugStmt->execute();
            $debugRecord = $debugStmt->fetch(PDO::FETCH_ASSOC);
            if ($debugRecord) {
                error_log("OTP verify failed for $email: OTP=$otp, DB OTP=" . $debugRecord['otp'] . 
                          ", Expires=" . $debugRecord['expires_at'] . ", CurrentTime=$currentTime");
            } else {
                error_log("OTP verify failed for $email: No valid OTP found");
            }
            return false;
        } catch (Exception $e) {
            error_log("OTP verify error: " . $e->getMessage());
            return false;
        }
    }

    private function markAsUsed($id) {
        $query = "UPDATE " . $this->table . " SET used = 1 WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        try {
            $result = $stmt->execute();
            if ($result) {
                error_log("OTP marked as used for id: $id");
            }
            return $result;
        } catch (Exception $e) {
            error_log("OTP markAsUsed error: " . $e->getMessage());
            return false;
        }
    }

    public function deleteByEmail($email) {
        $email = strtolower(trim($email));
        $query = "DELETE FROM " . $this->table . " WHERE LOWER(email) = :email";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':email', $email);
        try {
            $result = $stmt->execute();
            if ($result) {
                error_log("Deleted existing OTPs for $email");
            }
            return $result;
        } catch (Exception $e) {
            error_log("OTP deleteByEmail error: " . $e->getMessage());
            return false;
        }
    }

    public function cleanup() {
        $dateTime = new DateTime('now', new DateTimeZone('UTC'));
        $currentTime = $dateTime->format('Y-m-d H:i:s');
        $query = "DELETE FROM " . $this->table . " WHERE expires_at < :current_time";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':current_time', $currentTime);
        try {
            $result = $stmt->execute();
            if ($result) {
                error_log("Cleaned up expired OTPs before $currentTime");
            }
            return $result;
        } catch (Exception $e) {
            error_log("OTP cleanup error: " . $e->getMessage());
            return false;
        }
    }
}