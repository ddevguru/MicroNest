# 🗄️ **Profile System Database Setup Steps**

## 📋 **Step-by-Step Instructions**

### **Step 1: Create Profile Tables**
Run this command in your MySQL database:
```sql
source database/profile_tables.sql;
```

### **Step 2: Fix Users Table**
Run this command to add missing columns to the users table:
```sql
source database/fix_users_table.sql;
```

### **Step 3: Verify Setup**
Check if all tables were created successfully:
```sql
SHOW TABLES LIKE '%user%';
SHOW TABLES LIKE '%trust%';
SHOW TABLES LIKE '%achievement%';
```

### **Step 4: Check Users Table Structure**
Verify the users table has all required columns:
```sql
DESCRIBE users;
```

You should see these columns:
- `kyc_status` (ENUM: pending, verified, rejected)
- `trust_score` (INT)
- `profile_completion_percentage` (INT)

## 🔧 **Alternative: Manual Column Addition**

If the prepared statement approach doesn't work, manually add columns:

```sql
-- Add kyc_status column
ALTER TABLE users ADD COLUMN kyc_status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending';

-- Add trust_score column  
ALTER TABLE users ADD COLUMN trust_score INT DEFAULT 0;

-- Add profile_completion_percentage column
ALTER TABLE users ADD COLUMN profile_completion_percentage INT DEFAULT 0;
```

## ✅ **Verification Commands**

After setup, run these to verify everything works:

```sql
-- Check if profile tables exist
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME IN ('user_preferences', 'user_security', 'user_achievements');

-- Check if users table has new columns
SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'users' 
AND COLUMN_NAME IN ('kyc_status', 'trust_score', 'profile_completion_percentage');

-- Check sample data
SELECT * FROM user_achievements LIMIT 5;
SELECT * FROM user_preferences LIMIT 5;
```

## 🚨 **Troubleshooting**

### **Error: "Table doesn't exist"**
- Make sure you're in the correct database
- Check if the SQL files are in the right location

### **Error: "Column already exists"**
- This is normal if columns were already added
- The script will skip existing columns

### **Error: "Access denied"**
- Check your MySQL user permissions
- Ensure you have ALTER, CREATE, INSERT privileges

## 🎯 **What Gets Created**

1. **user_preferences** - Notification settings
2. **user_security** - Security preferences  
3. **user_achievements** - Achievement tracking
4. **trust_score_history** - Score changes
5. **user_profile_extensions** - Extended profile data
6. **Updated users table** - New columns for KYC, trust score, completion

## 🚀 **Next Steps**

After database setup:
1. Test the Flutter app
2. Click settings icon in home dashboard
3. Navigate to profile screen
4. Verify all tabs load correctly

---

**🎉 Database setup complete! Your profile system is ready to use.** 