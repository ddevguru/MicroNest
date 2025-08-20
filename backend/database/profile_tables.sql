-- Profile System Database Tables
-- Run this script to create all necessary tables for the profile functionality

-- User Preferences Table
CREATE TABLE IF NOT EXISTS user_preferences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    push_notifications BOOLEAN DEFAULT TRUE,
    loan_reminders BOOLEAN DEFAULT TRUE,
    group_chat BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_preferences (user_id)
);

-- User Security Table
CREATE TABLE IF NOT EXISTS user_security (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    biometric_login BOOLEAN DEFAULT FALSE,
    pin_enabled BOOLEAN DEFAULT FALSE,
    pin_hash VARCHAR(255) NULL,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP NULL,
    failed_login_attempts INT DEFAULT 0,
    account_locked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_security (user_id)
);

-- User Achievements Table
CREATE TABLE IF NOT EXISTS user_achievements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    achievement_type VARCHAR(100) NOT NULL,
    achievement_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_earned BOOLEAN DEFAULT FALSE,
    progress INT DEFAULT 0,
    max_progress INT DEFAULT 100,
    earned_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_achievement (user_id, achievement_type)
);

-- Trust Score History Table
CREATE TABLE IF NOT EXISTS trust_score_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    score INT NOT NULL,
    previous_score INT NULL,
    change_reason VARCHAR(255),
    change_amount INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_score (user_id, score),
    INDEX idx_created_at (created_at)
);

-- User Profile Extensions Table
CREATE TABLE IF NOT EXISTS user_profile_extensions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    date_of_birth DATE NULL,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say') NULL,
    address TEXT NULL,
    city VARCHAR(100) NULL,
    state VARCHAR(100) NULL,
    pincode VARCHAR(10) NULL,
    occupation VARCHAR(100) NULL,
    monthly_income DECIMAL(12,2) NULL,
    emergency_contact_name VARCHAR(255) NULL,
    emergency_contact_phone VARCHAR(20) NULL,
    emergency_contact_relation VARCHAR(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_profile (user_id)
);

-- Insert default achievements for existing users
INSERT IGNORE INTO user_achievements (user_id, achievement_type, achievement_name, description, is_earned, progress, max_progress) VALUES
(1, 'first_contribution', 'First Contribution', 'Made your first group contribution', FALSE, 0, 1),
(1, 'trusted_member', 'Trusted Member', 'Achieved 75% trust score', FALSE, 0, 75),
(1, 'group_builder', 'Group Builder', 'Helped create a new savings group', FALSE, 0, 1),
(1, 'perfect_payer', 'Perfect Payer', 'Completed 5 loans with perfect repayment', FALSE, 0, 5),
(1, 'savings_champion', 'Savings Champion', 'Saved ₹10,000 or more', FALSE, 0, 10000);

-- Insert default preferences for existing users
INSERT IGNORE INTO user_preferences (user_id, push_notifications, loan_reminders, group_chat, email_notifications, sms_notifications) VALUES
(1, TRUE, TRUE, TRUE, TRUE, FALSE);

-- Insert default security settings for existing users
INSERT IGNORE INTO user_security (user_id, biometric_login, pin_enabled, two_factor_enabled) VALUES
(1, FALSE, FALSE, FALSE);

-- Insert default profile extensions for existing users
INSERT IGNORE INTO user_profile_extensions (user_id) VALUES (1);

-- Note: Run the separate fix_users_table.sql script to safely add missing columns to the users table
-- This avoids MySQL version compatibility issues with IF NOT EXISTS syntax

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_trust_score ON users(trust_score);
CREATE INDEX IF NOT EXISTS idx_users_kyc_status ON users(kyc_status);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_security_user_id ON user_security(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_trust_score_history_user_id ON trust_score_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profile_extensions_user_id ON user_profile_extensions(user_id); 