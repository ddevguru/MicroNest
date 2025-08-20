<?php

class Wallet {
    private $conn;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function getUserWallet($userId) {
        try {
            // Get user's wallet balance and trust score
            $query = "SELECT 
                        u.id,
                        u.full_name,
                        u.email,
                        u.trust_score,
                        COALESCE(SUM(t.amount), 0) as total_balance,
                        COALESCE(SUM(CASE WHEN t.type = 'credit' THEN t.amount ELSE 0 END), 0) as total_credits,
                        COALESCE(SUM(CASE WHEN t.type = 'debit' THEN t.amount ELSE 0 END), 0) as total_debits,
                        COUNT(t.id) as transaction_count
                     FROM users u
                     LEFT JOIN wallet_transactions t ON u.id = t.user_id
                     WHERE u.id = ? AND u.status = 'active'
                     GROUP BY u.id";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() == 0) {
                return null;
            }
            
            $wallet = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Calculate net balance
            $wallet['net_balance'] = $wallet['total_credits'] - $wallet['total_debits'];
            
            // Get recent transactions
            $wallet['recent_transactions'] = $this->getRecentTransactions($userId, 5);
            
            return $wallet;
            
        } catch (Exception $e) {
            error_log("Error getting user wallet: " . $e->getMessage());
            return null;
        }
    }
    
    public function getRecentTransactions($userId, $limit = 5) {
        try {
            $query = "SELECT 
                        id,
                        type,
                        amount,
                        description,
                        created_at
                     FROM wallet_transactions 
                     WHERE user_id = ? 
                     ORDER BY created_at DESC 
                     LIMIT ?";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId, $limit]);
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
            
        } catch (Exception $e) {
            error_log("Error getting recent transactions: " . $e->getMessage());
            return [];
        }
    }
    
    public function addTransaction($userId, $type, $amount, $description) {
        try {
            $query = "INSERT INTO wallet_transactions (user_id, type, amount, description) 
                     VALUES (?, ?, ?, ?)";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId, $type, $amount, $description]);
            
            return $this->conn->lastInsertId();
            
        } catch (Exception $e) {
            error_log("Error adding transaction: " . $e->getMessage());
            return false;
        }
    }
}
?> 