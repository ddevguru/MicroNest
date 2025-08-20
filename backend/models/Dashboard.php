<?php
require_once __DIR__ . '/../utils/ResponseUtil.php';

class Dashboard {
    private $conn;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function getDashboardData($userId) {
        try {
            // Get user basic info
            $userInfo = $this->getUserInfo($userId);
            if (!$userInfo) {
                return ResponseUtil::error('User not found', 404);
            }
            
            // Get wallet balance
            $walletBalance = $this->getWalletBalance($userId);
            
            // Get groups data
            $groups = $this->getUserGroups($userId);
            
            // Get recent activities
            $recentActivities = $this->getRecentActivities($userId);
            
            return ResponseUtil::success('Dashboard data retrieved successfully', [
                'user' => $userInfo,
                'wallet' => [
                    'balance' => $walletBalance,
                    'currency' => 'INR'
                ],
                'groups' => $groups,
                'recent_activities' => $recentActivities
            ]);
            
        } catch (Exception $e) {
            error_log("Dashboard getDashboardData Error: " . $e->getMessage());
            return ResponseUtil::error('Failed to retrieve dashboard data: ' . $e->getMessage(), 500);
        }
    }
    
    private function getUserInfo($userId) {
        try {
            $query = "SELECT id, email, username, full_name, phone, trust_score, 
                             email_verified, kyc_status, profile_image, created_at, updated_at
                      FROM users WHERE id = ?";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() > 0) {
                return $stmt->fetch(PDO::FETCH_ASSOC);
            }
            
            return null;
            
        } catch (Exception $e) {
            error_log("Dashboard getUserInfo Error: " . $e->getMessage());
            return null;
        }
    }
    
    private function getWalletBalance($userId) {
        try {
            $query = "SELECT COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE -amount END), 0) as balance FROM wallet_transactions 
                      WHERE user_id = ?";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result['balance'] ?? 0;
            
        } catch (Exception $e) {
            error_log("Dashboard getWalletBalance Error: " . $e->getMessage());
            return 0;
        }
    }
    
    private function getUserGroups($userId) {
        try {
            $query = "SELECT g.id, g.name, g.description, g.target_amount, g.current_amount, 
                             g.member_limit, g.status, g.created_at, g.end_date,
                             gm.role as member_role, gm.joined_at
                      FROM savings_groups g
                      INNER JOIN group_members gm ON g.id = gm.group_id
                      WHERE gm.user_id = ? AND g.status = 'active'
                      ORDER BY gm.joined_at DESC
                      LIMIT 5";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            $groups = [];
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $groups[] = [
                    'id' => $row['id'],
                    'name' => $row['name'],
                    'description' => $row['description'],
                    'target_amount' => $row['target_amount'],
                    'current_amount' => $row['current_amount'],
                    'member_limit' => $row['member_limit'],
                    'status' => $row['status'],
                    'member_role' => $row['member_role'],
                    'joined_at' => $row['joined_at'],
                    'end_date' => $row['end_date'],
                    'progress_percentage' => round(($row['current_amount'] / $row['target_amount']) * 100, 2)
                ];
            }
            
            return $groups;
            
        } catch (Exception $e) {
            error_log("Dashboard getUserGroups Error: " . $e->getMessage());
            return [];
        }
    }
    
    private function getRecentActivities($userId) {
        try {
            $activities = [];
            
            // Get recent contributions
            $query = "SELECT 'contribution' as type, amount, created_at, 'Contributed ₹' || amount as description
                      FROM group_contributions 
                      WHERE user_id = ?
                      ORDER BY created_at DESC LIMIT 3";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $activities[] = $row;
            }
            
            // Get recent group joins
            $query = "SELECT 'group_join' as type, NULL as amount, gm.joined_at as created_at, 
                             'Joined group: ' || g.name as description
                      FROM group_members gm
                      INNER JOIN savings_groups g ON gm.group_id = g.id
                      WHERE gm.user_id = ?
                      ORDER BY gm.joined_at DESC LIMIT 2";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $activities[] = $row;
            }
            
            // Sort by date and limit to 5
            usort($activities, function($a, $b) {
                return strtotime($b['created_at']) - strtotime($a['created_at']);
            });
            
            return array_slice($activities, 0, 5);
            
        } catch (Exception $e) {
            error_log("Dashboard getRecentActivities Error: " . $e->getMessage());
            return [];
        }
    }
}
?> 