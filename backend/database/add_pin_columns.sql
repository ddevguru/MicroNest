-- Add PIN-related columns to user_security table
-- This script safely adds missing columns for PIN functionality

-- Check and add pin_hash column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'user_security' 
     AND COLUMN_NAME = 'pin_hash') = 0,
    'ALTER TABLE user_security ADD COLUMN pin_hash VARCHAR(255) NULL',
    'SELECT \'pin_hash column already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and add pin_enabled column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'user_security' 
     AND COLUMN_NAME = 'pin_enabled') = 0,
    'ALTER TABLE user_security ADD COLUMN pin_enabled BOOLEAN DEFAULT FALSE',
    'SELECT \'pin_enabled column already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and add biometric_login column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'user_security' 
     AND COLUMN_NAME = 'biometric_login') = 0,
    'ALTER TABLE user_security ADD COLUMN biometric_login BOOLEAN DEFAULT FALSE',
    'SELECT \'biometric_login column already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Insert default security settings for existing users if they don't exist
INSERT IGNORE INTO user_security (user_id, pin_enabled, biometric_login)
SELECT id, FALSE, FALSE FROM users 
WHERE id NOT IN (SELECT user_id FROM user_security);

-- Show the updated table structure
DESCRIBE user_security; 