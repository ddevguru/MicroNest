// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SavingsGroup
 * @dev Smart contract for managing savings groups on Ethereum blockchain
 */
contract SavingsGroup is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    
    // Structs
    struct Member {
        address walletAddress;
        uint256 totalContributed;
        uint256 lastContributionDate;
        bool isActive;
        uint256 trustScore;
        uint256 joinedAt;
    }
    
    struct Contribution {
        uint256 id;
        address member;
        uint256 amount;
        uint256 timestamp;
        bool isConfirmed;
        string paymentMethod;
    }
    
    struct WithdrawalRequest {
        uint256 id;
        address member;
        uint256 amount;
        string reason;
        uint256 timestamp;
        bool isApproved;
        bool isProcessed;
    }
    
    struct LoanRequest {
        uint256 id;
        address member;
        uint256 amount;
        uint256 interestRate;
        uint256 totalAmount;
        string purpose;
        uint256 dueDate;
        bool isApproved;
        bool isDisbursed;
        bool isRepaid;
    }
    
    // State variables
    Counters.Counter private _contributionIds;
    Counters.Counter private _withdrawalIds;
    Counters.Counter private _loanIds;
    
    string public groupName;
    string public groupDescription;
    uint256 public contributionAmount;
    uint256 public maxMembers;
    uint256 public currentMembers;
    uint256 public totalFunds;
    uint256 public interestRate;
    uint256 public createdAt;
    
    mapping(address => Member) public members;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;
    mapping(uint256 => LoanRequest) public loanRequests;
    
    address[] public memberAddresses;
    
    // Events
    event MemberJoined(address indexed member, uint256 timestamp);
    event MemberLeft(address indexed member, uint256 timestamp);
    event ContributionMade(address indexed member, uint256 amount, uint256 contributionId);
    event ContributionConfirmed(uint256 indexed contributionId, address indexed admin);
    event WithdrawalRequested(address indexed member, uint256 amount, uint256 requestId);
    event WithdrawalApproved(uint256 indexed requestId, address indexed admin);
    event WithdrawalProcessed(uint256 indexed requestId, address indexed member);
    event LoanRequested(address indexed member, uint256 amount, uint256 requestId);
    event LoanApproved(uint256 indexed requestId, address indexed admin);
    event LoanDisbursed(uint256 indexed requestId, address indexed member);
    event LoanRepaid(uint256 indexed requestId, address indexed member);
    
    // Modifiers
    modifier onlyMember() {
        require(members[msg.sender].isActive, "Not a member of this group");
        _;
    }
    
    modifier onlyAdmin() {
        require(members[msg.sender].isActive && members[msg.sender].trustScore >= 100, "Not an admin");
        _;
    }
    
    modifier groupNotFull() {
        require(currentMembers < maxMembers, "Group is full");
        _;
    }
    
    modifier sufficientFunds(uint256 amount) {
        require(totalFunds >= amount, "Insufficient group funds");
        _;
    }
    
    // Constructor
    constructor(
        string memory _name,
        string memory _description,
        uint256 _contributionAmount,
        uint256 _maxMembers,
        uint256 _interestRate
    ) {
        groupName = _name;
        groupDescription = _description;
        contributionAmount = _contributionAmount;
        maxMembers = _maxMembers;
        interestRate = _interestRate;
        createdAt = block.timestamp;
        
        // Add creator as first member and admin
        _addMember(msg.sender, 100); // 100 trust score for admin
    }
    
    // Core functions
    
    /**
     * @dev Join the savings group
     */
    function joinGroup() external payable groupNotFull {
        require(msg.value == contributionAmount, "Incorrect contribution amount");
        require(!members[msg.sender].isActive, "Already a member");
        
        _addMember(msg.sender, 50); // 50 trust score for new members
        
        // Record first contribution
        _recordContribution(msg.sender, msg.value, "blockchain");
        
        emit MemberJoined(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Leave the savings group
     */
    function leaveGroup() external onlyMember nonReentrant {
        Member storage member = members[msg.sender];
        require(member.totalContributed > 0, "No contributions to withdraw");
        
        uint256 withdrawalAmount = member.totalContributed;
        
        // Remove member
        member.isActive = false;
        currentMembers--;
        
        // Update group funds
        totalFunds -= withdrawalAmount;
        
        // Transfer funds back to member
        (bool success, ) = msg.sender.call{value: withdrawalAmount}("");
        require(success, "Transfer failed");
        
        emit MemberLeft(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Make a contribution to the group
     */
    function makeContribution() external payable onlyMember {
        require(msg.value > 0, "Contribution amount must be greater than 0");
        
        _recordContribution(msg.sender, msg.value, "blockchain");
        
        emit ContributionMade(msg.sender, msg.value, _contributionIds.current() - 1);
    }
    
    /**
     * @dev Confirm a contribution (admin only)
     */
    function confirmContribution(uint256 contributionId) external onlyAdmin {
        Contribution storage contribution = contributions[contributionId];
        require(contribution.id == contributionId, "Contribution not found");
        require(!contribution.isConfirmed, "Contribution already confirmed");
        
        contribution.isConfirmed = true;
        
        // Update member's total contribution
        members[contribution.member].totalContributed += contribution.amount;
        members[contribution.member].lastContributionDate = block.timestamp;
        
        // Update group funds
        totalFunds += contribution.amount;
        
        // Increase trust score for on-time contribution
        _increaseTrustScore(contribution.member, 5);
        
        emit ContributionConfirmed(contributionId, msg.sender);
    }
    
    /**
     * @dev Request withdrawal from group funds
     */
    function requestWithdrawal(uint256 amount, string memory reason) external onlyMember {
        Member storage member = members[msg.sender];
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(amount <= member.totalContributed, "Insufficient balance for withdrawal");
        
        _withdrawalIds.increment();
        uint256 requestId = _withdrawalIds.current();
        
        withdrawalRequests[requestId] = WithdrawalRequest({
            id: requestId,
            member: msg.sender,
            amount: amount,
            reason: reason,
            timestamp: block.timestamp,
            isApproved: false,
            isProcessed: false
        });
        
        emit WithdrawalRequested(msg.sender, amount, requestId);
    }
    
    /**
     * @dev Approve withdrawal request (admin only)
     */
    function approveWithdrawal(uint256 requestId) external onlyAdmin {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        require(request.id == requestId, "Withdrawal request not found");
        require(!request.isApproved, "Request already approved");
        
        request.isApproved = true;
        
        emit WithdrawalApproved(requestId, msg.sender);
    }
    
    /**
     * @dev Process approved withdrawal
     */
    function processWithdrawal(uint256 requestId) external onlyAdmin nonReentrant {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        require(request.id == requestId, "Withdrawal request not found");
        require(request.isApproved, "Request not approved");
        require(!request.isProcessed, "Request already processed");
        require(sufficientFunds(request.amount), "Insufficient group funds");
        
        request.isProcessed = true;
        
        // Update member's contribution
        members[request.member].totalContributed -= request.amount;
        
        // Update group funds
        totalFunds -= request.amount;
        
        // Transfer funds to member
        (bool success, ) = request.member.call{value: request.amount}("");
        require(success, "Transfer failed");
        
        emit WithdrawalProcessed(requestId, request.member);
    }
    
    /**
     * @dev Request a loan from the group
     */
    function requestLoan(uint256 amount, string memory purpose, uint256 dueDate) external onlyMember {
        require(amount > 0, "Loan amount must be greater than 0");
        require(dueDate > block.timestamp, "Due date must be in the future");
        require(amount <= totalFunds * 2 / 3, "Loan amount exceeds group limit");
        
        _loanIds.increment();
        uint256 requestId = _loanIds.current();
        
        uint256 totalAmount = amount + (amount * interestRate / 100);
        
        loanRequests[requestId] = LoanRequest({
            id: requestId,
            member: msg.sender,
            amount: amount,
            interestRate: interestRate,
            totalAmount: totalAmount,
            purpose: purpose,
            dueDate: dueDate,
            isApproved: false,
            isDisbursed: false,
            isRepaid: false
        });
        
        emit LoanRequested(msg.sender, amount, requestId);
    }
    
    /**
     * @dev Approve loan request (admin only)
     */
    function approveLoan(uint256 requestId) external onlyAdmin {
        LoanRequest storage request = loanRequests[requestId];
        require(request.id == requestId, "Loan request not found");
        require(!request.isApproved, "Request already approved");
        
        request.isApproved = true;
        
        emit LoanApproved(requestId, msg.sender);
    }
    
    /**
     * @dev Disburse approved loan
     */
    function disburseLoan(uint256 requestId) external onlyAdmin nonReentrant {
        LoanRequest storage request = loanRequests[requestId];
        require(request.id == requestId, "Loan request not found");
        require(request.isApproved, "Request not approved");
        require(!request.isDisbursed, "Loan already disbursed");
        require(sufficientFunds(request.amount), "Insufficient group funds");
        
        request.isDisbursed = true;
        
        // Update group funds
        totalFunds -= request.amount;
        
        // Transfer funds to borrower
        (bool success, ) = request.member.call{value: request.amount}("");
        require(success, "Transfer failed");
        
        emit LoanDisbursed(requestId, request.member);
    }
    
    /**
     * @dev Repay loan
     */
    function repayLoan(uint256 requestId) external payable nonReentrant {
        LoanRequest storage request = loanRequests[requestId];
        require(request.id == requestId, "Loan request not found");
        require(request.isDisbursed, "Loan not disbursed");
        require(!request.isRepaid, "Loan already repaid");
        require(msg.value == request.totalAmount, "Incorrect repayment amount");
        
        request.isRepaid = true;
        
        // Update group funds
        totalFunds += msg.value;
        
        // Increase trust score for loan repayment
        _increaseTrustScore(request.member, 10);
        
        emit LoanRepaid(requestId, request.member);
    }
    
    // View functions
    
    /**
     * @dev Get member information
     */
    function getMember(address memberAddress) external view returns (Member memory) {
        return members[memberAddress];
    }
    
    /**
     * @dev Get all member addresses
     */
    function getAllMembers() external view returns (address[] memory) {
        return memberAddresses;
    }
    
    /**
     * @dev Get contribution information
     */
    function getContribution(uint256 contributionId) external view returns (Contribution memory) {
        return contributions[contributionId];
    }
    
    /**
     * @dev Get withdrawal request information
     */
    function getWithdrawalRequest(uint256 requestId) external view returns (WithdrawalRequest memory) {
        return withdrawalRequests[requestId];
    }
    
    /**
     * @dev Get loan request information
     */
    function getLoanRequest(uint256 requestId) external view returns (LoanRequest memory) {
        return loanRequests[requestId];
    }
    
    /**
     * @dev Get group statistics
     */
    function getGroupStats() external view returns (
        uint256 _totalFunds,
        uint256 _currentMembers,
        uint256 _maxMembers,
        uint256 _contributionAmount,
        uint256 _interestRate,
        uint256 _createdAt
    ) {
        return (totalFunds, currentMembers, maxMembers, contributionAmount, interestRate, createdAt);
    }
    
    // Internal functions
    
    /**
     * @dev Add a new member to the group
     */
    function _addMember(address memberAddress, uint256 initialTrustScore) private {
        members[memberAddress] = Member({
            walletAddress: memberAddress,
            totalContributed: 0,
            lastContributionDate: 0,
            isActive: true,
            trustScore: initialTrustScore,
            joinedAt: block.timestamp
        });
        
        memberAddresses.push(memberAddress);
        currentMembers++;
    }
    
    /**
     * @dev Record a contribution
     */
    function _recordContribution(address member, uint256 amount, string memory paymentMethod) private {
        _contributionIds.increment();
        uint256 contributionId = _contributionIds.current();
        
        contributions[contributionId] = Contribution({
            id: contributionId,
            member: member,
            amount: amount,
            timestamp: block.timestamp,
            isConfirmed: false,
            paymentMethod: paymentMethod
        });
    }
    
    /**
     * @dev Increase member's trust score
     */
    function _increaseTrustScore(address member, uint256 points) private {
        members[member].trustScore += points;
        if (members[member].trustScore > 100) {
            members[member].trustScore = 100;
        }
    }
    
    /**
     * @dev Check if group has sufficient funds
     */
    function sufficientFunds(uint256 amount) private view returns (bool) {
        return totalFunds >= amount;
    }
    
    // Emergency functions (owner only)
    
    /**
     * @dev Emergency pause (owner only)
     */
    function emergencyPause() external onlyOwner {
        // Implementation for emergency pause
    }
    
    /**
     * @dev Emergency withdraw (owner only)
     */
    function emergencyWithdraw() external onlyOwner {
        // Implementation for emergency withdrawal
    }
    
    // Fallback and receive functions
    
    receive() external payable {
        // Accept ETH transfers
    }
    
    fallback() external payable {
        // Fallback function
    }
} 