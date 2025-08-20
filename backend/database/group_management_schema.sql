-- Group Management and Blockchain Integration Schema
-- Additional tables for MicroNest application

USE micronest_db;

-- User preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    push_notifications BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT TRUE,
    loan_reminders BOOLEAN DEFAULT TRUE,
    group_chat BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_preferences (user_id)
);

-- User security table
CREATE TABLE IF NOT EXISTS user_security (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    pin_hash VARCHAR(255) NULL,
    pin_enabled BOOLEAN DEFAULT FALSE,
    biometric_login BOOLEAN DEFAULT FALSE,
    two_factor_auth BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_security (user_id)
);

-- Enhanced savings groups table
CREATE TABLE IF NOT EXISTS savings_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    group_type ENUM('daily', 'weekly', 'monthly') NOT NULL,
    contribution_amount DECIMAL(10,2) NOT NULL,
    max_members INT DEFAULT 20,
    current_members INT DEFAULT 0,
    total_funds DECIMAL(15,2) DEFAULT 0.00,
    blockchain_address VARCHAR(42) NULL,
    smart_contract_address VARCHAR(42) NULL,
    status ENUM('active', 'inactive', 'full', 'completed') DEFAULT 'active',
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_status (status),
    INDEX idx_created_by (created_by),
    INDEX idx_blockchain (blockchain_address)
);

-- Enhanced group members table
CREATE TABLE IF NOT EXISTS group_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('admin', 'member', 'moderator') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'inactive', 'left', 'suspended') DEFAULT 'active',
    total_contributed DECIMAL(15,2) DEFAULT 0.00,
    last_contribution_date DATE NULL,
    blockchain_wallet_address VARCHAR(42) NULL,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_group_user (group_id, user_id),
    INDEX idx_group_id (group_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);

-- Enhanced contributions table
CREATE TABLE IF NOT EXISTS group_contributions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    contribution_date DATE NOT NULL,
    payment_method ENUM('cash', 'bank_transfer', 'mobile_money', 'blockchain') DEFAULT 'cash',
    blockchain_transaction_hash VARCHAR(66) NULL,
    status ENUM('pending', 'confirmed', 'rejected', 'blockchain_pending') DEFAULT 'pending',
    confirmed_by INT NULL,
    confirmed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (confirmed_by) REFERENCES users(id),
    INDEX idx_group_id (group_id),
    INDEX idx_user_id (user_id),
    INDEX idx_contribution_date (contribution_date),
    INDEX idx_status (status),
    INDEX idx_blockchain_hash (blockchain_transaction_hash)
);

-- Enhanced loans table
CREATE TABLE IF NOT EXISTS loans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    interest_rate DECIMAL(5,2) DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL,
    loan_purpose TEXT,
    blockchain_loan_id VARCHAR(66) NULL,
    smart_contract_address VARCHAR(42) NULL,
    status ENUM('pending', 'approved', 'rejected', 'active', 'completed', 'defaulted') DEFAULT 'pending',
    approved_by INT NULL,
    approved_at TIMESTAMP NULL,
    disbursed_at TIMESTAMP NULL,
    due_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id),
    INDEX idx_user_id (user_id),
    INDEX idx_group_id (group_id),
    INDEX idx_status (status),
    INDEX idx_due_date (due_date),
    INDEX idx_blockchain_loan (blockchain_loan_id)
);

-- Enhanced loan payments table
CREATE TABLE IF NOT EXISTS loan_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method ENUM('cash', 'bank_transfer', 'mobile_money', 'blockchain') DEFAULT 'cash',
    blockchain_transaction_hash VARCHAR(66) NULL,
    status ENUM('pending', 'confirmed', 'rejected', 'blockchain_pending') DEFAULT 'pending',
    confirmed_by INT NULL,
    confirmed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (confirmed_by) REFERENCES users(id),
    INDEX idx_loan_id (loan_id),
    INDEX idx_user_id (user_id),
    INDEX idx_payment_date (payment_date),
    INDEX idx_status (status),
    INDEX idx_blockchain_hash (blockchain_transaction_hash)
);

