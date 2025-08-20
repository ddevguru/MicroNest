-- Fix Users Table - Add Missing Columns
-- This script safely adds missing columns to the users table

-- Check and add kyc_status column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'users' 
     AND COLUMN_NAME = 'kyc_status') = 0,
    'ALTER TABLE users ADD COLUMN kyc_status ENUM(\'pending\', \'verified\', \'rejected\') DEFAULT \'pending\'',
    'SELECT \'kyc_status column already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and add trust_score column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'users' 
     AND COLUMN_NAME = 'trust_score') = 0,
    'ALTER TABLE users ADD COLUMN trust_score INT DEFAULT 0',
    'SELECT \'trust_score column already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and add profile_completion_percentage column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'users' 
     AND COLUMN_NAME = 'profile_completion_percentage') = 0,
    'ALTER TABLE users ADD COLUMN profile_completion_percentage INT DEFAULT 0',
    'SELECT \'profile_completion_percentage column already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Update existing users with default values
UPDATE users SET 
    kyc_status = 'pending' 
WHERE kyc_status IS NULL;

UPDATE users SET 
    trust_score = 0 
WHERE trust_score IS NULL;

UPDATE users SET 
    profile_completion_percentage = 0 
WHERE profile_completion_percentage IS NULL;

-- Show the updated table structure
DESCRIBE users; 