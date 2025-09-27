<?php
require_once __DIR__ . '/../../config/config.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../includes/cors.php';
require_once __DIR__ . '/../../includes/response.php';
require_once __DIR__ . '/../../includes/jwt.php';
require_once __DIR__ . '/../../models/User.php';
require_once __DIR__ . '/../../models/Group.php';
require_once __DIR__ . '/../../models/GroupMember.php';
require_once __DIR__ . '/../../models/Wallet.php';

header('Content-Type: application/json');

ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log("Make contribution error: Method not allowed");
    ApiResponse::error('Method not allowed', 405);
}

try {
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        error_log("Make contribution error: No token provided");
        ApiResponse::error('Access token required', 401);
    }

    $token = $matches[1];
    $decoded = JWTHandler::verifyAccessToken($token);
    $userId = $decoded['user_id'];

    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        error_log("Make contribution error: Invalid JSON input");
        ApiResponse::error('Invalid JSON input', 400);
    }

    $groupId = $input['group_id'] ?? null;
    $amount = $input['amount'] ?? null;
    $paymentMethod = $input['payment_method'] ?? null;

    if (!$groupId || !$amount || !$paymentMethod) {
        error_log("Make contribution error: Missing required fields");
        ApiResponse::error('Missing required fields', 400);
    }

    $validPaymentMethods = ['cash', 'bank_transfer', 'mobile_money', 'razorpay'];
    if (!in_array($paymentMethod, $validPaymentMethods)) {
        error_log("Make contribution error: Invalid payment method: $paymentMethod");
        ApiResponse::error('Invalid payment method', 400);
    }

    $group = new Group();
    $groupData = $group->findById($groupId);
    if (!$groupData) {
        error_log("Make contribution error: Group not found");
        ApiResponse::error('Group not found', 404);
    }

    $groupMember = new GroupMember();
    if (!$groupMember->isMember($groupId, $userId)) {
        error_log("Make contribution error: User not a member of group");
        ApiResponse::error('You are not a member of this group', 400);
    }

    // Get or create user wallet
    $wallet = new Wallet();
    $userWallet = $wallet->getOrCreateWallet($userId);
    
    if (!$userWallet) {
        error_log("Make contribution error: Failed to get user wallet");
        ApiResponse::error('Failed to get user wallet', 500);
    }

    // Check if user has sufficient balance (for non-cash payments)
    if ($paymentMethod !== 'cash' && $userWallet['balance'] < $amount) {
        error_log("Make contribution error: Insufficient wallet balance");
        ApiResponse::error('Insufficient wallet balance', 400);
    }

    // Start transaction
    $database = new Database();
    $conn = $database->getConnection();
    $conn->beginTransaction();

    try {
        // Deduct from wallet (for non-cash payments)
        if ($paymentMethod !== 'cash') {
            $wallet->updateBalance($userWallet['id'], $amount, 'debit');
            $wallet->addTransaction(
                $userWallet['id'], 
                $userId, 
                'debit', 
                $amount, 
                "Contribution to group: {$groupData['name']}", 
                'contribution', 
                $groupId
            );
        }

        // Update group member contribution
        $memberData = $groupMember->getGroupMembers($groupId);
        $member = array_filter($memberData, function($m) use ($userId) {
            return $m['user_id'] == $userId;
        });
        
        if (!empty($member)) {
            $memberId = reset($member)['id'];
            $newTotal = reset($member)['total_contributed'] + $amount;
            $groupMember->update($memberId, [
                'total_contributed' => $newTotal,
                'last_contribution_date' => date('Y-m-d H:i:s')
            ]);
        }

        // Update group total funds
        $group->update($groupId, [
            'total_funds' => $groupData['total_funds'] + $amount
        ]);

        // Add contribution record
        $contributionQuery = "INSERT INTO group_contributions (group_id, user_id, amount, payment_method, payment_status) 
                             VALUES (:group_id, :user_id, :amount, :payment_method, 'completed')";
        $stmt = $conn->prepare($contributionQuery);
        $stmt->bindParam(':group_id', $groupId);
        $stmt->bindParam(':user_id', $userId);
        $stmt->bindParam(':amount', $amount);
        $stmt->bindParam(':payment_method', $paymentMethod);
        $stmt->execute();

        $conn->commit();

        error_log("Make contribution success: User $userId contributed $amount to group $groupId");
        ApiResponse::success(['message' => 'Contribution successful'], 'Contribution made successfully');

    } catch (Exception $e) {
        $conn->rollBack();
        throw $e;
    }

} catch (Exception $e) {
    error_log("Make contribution error: " . $e->getMessage());
    ApiResponse::error('Internal server error: ' . $e->getMessage(), 500);
}
?> 