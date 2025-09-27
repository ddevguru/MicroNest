<?php
require_once __DIR__ . '/../config/database.php';

class Group {
    private $conn;

    public function __construct() {
        $database = new Database();
        $this->conn = $database->getConnection();
    }

    public function create($data) {
        $query = "INSERT INTO `groups` (name, description, contribution_amount, max_members, current_members, total_funds, created_by, created_at, status) 
                  VALUES (:name, :description, :contribution_amount, :max_members, 1, :total_funds, :created_by, :created_at, 'active')";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':name', $data['name']);
        $stmt->bindParam(':description', $data['description']);
        $stmt->bindParam(':contribution_amount', $data['contribution_amount']);
        $stmt->bindParam(':max_members', $data['max_members']);
        $stmt->bindParam(':total_funds', $data['total_funds']);
        $stmt->bindParam(':created_by', $data['created_by']);
        $stmt->bindParam(':created_at', $data['created_at']);
        if ($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    public function findById($id) {
        $query = "SELECT g.*, u.full_name as created_by_name 
                  FROM `groups` g 
                  LEFT JOIN users u ON g.created_by = u.id 
                  WHERE g.id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function getUserGroups($userId) {
        $query = "SELECT g.* 
                  FROM `groups` g 
                  INNER JOIN group_members gm ON g.id = gm.group_id 
                  WHERE gm.user_id = :user_id AND g.status = 'active'";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getAvailableGroups($userId) {
        $query = "SELECT g.* 
                  FROM `groups` g 
                  WHERE g.status = 'active' 
                  AND g.current_members < g.max_members 
                  AND g.id NOT IN (
                      SELECT group_id FROM group_members WHERE user_id = :user_id
                  )";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function updateMemberCount($groupId, $increment) {
        $query = "UPDATE `groups` 
                  SET current_members = current_members + :increment 
                  WHERE id = :group_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':increment', $increment, PDO::PARAM_INT);
        $stmt->bindParam(':group_id', $groupId);
        return $stmt->execute();
    }

    public function updateTotalFunds($groupId, $amount) {
        $query = "UPDATE `groups` 
                  SET total_funds = total_funds + :amount 
                  WHERE id = :group_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':amount', $amount);
        $stmt->bindParam(':group_id', $groupId);
        return $stmt->execute();
    }

    public function getConnection() {
        return $this->conn;
    }

    public function update($groupId, $data) {
        $setParts = [];
        $params = [];
        
        foreach ($data as $key => $value) {
            $setParts[] = "`$key` = :$key";
            $params[":$key"] = $value;
        }
        
        $query = "UPDATE `groups` SET " . implode(', ', $setParts) . " WHERE id = :id";
        $params[':id'] = $groupId;
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute($params);
    }
}
?>