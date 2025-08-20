-- Create Indexes Safely
-- This script creates indexes only if they don't already exist

-- Check and create users table indexes
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'users' 
     AND INDEX_NAME = 'idx_users_trust_score') = 0,
    'CREATE INDEX idx_users_trust_score ON users(trust_score)',
    'SELECT \'idx_users_trust_score index already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'users' 
     AND INDEX_NAME = 'idx_users_kyc_status') = 0,
    'CREATE INDEX idx_users_kyc_status ON users(kyc_status)',
    'SELECT \'idx_users_kyc_status index already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and create user_preferences indexes
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'user_preferences' 
     AND INDEX_NAME = 'idx_user_preferences_user_id') = 0,
    'CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id)',
    'SELECT \'idx_user_preferences_user_id index already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and create user_security indexes
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'user_security' 
     AND INDEX_NAME = 'idx_user_security_user_id') = 0,
    'CREATE INDEX idx_user_security_user_id ON user_security(user_id)',
    'SELECT \'idx_user_security_user_id index already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and create user_achievements indexes
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'user_achievements' 
     AND INDEX_NAME = 'idx_user_achievements_user_id') = 0,
    'CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id)',
    'SELECT \'idx_user_achievements_user_id index already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and create trust_score_history indexes
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'trust_score_history' 
     AND INDEX_NAME = 'idx_trust_score_history_user_id') = 0,
    'CREATE INDEX idx_trust_score_history_user_id ON trust_score_history(user_id)',
    'SELECT \'idx_trust_score_history_user_id index already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and create user_profile_extensions indexes
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'user_profile_extensions' 
     AND INDEX_NAME = 'idx_user_profile_extensions_user_id') = 0,
    'CREATE INDEX idx_user_profile_extensions_user_id ON user_profile_extensions(user_id)',
    'SELECT \'idx_user_profile_extensions_user_id index already exists\' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Show all indexes for verification
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME IN ('users', 'user_preferences', 'user_security', 'user_achievements', 'trust_score_history', 'user_profile_extensions')
ORDER BY TABLE_NAME, INDEX_NAME; 