<?php
require_once __DIR__ . '/../config/database.php';

class Wallet {
    private $conn;

    public function __construct() {
        $database = new Database();
        $this->conn = $database->getConnection();
    }

    public function createWallet($userId) {
        $query = "INSERT INTO user_wallets (user_id) VALUES (:user_id)";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId);
        return $stmt->execute();
    }

    public function getWallet($userId) {
        $query = "SELECT * FROM user_wallets WHERE user_id = :user_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function getOrCreateWallet($userId) {
        $wallet = $this->getWallet($userId);
        if (!$wallet) {
            $this->createWallet($userId);
            $wallet = $this->getWallet($userId);
        }
        return $wallet;
    }

    public function addTransaction($walletId, $userId, $type, $amount, $description, $referenceType, $referenceId = null) {
        $query = "INSERT INTO wallet_transactions (wallet_id, user_id, type, amount, description, reference_type, reference_id) 
                  VALUES (:wallet_id, :user_id, :type, :amount, :description, :reference_type, :reference_id)";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':wallet_id', $walletId);
        $stmt->bindParam(':user_id', $userId);
        $stmt->bindParam(':type', $type);
        $stmt->bindParam(':amount', $amount);
        $stmt->bindParam(':description', $description);
        $stmt->bindParam(':reference_type', $referenceType);
        $stmt->bindParam(':reference_id', $referenceId);
        return $stmt->execute();
    }

    public function updateBalance($walletId, $amount, $type) {
        $operator = $type === 'credit' ? '+' : '-';
        $query = "UPDATE user_wallets 
                  SET balance = balance $operator :amount,
                      total_earned = CASE WHEN :type = 'credit' THEN total_earned + :amount ELSE total_earned END,
                      total_spent = CASE WHEN :type = 'debit' THEN total_spent + :amount ELSE total_spent END,
                      updated_at = CURRENT_TIMESTAMP
                  WHERE id = :wallet_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':amount', $amount);
        $stmt->bindParam(':type', $type);
        $stmt->bindParam(':wallet_id', $walletId);
        return $stmt->execute();
    }

    public function getTransactions($userId, $limit = 50) {
        $query = "SELECT wt.*, uw.balance 
                  FROM wallet_transactions wt 
                  JOIN user_wallets uw ON wt.wallet_id = uw.id 
                  WHERE wt.user_id = :user_id 
                  ORDER BY wt.created_at DESC 
                  LIMIT :limit";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getConnection() {
        return $this->conn;
    }
}
?> 