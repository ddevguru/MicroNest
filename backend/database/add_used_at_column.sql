-- Add used_at column to email_otps table
ALTER TABLE email_otps ADD COLUMN used_at TIMESTAMP NULL AFTER used;

-- Update existing records to have used_at set to created_at if they are already used
UPDATE email_otps SET used_at = created_at WHERE used = TRUE AND used_at IS NULL;

-- Add index for better performance
ALTER TABLE email_otps ADD INDEX idx_used_at (used_at); 