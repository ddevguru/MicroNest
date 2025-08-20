<?php
require_once '../config/database.php';
require_once '../utils/ResponseUtil.php';

class User {
    private $conn;
    
    public function __construct() {
        $database = new Database();
        $this->conn = $database->getConnection();
    }
    
    public function getProfile($userId) {
        try {
            $query = "SELECT id, full_name, email, username, phone, address, profile_image, 
                             email_verified, email_verified_at, status, trust_score, created_at, updated_at
                     FROM users WHERE id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() == 0) {
                return ResponseUtil::error('User not found', 404);
            }
            
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return ResponseUtil::success('Profile retrieved successfully', $user);
            
        } catch (Exception $e) {
            return ResponseUtil::error('Failed to get profile: ' . $e->getMessage(), 500);
        }
    }
    
    public function updateProfile($userId, $data) {
        try {
            // Validate user exists
            $query = "SELECT id FROM users WHERE id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() == 0) {
                return ResponseUtil::error('User not found', 404);
            }
            
            // Build update query dynamically
            $updateFields = [];
            $updateValues = [];
            
            $allowedFields = ['full_name', 'phone', 'address', 'profile_image'];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field]) && !empty($data[$field])) {
                    $updateFields[] = "$field = ?";
                    $updateValues[] = $data[$field];
                }
            }
            
            if (empty($updateFields)) {
                return ResponseUtil::error('No valid fields to update', 400);
            }
            
            $updateValues[] = $userId;
            
            $query = "UPDATE users SET " . implode(', ', $updateFields) . ", updated_at = NOW() WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute($updateValues);
            
            // Get updated profile
            return $this->getProfile($userId);
            
        } catch (Exception $e) {
            return ResponseUtil::error('Failed to update profile: ' . $e->getMessage(), 500);
        }
    }
    
    public function getTrustScore($userId) {
        try {
            $query = "SELECT trust_score FROM users WHERE id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() == 0) {
                return ResponseUtil::error('User not found', 404);
            }
            
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Get trust score history
            $historyQuery = "SELECT score_change, reason, related_entity_type, created_at 
                           FROM trust_score_history 
                           WHERE user_id = ? 
                           ORDER BY created_at DESC 
                           LIMIT 10";
            $historyStmt = $this->conn->prepare($historyQuery);
            $historyStmt->execute([$userId]);
            $history = $historyStmt->fetchAll(PDO::FETCH_ASSOC);
            
            $result = [
                'current_score' => $user['trust_score'],
                'history' => $history
            ];
            
            return ResponseUtil::success('Trust score retrieved successfully', $result);
            
        } catch (Exception $e) {
            return ResponseUtil::error('Failed to get trust score: ' . $e->getMessage(), 500);
        }
    }
    
    public function updateTrustScore($userId, $scoreChange, $reason, $relatedEntityType = 'contribution', $relatedEntityId = null) {
        try {
            // Start transaction
            $this->conn->beginTransaction();
            
            // Update user's trust score
            $query = "UPDATE users SET trust_score = trust_score + ?, updated_at = NOW() WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$scoreChange, $userId]);
            
            // Record trust score change
            $historyQuery = "INSERT INTO trust_score_history (user_id, score_change, reason, related_entity_type, related_entity_id) 
                           VALUES (?, ?, ?, ?, ?)";
            $historyStmt = $this->conn->prepare($historyQuery);
            $historyStmt->execute([$userId, $scoreChange, $reason, $relatedEntityType, $relatedEntityId]);
            
            // Commit transaction
            $this->conn->commit();
            
            return true;
            
        } catch (Exception $e) {
            // Rollback transaction
            $this->conn->rollback();
            throw new Exception('Failed to update trust score: ' . $e->getMessage());
        }
    }
    
    public function getUserById($userId) {
        try {
            $query = "SELECT id, full_name, email, username, phone, address, profile_image, 
                             email_verified, status, trust_score, created_at
                     FROM users WHERE id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() == 0) {
                return null;
            }
            
            return $stmt->fetch(PDO::FETCH_ASSOC);
            
        } catch (Exception $e) {
            return null;
        }
    }
    
    public function getUserByEmail($email) {
        try {
            $query = "SELECT id, full_name, email, username, phone, address, profile_image, 
                             email_verified, status, trust_score, created_at
                     FROM users WHERE email = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$email]);
            
            if ($stmt->rowCount() == 0) {
                return null;
            }
            
            return $stmt->fetch(PDO::FETCH_ASSOC);
            
        } catch (Exception $e) {
            return null;
        }
    }
    
    public function getUserByUsername($username) {
        try {
            $query = "SELECT id, full_name, email, username, phone, address, profile_image, 
                             email_verified, status, trust_score, created_at
                     FROM users WHERE username = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$username]);
            
            if ($stmt->rowCount() == 0) {
                return null;
            }
            
            return $stmt->fetch(PDO::FETCH_ASSOC);
            
        } catch (Exception $e) {
            return null;
        }
    }
    
    public function searchUsers($searchTerm, $limit = 20) {
        try {
            $query = "SELECT id, full_name, username, trust_score, created_at
                     FROM users 
                     WHERE (full_name LIKE ? OR username LIKE ?) AND status = 'active'
                     ORDER BY trust_score DESC, created_at DESC
                     LIMIT ?";
            
            $searchPattern = "%$searchTerm%";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$searchPattern, $searchPattern, $limit]);
            
            $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return ResponseUtil::success('Users found', $users);
            
        } catch (Exception $e) {
            return ResponseUtil::error('Failed to search users: ' . $e->getMessage(), 500);
        }
    }
    
    public function getTopUsers($limit = 10) {
        try {
            $query = "SELECT id, full_name, username, trust_score, created_at
                     FROM users 
                     WHERE status = 'active'
                     ORDER BY trust_score DESC, created_at DESC
                     LIMIT ?";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$limit]);
            
            $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return ResponseUtil::success('Top users retrieved successfully', $users);
            
        } catch (Exception $e) {
            return ResponseUtil::error('Failed to get top users: ' . $e->getMessage(), 500);
        }
    }
    
    public function deactivateUser($userId, $reason = 'User requested deactivation') {
        try {
            $query = "UPDATE users SET status = 'inactive', updated_at = NOW() WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() > 0) {
                return ResponseUtil::success('User deactivated successfully');
            } else {
                return ResponseUtil::error('User not found or already deactivated', 404);
            }
            
        } catch (Exception $e) {
            return ResponseUtil::error('Failed to deactivate user: ' . $e->getMessage(), 500);
        }
    }
    
    public function reactivateUser($userId) {
        try {
            $query = "UPDATE users SET status = 'active', updated_at = NOW() WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() > 0) {
                return ResponseUtil::success('User reactivated successfully');
            } else {
                return ResponseUtil::error('User not found', 404);
            }
            
        } catch (Exception $e) {
            return ResponseUtil::error('Failed to reactivate user: ' . $e->getMessage(), 500);
        }
    }
}
?> 