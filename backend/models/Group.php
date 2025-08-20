<?php

class Group {
    private $conn;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function getUserGroups($userId) {
        try {
            $query = "SELECT 
                        g.id,
                        g.name,
                        g.description,
                        g.target_amount,
                        g.current_amount,
                        g.member_limit,
                        g.status,
                        g.created_at,
                        g.end_date,
                        COUNT(gm.id) as member_count,
                        g.created_by,
                        CASE WHEN g.created_by = ? THEN 'creator' 
                             WHEN gm.role = 'admin' THEN 'admin'
                             ELSE 'member' END as user_role
                     FROM savings_groups g
                     LEFT JOIN group_members gm ON g.id = gm.group_id
                     WHERE g.id IN (
                         SELECT group_id FROM group_members WHERE user_id = ?
                     )
                     AND g.status = 'active'
                     GROUP BY g.id
                     ORDER BY g.created_at DESC";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId, $userId]);
            
            $groups = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Calculate progress and days remaining for each group
            foreach ($groups as &$group) {
                $group['progress_percentage'] = $this->calculateProgress($group['current_amount'], $group['target_amount']);
                $group['days_remaining'] = $this->calculateDaysRemaining($group['end_date']);
                $group['user_contributions'] = $this->getUserContributions($userId, $group['id']);
            }
            
            return $groups;
            
        } catch (Exception $e) {
            error_log("Error getting user groups: " . $e->getMessage());
            return [];
        }
    }
    
    public function getGroupDetails($groupId, $userId) {
        try {
            $query = "SELECT 
                        g.*,
                        COUNT(gm.id) as member_count,
                        CASE WHEN g.created_by = ? THEN 'creator' 
                             WHEN gm2.role = 'admin' THEN 'admin'
                             ELSE 'member' END as user_role
                     FROM savings_groups g
                     LEFT JOIN group_members gm ON g.id = gm.group_id
                     LEFT JOIN group_members gm2 ON g.id = gm2.group_id AND gm2.user_id = ?
                     WHERE g.id = ? AND g.status = 'active'
                     GROUP BY g.id";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId, $userId, $groupId]);
            
            if ($stmt->rowCount() == 0) {
                return null;
            }
            
            $group = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Add additional details
            $group['progress_percentage'] = $this->calculateProgress($group['current_amount'], $group['target_amount']);
            $group['days_remaining'] = $this->calculateDaysRemaining($group['end_date']);
            $group['members'] = $this->getGroupMembers($groupId);
            $group['contributions'] = $this->getGroupContributions($groupId);
            
            return $group;
            
        } catch (Exception $e) {
            error_log("Error getting group details: " . $e->getMessage());
            return null;
        }
    }
    
    private function calculateProgress($current, $target) {
        if ($target <= 0) return 0;
        return min(100, round(($current / $target) * 100, 1));
    }
    
    private function calculateDaysRemaining($endDate) {
        if (!$endDate) return null;
        
        $end = new DateTime($endDate);
        $now = new DateTime();
        $diff = $now->diff($end);
        
        if ($diff->invert) {
            return 0; // Past due
        }
        
        return $diff->days;
    }
    
    private function getUserContributions($userId, $groupId) {
        try {
            $query = "SELECT 
                        SUM(amount) as total_contributed,
                        COUNT(*) as contribution_count,
                        MAX(created_at) as last_contribution
                     FROM group_contributions 
                     WHERE user_id = ? AND group_id = ?";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId, $groupId]);
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return [
                'total_contributed' => $result['total_contributed'] ?? 0,
                'contribution_count' => $result['contribution_count'] ?? 0,
                'last_contribution' => $result['last_contribution'] ?? null
            ];
            
        } catch (Exception $e) {
            error_log("Error getting user contributions: " . $e->getMessage());
            return ['total_contributed' => 0, 'contribution_count' => 0, 'last_contribution' => null];
        }
    }
    
    private function getGroupMembers($groupId) {
        try {
            $query = "SELECT 
                        u.id,
                        u.full_name,
                        u.username,
                        u.profile_image,
                        gm.role,
                        gm.joined_at
                     FROM group_members gm
                     JOIN users u ON gm.user_id = u.id
                     WHERE gm.group_id = ?
                     ORDER BY gm.joined_at ASC";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId]);
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
            
        } catch (Exception $e) {
            error_log("Error getting group members: " . $e->getMessage());
            return [];
        }
    }
    
    private function getGroupContributions($groupId) {
        try {
            $query = "SELECT 
                        gc.id,
                        gc.amount,
                        gc.description,
                        gc.created_at,
                        u.full_name,
                        u.username
                     FROM group_contributions gc
                     JOIN users u ON gc.user_id = u.id
                     WHERE gc.group_id = ?
                     ORDER BY gc.created_at DESC
                     LIMIT 10";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId]);
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
            
        } catch (Exception $e) {
            error_log("Error getting group contributions: " . $e->getMessage());
            return [];
        }
    }
}
?> 