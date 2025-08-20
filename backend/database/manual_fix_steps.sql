-- Manual Fix Steps - Run these commands one by one

-- Step 1: First, let's see what tables exist and what references savings_groups
SHOW TABLES;

-- Step 2: Check what foreign keys reference savings_groups
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE REFERENCED_TABLE_NAME = 'savings_groups';

-- Step 3: Based on the results above, drop tables in this order:
-- (Replace 'table_name' with actual table names from Step 2)

-- Example: If you see 'contributions' table references savings_groups:
-- DROP TABLE IF EXISTS contributions;

-- Example: If you see 'group_members' table references savings_groups:
-- DROP TABLE IF EXISTS group_members;

-- Example: If you see 'group_contributions' table references savings_groups:
-- DROP TABLE IF EXISTS group_contributions;

-- Step 4: After dropping ALL child tables, drop the parent:
-- DROP TABLE IF EXISTS savings_groups;

-- Step 5: Now recreate the savings_groups table:
-- CREATE TABLE savings_groups (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     name VARCHAR(255) NOT NULL,
--     description TEXT,
--     target_amount DECIMAL(10,2) NOT NULL,
--     current_amount DECIMAL(10,2) DEFAULT 0.00,
--     member_limit INT DEFAULT 10,
--     status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
--     created_by INT NOT NULL,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--     end_date DATE,
--     FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
-- );

-- Step 6: Test with one insert:
-- INSERT INTO savings_groups (name, description, target_amount, current_amount, member_limit, created_by, end_date) VALUES
-- ('Local Merchants', 'Savings group for local business owners', 50000.00, 37500.00, 8, 1, DATE_ADD(CURDATE(), INTERVAL 5 DAY));

-- Step 7: Verify the table structure:
-- DESCRIBE savings_groups; 