-- Fund withdrawal requests table
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT,
    blockchain_transaction_hash VARCHAR(66) NULL,
    status ENUM('pending', 'approved', 'rejected', 'processing', 'completed') DEFAULT 'pending',
    approved_by INT NULL,
    approved_at TIMESTAMP NULL,
    processed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id),
    INDEX idx_user_id (user_id),
    INDEX idx_group_id (group_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Fund deposit requests table
CREATE TABLE IF NOT EXISTS deposit_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'bank_transfer', 'mobile_money', 'blockchain') DEFAULT 'cash',
    blockchain_transaction_hash VARCHAR(66) NULL,
    status ENUM('pending', 'confirmed', 'rejected', 'blockchain_pending') DEFAULT 'pending',
    confirmed_by INT NULL,
    confirmed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (confirmed_by) REFERENCES users(id),
    INDEX idx_user_id (user_id),
    INDEX idx_group_id (group_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Transaction history table
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    group_id INT NULL,
    transaction_type ENUM('contribution', 'withdrawal', 'loan_disbursement', 'loan_payment', 'interest_payment', 'fee_payment') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    balance_before DECIMAL(15,2) NOT NULL,
    balance_after DECIMAL(15,2) NOT NULL,
    description TEXT,
    blockchain_transaction_hash VARCHAR(66) NULL,
    smart_contract_address VARCHAR(42) NULL,
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_group_id (group_id),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_blockchain_hash (blockchain_transaction_hash)
);

-- Blockchain wallet addresses table
CREATE TABLE IF NOT EXISTS blockchain_wallets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    wallet_address VARCHAR(42) NOT NULL,
    wallet_type ENUM('ethereum', 'polygon', 'bsc') DEFAULT 'ethereum',
    is_primary BOOLEAN DEFAULT FALSE,
    balance_wei DECIMAL(65,0) DEFAULT 0,
    balance_eth DECIMAL(20,18) DEFAULT 0,
    last_sync_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_wallet_address (wallet_address),
    INDEX idx_user_id (user_id),
    INDEX idx_wallet_type (wallet_type),
    INDEX idx_is_primary (is_primary)
);

-- Smart contract deployments table
CREATE TABLE IF NOT EXISTS smart_contracts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contract_name VARCHAR(100) NOT NULL,
    contract_address VARCHAR(42) NOT NULL,
    contract_type ENUM('savings_group', 'loan_contract', 'token_contract') NOT NULL,
    network ENUM('ethereum', 'polygon', 'bsc', 'testnet') DEFAULT 'ethereum',
    abi TEXT NOT NULL,
    bytecode TEXT NOT NULL,
    deployed_by INT NOT NULL,
    deployed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'inactive', 'deprecated') DEFAULT 'active',
    FOREIGN KEY (deployed_by) REFERENCES users(id),
    UNIQUE KEY unique_contract_address (contract_address),
    INDEX idx_contract_type (contract_type),
    INDEX idx_network (network),
    INDEX idx_status (status)
);

-- Group chat messages table
CREATE TABLE IF NOT EXISTS group_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    message_type ENUM('text', 'image', 'file', 'system') DEFAULT 'text',
    file_url VARCHAR(500) NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_group_id (group_id),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
);

-- Group notifications table
CREATE TABLE IF NOT EXISTS group_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    notification_type ENUM('contribution', 'withdrawal', 'loan', 'chat', 'system') DEFAULT 'system',
    read_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_group_id (group_id),
    INDEX idx_user_id (user_id),
    INDEX idx_read_status (read_status),
    INDEX idx_created_at (created_at)
);

-- Insert default data for existing users
INSERT IGNORE INTO user_preferences (user_id) 
SELECT id FROM users WHERE id NOT IN (SELECT user_id FROM user_preferences);

INSERT IGNORE INTO user_security (user_id) 
SELECT id FROM users WHERE id NOT IN (SELECT user_id FROM user_security);

-- Create indexes for better performance
CREATE INDEX idx_group_contributions_user_date ON group_contributions(user_id, contribution_date);
CREATE INDEX idx_loans_group_status ON loans(group_id, status);
CREATE INDEX idx_transactions_user_type ON transactions(user_id, transaction_type);
CREATE INDEX idx_blockchain_wallets_user_primary ON blockchain_wallets(user_id, is_primary);
CREATE INDEX idx_smart_contracts_network_status ON smart_contracts(network, status); 