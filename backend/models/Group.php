<?php
require_once '../config/database.php';

class Group {
    private $conn;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    // Create a new savings group
    public function createGroup($data) {
        try {
            $this->conn->beginTransaction();
            
            // Validate required fields
            if (empty($data['name']) || empty($data['group_type']) || empty($data['contribution_amount'])) {
                return ['success' => false, 'message' => 'Name, group type, and contribution amount are required'];
            }
            
            // Create group
            $query = "INSERT INTO savings_groups (name, description, group_type, contribution_amount, max_members, created_by) 
                      VALUES (?, ?, ?, ?, ?, ?)";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $data['name'],
                $data['description'] ?? '',
                $data['group_type'],
                $data['contribution_amount'],
                $data['max_members'] ?? 20,
                $data['created_by']
            ]);
            
            $groupId = $this->conn->lastInsertId();
            
            // Add creator as admin member
            $query = "INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'admin')";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId, $data['created_by']]);
            
            // Update current members count
            $query = "UPDATE savings_groups SET current_members = 1 WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId]);
            
            $this->conn->commit();
            
            return [
                'success' => true,
                'message' => 'Group created successfully',
                'group_id' => $groupId
            ];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group createGroup Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to create group: ' . $e->getMessage()];
        }
    }
    
    // Join a group
    public function joinGroup($data) {
        try {
            $this->conn->beginTransaction();
            
            // Check if group exists and has space
            $query = "SELECT * FROM savings_groups WHERE id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id']]);
            $group = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$group) {
                return ['success' => false, 'message' => 'Group not found or inactive'];
            }
            
            if ($group['current_members'] >= $group['max_members']) {
                return ['success' => false, 'message' => 'Group is full'];
            }
            
            // Check if user is already a member
            $query = "SELECT * FROM group_members WHERE group_id = ? AND user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            
            if ($stmt->rowCount() > 0) {
                return ['success' => false, 'message' => 'Already a member of this group'];
            }
            
            // Add user to group
            $query = "INSERT INTO group_members (group_id, user_id) VALUES (?, ?)";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            
            // Update member count
            $query = "UPDATE savings_groups SET current_members = current_members + 1 WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id']]);
            
            $this->conn->commit();
            
            return ['success' => true, 'message' => 'Successfully joined group'];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group joinGroup Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to join group: ' . $e->getMessage()];
        }
    }
    
    // Leave a group
    public function leaveGroup($data) {
        try {
            $this->conn->beginTransaction();
            
            // Check if user is a member
            $query = "SELECT * FROM group_members WHERE group_id = ? AND user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'message' => 'Not a member of this group'];
            }
            
            // Update member status to left
            $query = "UPDATE group_members SET status = 'left' WHERE group_id = ? AND user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            
            // Update member count
            $query = "UPDATE savings_groups SET current_members = current_members - 1 WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id']]);
            
            $this->conn->commit();
            
            return ['success' => true, 'message' => 'Successfully left group'];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group leaveGroup Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to leave group: ' . $e->getMessage()];
        }
    }
    
    // Get user's groups
    public function getUserGroups($userId) {
        try {
            $query = "SELECT sg.*, gm.role, gm.total_contributed, gm.last_contribution_date
                      FROM savings_groups sg
                      JOIN group_members gm ON sg.id = gm.group_id
                      WHERE gm.user_id = ? AND gm.status = 'active'
                      ORDER BY sg.created_at DESC";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            $groups = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'groups' => $groups
            ];
            
        } catch (Exception $e) {
            error_log("Group getUserGroups Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to fetch groups: ' . $e->getMessage()];
        }
    }
    
    // Get available groups to join
    public function getAvailableGroups() {
        try {
            $query = "SELECT sg.*, u.full_name as creator_name
                      FROM savings_groups sg
                      JOIN users u ON sg.created_by = u.id
                      WHERE sg.status = 'active' AND sg.current_members < sg.max_members
                      ORDER BY sg.created_at DESC";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute();
            
            $groups = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'groups' => $groups
            ];
            
        } catch (Exception $e) {
            error_log("Group getAvailableGroups Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to fetch available groups: ' . $e->getMessage()];
        }
    }
    
    // Get group details
    public function getGroupDetails($groupId, $userId) {
        try {
            // Get group info
            $query = "SELECT sg.*, u.full_name as creator_name
                      FROM savings_groups sg
                      JOIN users u ON sg.created_by = u.id
                      WHERE sg.id = ?";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId]);
            $group = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$group) {
                return ['success' => false, 'message' => 'Group not found'];
            }
            
            // Get user's role in group
            $query = "SELECT role, total_contributed, last_contribution_date
                      FROM group_members
                      WHERE group_id = ? AND user_id = ? AND status = 'active'";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId, $userId]);
            $membership = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Get recent contributions
            $query = "SELECT gc.*, u.full_name, u.profile_image
                      FROM group_contributions gc
                      JOIN users u ON gc.user_id = u.id
                      WHERE gc.group_id = ? AND gc.status = 'confirmed'
                      ORDER BY gc.contribution_date DESC
                      LIMIT 10";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId]);
            $recentContributions = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'group' => $group,
                'membership' => $membership,
                'recent_contributions' => $recentContributions
            ];
            
        } catch (Exception $e) {
            error_log("Group getGroupDetails Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to fetch group details: ' . $e->getMessage()];
        }
    }
    
    // Get group members
    public function getGroupMembers($groupId) {
        try {
            $query = "SELECT gm.*, u.full_name, u.profile_image, u.trust_score
                      FROM group_members gm
                      JOIN users u ON gm.user_id = u.id
                      WHERE gm.group_id = ? AND gm.status = 'active'
                      ORDER BY gm.role DESC, gm.joined_at ASC";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId]);
            
            $members = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'members' => $members
            ];
            
        } catch (Exception $e) {
            error_log("Group getGroupMembers Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to fetch group members: ' . $e->getMessage()];
        }
    }
    
    // Make a contribution
    public function makeContribution($data) {
        try {
            $this->conn->beginTransaction();
            
            // Validate required fields
            if (empty($data['group_id']) || empty($data['amount']) || empty($data['contribution_date'])) {
                return ['success' => false, 'message' => 'Group ID, amount, and date are required'];
            }
            
            // Check if user is a member
            $query = "SELECT * FROM group_members WHERE group_id = ? AND user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'message' => 'Not a member of this group'];
            }
            
            // Create contribution record
            $query = "INSERT INTO group_contributions (group_id, user_id, amount, contribution_date, payment_method, status) 
                      VALUES (?, ?, ?, ?, ?, ?)";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $data['group_id'],
                $data['user_id'],
                $data['amount'],
                $data['contribution_date'],
                $data['payment_method'] ?? 'cash',
                'pending'
            ]);
            
            $contributionId = $this->conn->lastInsertId();
            
            // If blockchain payment, update status
            if (($data['payment_method'] ?? 'cash') === 'blockchain' && !empty($data['blockchain_transaction_hash'])) {
                $query = "UPDATE group_contributions SET 
                          blockchain_transaction_hash = ?, 
                          status = 'blockchain_pending' 
                          WHERE id = ?";
                $stmt = $this->conn->prepare($query);
                $stmt->execute([$data['blockchain_transaction_hash'], $contributionId]);
            }
            
            $this->conn->commit();
            
            return [
                'success' => true,
                'message' => 'Contribution recorded successfully',
                'contribution_id' => $contributionId
            ];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group makeContribution Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to record contribution: ' . $e->getMessage()];
        }
    }
    
    // Request withdrawal
    public function requestWithdrawal($data) {
        try {
            $this->conn->beginTransaction();
            
            // Validate required fields
            if (empty($data['group_id']) || empty($data['amount']) || empty($data['reason'])) {
                return ['success' => false, 'message' => 'Group ID, amount, and reason are required'];
            }
            
            // Check if user is a member
            $query = "SELECT * FROM group_members WHERE group_id = ? AND user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'message' => 'Not a member of this group'];
            }
            
            // Check if user has sufficient balance
            $query = "SELECT total_contributed FROM group_members WHERE group_id = ? AND user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            $member = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($member['total_contributed'] < $data['amount']) {
                return ['success' => false, 'message' => 'Insufficient balance for withdrawal'];
            }
            
            // Create withdrawal request
            $query = "INSERT INTO withdrawal_requests (user_id, group_id, amount, reason, status) 
                      VALUES (?, ?, ?, ?, 'pending')";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $data['user_id'],
                $data['group_id'],
                $data['amount'],
                $data['reason']
            ]);
            
            $this->conn->commit();
            
            return ['success' => true, 'message' => 'Withdrawal request submitted successfully'];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group requestWithdrawal Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to submit withdrawal request: ' . $e->getMessage()];
        }
    }
    
    // Request deposit
    public function requestDeposit($data) {
        try {
            $this->conn->beginTransaction();
            
            // Validate required fields
            if (empty($data['group_id']) || empty($data['amount'])) {
                return ['success' => false, 'message' => 'Group ID and amount are required'];
            }
            
            // Check if user is a member
            $query = "SELECT * FROM group_members WHERE group_id = ? AND user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'message' => 'Not a member of this group'];
            }
            
            // Create deposit request
            $query = "INSERT INTO deposit_requests (user_id, group_id, amount, payment_method, status) 
                      VALUES (?, ?, ?, ?, 'pending')";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $data['user_id'],
                $data['group_id'],
                $data['amount'],
                $data['payment_method'] ?? 'cash'
            ]);
            
            $this->conn->commit();
            
            return ['success' => true, 'message' => 'Deposit request submitted successfully'];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group requestDeposit Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to submit deposit request: ' . $e->getMessage()];
        }
    }
    
    // Request loan
    public function requestLoan($data) {
        try {
            $this->conn->beginTransaction();
            
            // Validate required fields
            if (empty($data['group_id']) || empty($data['amount']) || empty($data['loan_purpose']) || empty($data['due_date'])) {
                return ['success' => false, 'message' => 'Group ID, amount, purpose, and due date are required'];
            }
            
            // Check if user is a member
            $query = "SELECT * FROM group_members WHERE group_id = ? AND user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'message' => 'Not a member of this group'];
            }
            
            // Calculate interest and total amount
            $interestRate = 5.0; // Default 5% interest
            $totalAmount = $data['amount'] * (1 + ($interestRate / 100));
            
            // Create loan request
            $query = "INSERT INTO loans (user_id, group_id, amount, interest_rate, total_amount, loan_purpose, due_date, status) 
                      VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $data['user_id'],
                $data['group_id'],
                $data['amount'],
                $interestRate,
                $totalAmount,
                $data['loan_purpose'],
                $data['due_date']
            ]);
            
            $this->conn->commit();
            
            return ['success' => true, 'message' => 'Loan request submitted successfully'];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group requestLoan Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to submit loan request: ' . $e->getMessage()];
        }
    }
    
    // Get group loans
    public function getGroupLoans($groupId) {
        try {
            $query = "SELECT l.*, u.full_name, u.profile_image
                      FROM loans l
                      JOIN users u ON l.user_id = u.id
                      WHERE l.group_id = ?
                      ORDER BY l.created_at DESC";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId]);
            
            $loans = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'loans' => $loans
            ];
            
        } catch (Exception $e) {
            error_log("Group getGroupLoans Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to fetch loans: ' . $e->getMessage()];
        }
    }
    
    // Get user loans
    public function getUserLoans($userId) {
        try {
            $query = "SELECT l.*, sg.name as group_name
                      FROM loans l
                      JOIN savings_groups sg ON l.group_id = sg.id
                      WHERE l.user_id = ?
                      ORDER BY l.created_at DESC";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            $loans = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'loans' => $loans
            ];
            
        } catch (Exception $e) {
            error_log("Group getUserLoans Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to fetch loans: ' . $e->getMessage()];
        }
    }
    
    // Get group transactions
    public function getGroupTransactions($groupId) {
        try {
            $query = "SELECT t.*, u.full_name
                      FROM transactions t
                      JOIN users u ON t.user_id = u.id
                      WHERE t.group_id = ?
                      ORDER BY t.created_at DESC
                      LIMIT 50";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId]);
            
            $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'transactions' => $transactions
            ];
            
        } catch (Exception $e) {
            error_log("Group getGroupTransactions Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to fetch transactions: ' . $e->getMessage()];
        }
    }
    
    // Get user transactions
    public function getUserTransactions($userId) {
        try {
            $query = "SELECT t.*, sg.name as group_name
                      FROM transactions t
                      LEFT JOIN savings_groups sg ON t.group_id = sg.id
                      WHERE t.user_id = ?
                      ORDER BY t.created_at DESC
                      LIMIT 50";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$userId]);
            
            $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'transactions' => $transactions
            ];
            
        } catch (Exception $e) {
            error_log("Group getUserTransactions Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to fetch transactions: ' . $e->getMessage()];
        }
    }
    
    // Get group chat
    public function getGroupChat($groupId) {
        try {
            $query = "SELECT gm.*, u.full_name, u.profile_image
                      FROM group_messages gm
                      JOIN users u ON gm.user_id = u.id
                      WHERE gm.group_id = ?
                      ORDER BY gm.created_at DESC
                      LIMIT 100";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$groupId]);
            
            $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return [
                'success' => true,
                'messages' => array_reverse($messages) // Show oldest first
            ];
            
        } catch (Exception $e) {
            error_log("Group getGroupChat Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to fetch chat messages: ' . $e->getMessage()];
        }
    }
    
    // Send message to group chat
    public function sendMessage($data) {
        try {
            // Validate required fields
            if (empty($data['group_id']) || empty($data['message'])) {
                return ['success' => false, 'message' => 'Group ID and message are required'];
            }
            
            // Check if user is a member
            $query = "SELECT * FROM group_members WHERE group_id = ? AND user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['user_id']]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'message' => 'Not a member of this group'];
            }
            
            // Insert message
            $query = "INSERT INTO group_messages (group_id, user_id, message, message_type) 
                      VALUES (?, ?, ?, ?)";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $data['group_id'],
                $data['user_id'],
                $data['message'],
                $data['message_type'] ?? 'text'
            ]);
            
            return ['success' => true, 'message' => 'Message sent successfully'];
            
        } catch (Exception $e) {
            error_log("Group sendMessage Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to send message: ' . $e->getMessage()];
        }
    }
    
    // Approve contribution
    public function approveContribution($data) {
        try {
            $this->conn->beginTransaction();
            
            // Check if user is admin
            $query = "SELECT role FROM group_members WHERE group_id = ? AND user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['admin_id']]);
            $member = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$member || $member['role'] !== 'admin') {
                return ['success' => false, 'message' => 'Only admins can approve contributions'];
            }
            
            // Update contribution status
            $query = "UPDATE group_contributions SET status = 'confirmed', confirmed_by = ?, confirmed_at = NOW() 
                      WHERE id = ? AND group_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['admin_id'], $data['contribution_id'], $data['group_id']]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'message' => 'Contribution not found'];
            }
            
            // Get contribution details
            $query = "SELECT * FROM group_contributions WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['contribution_id']]);
            $contribution = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Update member's total contribution
            $query = "UPDATE group_members SET 
                      total_contributed = total_contributed + ?, 
                      last_contribution_date = ? 
                      WHERE group_id = ? AND user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $contribution['amount'],
                $contribution['contribution_date'],
                $data['group_id'],
                $contribution['user_id']
            ]);
            
            // Update group total funds
            $query = "UPDATE savings_groups SET total_funds = total_funds + ? WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$contribution['amount'], $data['group_id']]);
            
            // Record transaction
            $query = "INSERT INTO transactions (user_id, group_id, transaction_type, amount, balance_before, balance_after, description, status) 
                      VALUES (?, ?, 'contribution', ?, 0, ?, 'Group contribution', 'completed')";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $contribution['user_id'],
                $data['group_id'],
                $contribution['amount'],
                $contribution['amount']
            ]);
            
            $this->conn->commit();
            
            return ['success' => true, 'message' => 'Contribution approved successfully'];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group approveContribution Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to approve contribution: ' . $e->getMessage()];
        }
    }
    
    // Approve withdrawal
    public function approveWithdrawal($data) {
        try {
            $this->conn->beginTransaction();
            
            // Check if user is admin
            $query = "SELECT role FROM group_members WHERE group_id = ? AND user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['admin_id']]);
            $member = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$member || $member['role'] !== 'admin') {
                return ['success' => false, 'message' => 'Only admins can approve withdrawals'];
            }
            
            // Update withdrawal status
            $query = "UPDATE withdrawal_requests SET status = 'approved', approved_by = ?, approved_at = NOW() 
                      WHERE id = ? AND group_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['admin_id'], $data['withdrawal_id'], $data['group_id']]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'message' => 'Withdrawal request not found'];
            }
            
            // Get withdrawal details
            $query = "SELECT * FROM withdrawal_requests WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['withdrawal_id']]);
            $withdrawal = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Update member's total contribution
            $query = "UPDATE group_members SET 
                      total_contributed = total_contributed - ? 
                      WHERE group_id = ? AND user_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $withdrawal['amount'],
                $data['group_id'],
                $withdrawal['user_id']
            ]);
            
            // Update group total funds
            $query = "UPDATE savings_groups SET total_funds = total_funds - ? WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$withdrawal['amount'], $data['group_id']]);
            
            // Record transaction
            $query = "INSERT INTO transactions (user_id, group_id, transaction_type, amount, balance_before, balance_after, description, status) 
                      VALUES (?, ?, 'withdrawal', ?, ?, ?, 'Group withdrawal', 'completed')";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([
                $withdrawal['user_id'],
                $data['group_id'],
                $withdrawal['amount'],
                $withdrawal['amount'],
                0
            ]);
            
            $this->conn->commit();
            
            return ['success' => true, 'message' => 'Withdrawal approved successfully'];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group approveWithdrawal Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to approve withdrawal: ' . $e->getMessage()];
        }
    }
    
    // Approve loan
    public function approveLoan($data) {
        try {
            $this->conn->beginTransaction();
            
            // Check if user is admin
            $query = "SELECT role FROM group_members WHERE group_id = ? AND user_id = ? AND status = 'active'";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['group_id'], $data['admin_id']]);
            $member = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$member || $member['role'] !== 'admin') {
                return ['success' => false, 'message' => 'Only admins can approve loans'];
            }
            
            // Update loan status
            $query = "UPDATE loans SET status = 'approved', approved_by = ?, approved_at = NOW() 
                      WHERE id = ? AND group_id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$data['admin_id'], $data['loan_id'], $data['group_id']]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'message' => 'Loan request not found'];
            }
            
            $this->conn->commit();
            
            return ['success' => true, 'message' => 'Loan approved successfully'];
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Group approveLoan Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to approve loan: ' . $e->getMessage()];
        }
    }
}
?> 