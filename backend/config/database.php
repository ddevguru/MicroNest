<?php
class Database {
    private $host = "103.120.179.212";
    private $db_name = "devlope4_bharat";
    private $username = "sources";
    private $password = "Sources@123";
    private $conn;

    public function getConnection() {
        $this->conn = null;

        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name,
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->exec("set names utf8");
            
            error_log("Database connection successful to: " . $this->host . "/" . $this->db_name);
            return $this->conn;
            
        } catch(PDOException $exception) {
            error_log("=== DATABASE CONNECTION ERROR ===");
            error_log("Host: " . $this->host);
            error_log("Database: " . $this->db_name);
            error_log("Username: " . $this->username);
            error_log("Error: " . $exception->getMessage());
            error_log("Code: " . $exception->getCode());
            error_log("Stack trace: " . $exception->getTraceAsString());
            
            // Don't echo here, let the calling code handle it
            throw new Exception("Database connection failed: " . $exception->getMessage());
        }
    }
}
?> 