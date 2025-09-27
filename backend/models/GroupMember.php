<?php
require_once __DIR__ . '/../config/database.php';

class GroupMember {
    private $conn;

    public function __construct() {
        $database = new Database();
        $this->conn = $database->getConnection();
    }

    public function addMember($groupId, $userId, $amount, $role = 'member') {
        $query = "INSERT INTO group_members (group_id, user_id, role, total_contributed, joined_at) 
                  VALUES (:group_id, :user_id, :role, :total_contributed, :joined_at)";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':group_id', $groupId);
        $stmt->bindParam(':user_id', $userId);
        $stmt->bindParam(':role', $role);
        $stmt->bindParam(':total_contributed', $amount);
        $joinedAt = date('Y-m-d H:i:s');
        $stmt->bindParam(':joined_at', $joinedAt);
        return $stmt->execute();
    }

    public function create($data) {
        $query = "INSERT INTO group_members (group_id, user_id, role, total_contributed, last_contribution_date, joined_at, status) 
                  VALUES (:group_id, :user_id, :role, :total_contributed, :last_contribution_date, :joined_at, 'active')";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':group_id', $data['group_id']);
        $stmt->bindParam(':user_id', $data['user_id']);
        $stmt->bindParam(':role', $data['role']);
        $stmt->bindParam(':total_contributed', $data['total_contributed']);
        $stmt->bindParam(':last_contribution_date', $data['last_contribution_date']);
        $stmt->bindParam(':joined_at', $data['joined_at']);
        return $stmt->execute();
    }

    public function getGroupMembers($groupId) {
        $query = "SELECT gm.*, u.full_name 
                  FROM group_members gm 
                  LEFT JOIN users u ON gm.user_id = u.id 
                  WHERE gm.group_id = :group_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':group_id', $groupId);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function isMember($groupId, $userId) {
        $query = "SELECT id FROM group_members 
                  WHERE group_id = :group_id AND user_id = :user_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':group_id', $groupId);
        $stmt->bindParam(':user_id', $userId);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC) !== false;
    }

    public function removeMember($groupId, $userId) {
        $query = "DELETE FROM group_members 
                  WHERE group_id = :group_id AND user_id = :user_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':group_id', $groupId);
        $stmt->bindParam(':user_id', $userId);
        return $stmt->execute();
    }
}
?>