-- Create Wallet and Groups Tables
-- Run this script in your MySQL database

-- 1. Create wallet_transactions table
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('credit', 'debit') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
);

-- 2. Create savings_groups table (avoiding MySQL reserved keyword 'groups')
CREATE TABLE IF NOT EXISTS savings_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    target_amount DECIMAL(10,2) NOT NULL,
    current_amount DECIMAL(10,2) DEFAULT 0.00,
    member_limit INT DEFAULT 10,
    status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    end_date DATE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_created_by (created_by),
    INDEX idx_status (status)
);

-- 3. Create group_members table
CREATE TABLE IF NOT EXISTS group_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('member', 'admin', 'creator') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_group_user (group_id, user_id),
    INDEX idx_group_id (group_id),
    INDEX idx_user_id (user_id)
);

-- 4. Create group_contributions table
CREATE TABLE IF NOT EXISTS group_contributions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES savings_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_group_id (group_id),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
);

-- 5. Insert sample data
INSERT INTO savings_groups (name, description, target_amount, current_amount, member_limit, created_by, end_date) VALUES
('Local Merchants', 'Savings group for local business owners', 50000.00, 37500.00, 8, 1, DATE_ADD(CURDATE(), INTERVAL 5 DAY)),
('Tech Professionals', 'Monthly savings for tech workers', 100000.00, 25000.00, 12, 1, DATE_ADD(CURDATE(), INTERVAL 30 DAY)),
('Student Savings', 'Educational fund for students', 25000.00, 15000.00, 15, 1, DATE_ADD(CURDATE(), INTERVAL 15 DAY));

-- 6. Insert sample group members
INSERT INTO group_members (group_id, user_id, role) VALUES
(1, 1, 'creator'),
(2, 1, 'creator'),
(3, 1, 'creator');

-- 7. Insert sample wallet transactions
INSERT INTO wallet_transactions (user_id, type, amount, description) VALUES
(1, 'credit', 5000.00, 'Initial deposit'),
(1, 'credit', 2500.00, 'Monthly contribution'),
(1, 'credit', 1000.00, 'Bonus payment'),
(1, 'debit', 500.00, 'Group contribution'),
(1, 'debit', 200.00, 'Service fee');

-- 8. Insert sample group contributions
INSERT INTO group_contributions (group_id, user_id, amount, description) VALUES
(1, 1, 5000.00, 'Monthly contribution'),
(1, 1, 2500.00, 'Extra contribution'),
(2, 1, 10000.00, 'Initial contribution'),
(3, 1, 5000.00, 'Monthly contribution');

-- Success message
SELECT 'Tables created successfully!' as status; 