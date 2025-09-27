<?php
require_once __DIR__ . '/../config/database.php';

class User {
    private $conn;
    private $table = 'users';

    public function __construct() {
        $database = new Database();
        $this->conn = $database->getConnection();
        if (!$this->conn instanceof PDO) {
            error_log("User construct error: Invalid database connection");
            throw new Exception("Database connection failed");
        }
    }

    public function create($userData) {
        $query = "INSERT INTO " . $this->table . " 
                  (full_name, email, username, password_hash, phone, address, profile_image, email_verified, status, trust_score, created_at, updated_at) 
                  VALUES (:full_name, :email, :username, :password_hash, :phone, :address, :profile_image, :email_verified, :status, :trust_score, NOW(), NOW())";

        $stmt = $this->conn->prepare($query);

        // Hash password using MD5 (WARNING: MD5 is not secure for password hashing in production; consider Argon2 or bcrypt)
        $passwordHash = md5($userData['password']);

        // Normalize email to lowercase
        $email = strtolower(trim($userData['email']));

        // Set default values
        $emailVerified = 0;
        $status = 'active';
        $trustScore = 0;
        $profileImage = $userData['profile_image'] ?? null;

        $stmt->bindParam(':full_name', $userData['full_name']);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':username', $userData['username']);
        $stmt->bindParam(':password_hash', $passwordHash);
        $stmt->bindParam(':phone', $userData['phone']);
        $stmt->bindParam(':address', $userData['address']);
        $stmt->bindParam(':profile_image', $profileImage, PDO::PARAM_STR | PDO::PARAM_NULL);
        $stmt->bindParam(':email_verified', $emailVerified, PDO::PARAM_INT);
        $stmt->bindParam(':status', $status);
        $stmt->bindParam(':trust_score', $trustScore, PDO::PARAM_INT);

        try {
            if ($stmt->execute()) {
                error_log("User created successfully: Email = $email, Username = {$userData['username']}");
                return $this->conn->lastInsertId();
            }
            $errorInfo = $stmt->errorInfo();
            error_log("Failed to create user: SQLSTATE[{$errorInfo[0]}]: {$errorInfo[2]}");
            return false;
        } catch (PDOException $e) {
            error_log("Error creating user: " . $e->getMessage() . " | Input: " . json_encode($userData));
            return false;
        }
    }

    public function findByEmail($email) {
        $email = strtolower(trim($email));
        $query = "SELECT * FROM " . $this->table . " WHERE LOWER(email) = :email LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':email', $email);

        try {
            $stmt->execute();
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($result) {
                error_log("User found by email: $email, ID = {$result['id']}");
            } else {
                error_log("No user found for email: $email");
                // Debug: Check all emails in the table
                $debugStmt = $this->conn->query("SELECT email FROM " . $this->table);
                $emails = $debugStmt->fetchAll(PDO::FETCH_COLUMN);
                error_log("All emails in users table: " . json_encode($emails));
            }
            return $result;
        } catch (PDOException $e) {
            error_log("Error finding user by email ($email): " . $e->getMessage());
            return false;
        }
    }

    public function findByUsername($username) {
        $query = "SELECT * FROM " . $this->table . " WHERE username = :username LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':username', $username);

        try {
            $stmt->execute();
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($result) {
                error_log("User found by username: $username");
            } else {
                error_log("No user found for username: $username");
            }
            return $result;
        } catch (PDOException $e) {
            error_log("Error finding user by username ($username): " . $e->getMessage());
            return false;
        }
    }

    public function findById($id) {
        $query = "SELECT * FROM " . $this->table . " WHERE id = :id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);

        try {
            $stmt->execute();
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($result) {
                error_log("User found by ID: $id");
            } else {
                error_log("No user found for ID: $id");
            }
            return $result;
        } catch (PDOException $e) {
            error_log("Error finding user by ID ($id): " . $e->getMessage());
            return false;
        }
    }

    public function verifyEmail($email) {
        $email = strtolower(trim($email));
        $query = "UPDATE " . $this->table . " SET email_verified = 1, updated_at = NOW() WHERE LOWER(email) = :email";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':email', $email);

        try {
            $result = $stmt->execute();
            if ($result) {
                error_log("Email verified successfully for: $email");
            } else {
                error_log("Failed to verify email for: $email");
            }
            return $result;
        } catch (PDOException $e) {
            error_log("Error verifying email ($email): " . $e->getMessage());
            return false;
        }
    }

    public function emailExists($email) {
        $email = strtolower(trim($email));
        $result = $this->findByEmail($email);
        return $result !== false;
    }

    public function usernameExists($username) {
        $result = $this->findByUsername($username);
        return $result !== false;
    }

    public function verifyPassword($password, $hash) {
        $result = (md5($password) === $hash);
        if (!$result) {
            error_log("Password verification failed for hash: $hash");
        } else {
            error_log("Password verification successful");
        }
        return $result;
    }

    public function getUserData($user) {
        if (!$user) {
            error_log("No user data provided to getUserData");
            return null;
        }
        $data = [
            'id' => (int)$user['id'],
            'full_name' => $user['full_name'],
            'email' => $user['email'],
            'username' => $user['username'],
            'phone' => $user['phone'],
            'address' => $user['address'],
            'profile_image' => $user['profile_image'],
            'email_verified' => (bool)$user['email_verified'],
            'status' => $user['status'],
            'trust_score' => (int)$user['trust_score'],
            'created_at' => $user['created_at'],
            'updated_at' => $user['updated_at']
        ];
        error_log("User data retrieved: " . json_encode($data));
        return $data;
    }

    public function updatePassword($email, $newPassword) {
        $email = strtolower(trim($email));
        $passwordHash = md5($newPassword);
        $query = "UPDATE " . $this->table . " SET password_hash = :password_hash, updated_at = NOW() WHERE LOWER(email) = :email";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':password_hash', $passwordHash);
        $stmt->bindParam(':email', $email);

        try {
            $result = $stmt->execute();
            if ($result) {
                error_log("Password updated successfully for: $email");
            } else {
                error_log("Failed to update password for: $email");
            }
            return $result;
        } catch (PDOException $e) {
            error_log("Error updating password for email ($email): " . $e->getMessage());
            return false;
        }
    }
}
?>