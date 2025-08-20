<?php
require_once '../config/database.php';

class Profile {
    private $conn;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    // Get complete profile data including user info, stats, trust score, and awards
    public function getCompleteProfile($userId) {
        try {
            // Get user basic info
            $userInfo = $this->getUserInfo($userId);
            if (!$userInfo) {
                return ResponseUtil::error('User not found', 404);
            }
            
            // Get account stats
            $stats = $this->getAccountStats($userId);
            
            // Get trust score details
            $trust = $this->getTrustScoreDetails($userId);
            
            // Get awards and achievements
            $awards = $this->getAwardsAndAchievements($userId);
            
            // Get notification settings
            $notifications = $this->getNotificationSettings($userId);
            
            // Get security settings
            $security = $this->getSecuritySettings($userId);
            
            return ResponseUtil::success('Profile data retrieved successfully', [
                'user' => $userInfo,
                'stats' => $stats,
                'trust' => $trust,
                'awards' => $awards,
                'notifications' => $notifications,
                'security' => $security
            ]);
            
        } catch (Exception $e) {
            error_log("Profile getCompleteProfile Error: " . $e->getMessage());
            return ResponseUtil::error('Failed to retrieve profile data: ' . $e->getMessage(), 500);
        }
    }
    
    // Get user basic information
    private function getUserInfo($userId) {
        try {
            $query = "SELECT id, email, username, full_name, phone, trust_score, 
                             email_verified, kyc_status, created_at, updated_at
                      FROM users WHERE id = ?";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() > 0) {
                return $stmt->fetch(PDO::FETCH_ASSOC);
            }
            
            return null;
            
        } catch (Exception $e) {
            error_log("Profile getUserInfo Error: " . $e->getMessage());
            return null;
        }
    }
    
    // Get account statistics
    private function getAccountStats($userId) {
        try {
            $stats = [];
            
            // Get groups joined count
            $query = "SELECT COUNT(*) as count FROM group_members WHERE user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $stats['groups_joined'] = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            
            // Get total contributed amount
            $query = "SELECT COALESCE(SUM(amount), 0) as total FROM group_contributions 
                      WHERE user_id = ? AND status = 'completed'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $stats['total_contributed'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
            
            // Get active loans count
            $query = "SELECT COUNT(*) as count FROM loans WHERE user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $stats['active_loans'] = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            
            return $stats;
            
        } catch (Exception $e) {
            error_log("Profile getAccountStats Error: " . $e->getMessage());
            return [
                'groups_joined' => 0,
                'total_contributed' => 0,
                'active_loans' => 0
            ];
        }
    }
    
    // Get trust score details
    public function getTrustScoreDetails($userId) {
        try {
            // Get overall trust score
            $query = "SELECT trust_score FROM users WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $overallScore = $stmt->fetch(PDO::FETCH_ASSOC)['trust_score'] ?? 0;
            
            // Calculate breakdown scores
            $breakdown = $this->calculateTrustBreakdown($userId);
            
            return [
                'overall_score' => $overallScore,
                'breakdown' => $breakdown
            ];
            
        } catch (Exception $e) {
            error_log("Profile getTrustScoreDetails Error: " . $e->getMessage());
            return [
                'overall_score' => 0,
                'breakdown' => []
            ];
        }
    }
    
    // Calculate trust score breakdown
    private function calculateTrustBreakdown($userId) {
        try {
            $breakdown = [];
            
            // Payment History Score (based on loan repayments)
            $query = "SELECT 
                        COUNT(*) as total_payments,
                        SUM(CASE WHEN status = 'completed' AND due_date >= payment_date THEN 1 ELSE 0 END) as on_time_payments
                      FROM loan_payments WHERE user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $paymentData = $stmt->fetch(PDO::FETCH_ASSOC);
            
            $paymentScore = $paymentData['total_payments'] > 0 
                ? round(($paymentData['on_time_payments'] / $paymentData['total_payments']) * 100)
                : 85; // Default score for new users
                
            $breakdown[] = [
                'name' => 'Payment History',
                'description' => 'On-time payments and contributions',
                'score' => $paymentScore,
                'max_score' => 100
            ];
            
            // Group Participation Score
            $query = "SELECT COUNT(*) as active_groups FROM group_members 
                      WHERE user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $activeGroups = $stmt->fetch(PDO::FETCH_ASSOC)['active_groups'];
            
            $participationScore = min(100, $activeGroups * 20 + 60); // Base 60 + 20 per group
            
            $breakdown[] = [
                'name' => 'Group Participation',
                'description' => 'Active group member',
                'score' => $participationScore,
                'max_score' => 100
            ];
            
            // Identity Verification Score (KYC)
            $query = "SELECT kyc_status FROM users WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $kycStatus = $stmt->fetch(PDO::FETCH_ASSOC)['kyc_status'];
            
            $kycScore = $kycStatus === 'verified' ? 100 : 
                       ($kycStatus === 'pending' ? 60 : 30);
                       
            $breakdown[] = [
                'name' => 'Identity Verification',
                'description' => 'KYC completion status',
                'score' => $kycScore,
                'max_score' => 100
            ];
            
            // Network Trust Score (based on group member relationships)
            $query = "SELECT COUNT(DISTINCT gm2.user_id) as network_size
                      FROM group_members gm1
                      JOIN group_members gm2 ON gm1.group_id = gm2.group_id
                      WHERE gm1.user_id = ? AND gm1.user_id != gm2.user_id";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $networkSize = $stmt->fetch(PDO::FETCH_ASSOC)['network_size'];
            
            $networkScore = min(100, $networkSize * 5 + 50); // Base 50 + 5 per connection
            
            $breakdown[] = [
                'name' => 'Network Trust',
                'description' => 'Community connections and reputation',
                'score' => $networkScore,
                'max_score' => 100
            ];
            
            return $breakdown;
            
        } catch (Exception $e) {
            error_log("Profile calculateTrustBreakdown Error: " . $e->getMessage());
            return [];
        }
    }
    
    // Get awards and achievements
    public function getAwardsAndAchievements($userId) {
        try {
            $awards = [];
            $earnedCount = 0;
            
            // First Contribution Award
            $query = "SELECT COUNT(*) as count FROM group_contributions WHERE user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $contributionCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            
            $firstContributionEarned = $contributionCount > 0;
            if ($firstContributionEarned) $earnedCount++;
            
            $awards[] = [
                'name' => 'First Contribution',
                'description' => 'Made your first group contribution',
                'is_earned' => $firstContributionEarned,
                'progress' => $firstContributionEarned ? 100 : 0,
                'earned_date' => $firstContributionEarned ? date('m/d/Y') : null
            ];
            
            // Trusted Member Award
            $query = "SELECT trust_score FROM users WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $trustScore = $stmt->fetch(PDO::FETCH_ASSOC)['trust_score'] ?? 0;
            
            $trustedMemberEarned = $trustScore >= 75;
            if ($trustedMemberEarned) $earnedCount++;
            
            $awards[] = [
                'name' => 'Trusted Member',
                'description' => 'Achieved 75% trust score',
                'is_earned' => $trustedMemberEarned,
                'progress' => min(100, $trustScore),
                'earned_date' => $trustedMemberEarned ? date('m/d/Y') : null
            ];
            
            // Group Builder Award
            $query = "SELECT COUNT(*) as count FROM savings_groups WHERE created_by = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $groupsCreated = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            
            $groupBuilderEarned = $groupsCreated > 0;
            if ($groupBuilderEarned) $earnedCount++;
            
            $awards[] = [
                'name' => 'Group Builder',
                'description' => 'Helped create a new savings group',
                'is_earned' => $groupBuilderEarned,
                'progress' => $groupBuilderEarned ? 100 : 50,
                'earned_date' => $groupBuilderEarned ? date('m/d/Y') : null
            ];
            
            // Perfect Payer Award
            $query = "SELECT COUNT(*) as total_loans FROM loans WHERE user_id = ? AND status = 'completed'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $totalLoans = $stmt->fetch(PDO::FETCH_ASSOC)['total_loans'];
            
            $query = "SELECT COUNT(*) as perfect_payments FROM loans l
                      JOIN loan_payments lp ON l.id = lp.loan_id
                      WHERE l.user_id = ? AND l.status = 'completed' 
                      AND lp.status = 'completed' AND lp.due_date >= lp.payment_date";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $perfectPayments = $stmt->fetch(PDO::FETCH_ASSOC)['perfect_payments'];
            
            $perfectPayerEarned = $totalLoans >= 5 && $perfectPayments >= 5;
            $perfectPayerProgress = $totalLoans > 0 ? min(100, ($perfectPayments / 5) * 100) : 0;
            
            if ($perfectPayerEarned) $earnedCount++;
            
            $awards[] = [
                'name' => 'Perfect Payer',
                'description' => 'Completed 5 loans with perfect repayment',
                'is_earned' => $perfectPayerEarned,
                'progress' => $perfectPayerProgress,
                'earned_date' => $perfectPayerEarned ? date('m/d/Y') : null
            ];
            
            // Savings Champion Award
            $query = "SELECT COALESCE(SUM(amount), 0) as total_saved FROM group_contributions 
                      WHERE user_id = ? AND status = 'completed'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            $totalSaved = $stmt->fetch(PDO::FETCH_ASSOC)['total_saved'];
            
            $savingsChampionEarned = $totalSaved >= 10000; // ₹10,000
            if ($savingsChampionEarned) $earnedCount++;
            
            $awards[] = [
                'name' => 'Savings Champion',
                'description' => 'Saved ₹10,000 or more',
                'is_earned' => $savingsChampionEarned,
                'progress' => min(100, ($totalSaved / 10000) * 100),
                'earned_date' => $savingsChampionEarned ? date('m/d/Y') : null
            ];
            
            return [
                'earned_count' => $earnedCount,
                'total_count' => count($awards),
                'list' => $awards
            ];
            
        } catch (Exception $e) {
            error_log("Profile getAwardsAndAchievements Error: " . $e->getMessage());
            return [
                'earned_count' => 0,
                'total_count' => 5,
                'list' => []
            ];
        }
    }
    
    // Get notification settings
    private function getNotificationSettings($userId) {
        try {
            $query = "SELECT push_notifications, loan_reminders, group_chat 
                      FROM user_preferences WHERE user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() > 0) {
                return $stmt->fetch(PDO::FETCH_ASSOC);
            }
            
            // Return default settings if no preferences found
            return [
                'push_notifications' => true,
                'loan_reminders' => true,
                'group_chat' => true
            ];
            
        } catch (Exception $e) {
            error_log("Profile getNotificationSettings Error: " . $e->getMessage());
            return [
                'push_notifications' => true,
                'loan_reminders' => true,
                'group_chat' => true
            ];
        }
    }
    
    // Get security settings
    private function getSecuritySettings($userId) {
        try {
            $query = "SELECT biometric_login, pin_enabled FROM user_security WHERE user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() > 0) {
                return $stmt->fetch(PDO::FETCH_ASSOC);
            }
            
            // Return default settings if no security settings found
            return [
                'biometric_login' => false,
                'pin_enabled' => false
            ];
            
        } catch (Exception $e) {
            error_log("Profile getSecuritySettings Error: " . $e->getMessage());
            return [
                'biometric_login' => false,
                'pin_enabled' => false
            ];
        }
    }
    
    // Update profile information
    public function updateProfile($userId, $data) {
        try {
            $allowedFields = ['full_name', 'phone'];
            $updateFields = [];
            $updateValues = [];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field])) {
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
            
            if ($stmt->rowCount() > 0) {
                return ResponseUtil::success('Profile updated successfully');
            } else {
                return ResponseUtil::error('No changes made to profile', 400);
            }
            
        } catch (Exception $e) {
            error_log("Profile updateProfile Error: " . $e->getMessage());
            return ResponseUtil::error('Failed to update profile: ' . $e->getMessage(), 500);
        }
    }
    
    // Update notification settings
    public function updateNotificationSettings($userId, $data) {
        try {
            $allowedFields = ['push_notifications', 'loan_reminders', 'group_chat'];
            $updateFields = [];
            $updateValues = [];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field])) {
                    $updateFields[] = "$field = ?";
                    $updateValues[] = $data[$field] ? 1 : 0;
                }
            }
            
            if (empty($updateFields)) {
                return ResponseUtil::error('No valid notification settings to update', 400);
            }
            
            // Check if user preferences exist
            $query = "SELECT id FROM user_preferences WHERE user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() > 0) {
                // Update existing preferences
                $updateValues[] = $userId;
                $query = "UPDATE user_preferences SET " . implode(', ', $updateFields) . " WHERE user_id = ?";
            } else {
                // Insert new preferences
                $updateValues[] = $userId;
                $query = "INSERT INTO user_preferences (" . implode(', ', $allowedFields) . ", user_id) VALUES (" . 
                        str_repeat('?,', count($allowedFields) - 1) . "?, ?)";
            }
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute($updateValues);
            
            return ResponseUtil::success('Notification settings updated successfully');
            
        } catch (Exception $e) {
            error_log("Profile updateNotificationSettings Error: " . $e->getMessage());
            return ResponseUtil::error('Failed to update notification settings: ' . $e->getMessage(), 500);
        }
    }
    
    // Update security settings
    public function updateSecuritySettings($userId, $data) {
        try {
            $allowedFields = ['biometric_login', 'pin_enabled'];
            $updateFields = [];
            $updateValues = [];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field])) {
                    $updateFields[] = "$field = ?";
                    $updateValues[] = $data[$field] ? 1 : 0;
                }
            }
            
            if (empty($updateFields)) {
                return ResponseUtil::error('No valid security settings to update', 400);
            }
            
            // Check if user security settings exist
            $query = "SELECT id FROM user_security WHERE user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            if ($stmt->rowCount() > 0) {
                // Update existing settings
                $updateValues[] = $userId;
                $query = "UPDATE user_security SET " . implode(', ', $updateFields) . " WHERE user_id = ?";
            } else {
                // Insert new settings
                $updateValues[] = $userId;
                $query = "INSERT INTO user_security (" . implode(', ', $allowedFields) . ", user_id) VALUES (" . 
                        str_repeat('?,', count($allowedFields) - 1) . "?, ?)";
            }
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute($updateValues);
            
            return ResponseUtil::success('Security settings updated successfully');
            
        } catch (Exception $e) {
            error_log("Profile updateSecuritySettings Error: " . $e->getMessage());
            return ResponseUtil::error('Failed to update security settings: ' . $e->getMessage(), 500);
        }
    }
}
?> 