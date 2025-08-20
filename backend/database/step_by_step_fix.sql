-- Step by Step Fix for Table Structure Issue
-- Run these commands one by one in your MySQL database

-- Step 1: Check what columns exist in savings_groups table
DESCRIBE savings_groups;

-- Step 2: If the table is missing columns, drop it completely
DROP TABLE IF EXISTS savings_groups;

-- Step 3: Create the savings_groups table with ALL required columns
CREATE TABLE savings_groups (
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
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- Step 4: Verify the table structure
DESCRIBE savings_groups;

-- Step 5: Now insert the sample data
INSERT INTO savings_groups (name, description, target_amount, current_amount, member_limit, created_by, end_date) VALUES
('Local Merchants', 'Savings group for local business owners', 50000.00, 37500.00, 8, 1, DATE_ADD(CURDATE(), INTERVAL 5 DAY));

-- Step 6: Check if data was inserted
SELECT * FROM savings_groups; 