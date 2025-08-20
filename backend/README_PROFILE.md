# 🎯 **Profile System Setup Guide**

## 📋 **Overview**
Complete profile management system with 4 tabs: Profile, Trust, Awards, and Settings. Follows the same design pattern as the home dashboard with smooth animations.

## 🚀 **Quick Setup**

### **1. Database Setup**
Run the SQL script to create all necessary tables:
```bash
mysql -u your_username -p your_database < database/profile_tables.sql
```

### **2. File Structure**
```
backend/
├── api/
│   ├── index.php (updated with profile routes)
│   └── profile.php (standalone profile API)
├── models/
│   └── Profile.php (profile model)
├── database/
│   └── profile_tables.sql (database schema)
└── README_PROFILE.md (this file)
```

### **3. Flutter Integration**
```
lib/
├── screens/
│   └── profile_screen.dart (main profile screen)
├── services/
│   └── profile_service.dart (profile API service)
└── main.dart (updated with profile route)
```

## 🔧 **API Endpoints**

### **Profile Data**
- **GET** `/api/profile` - Get complete profile data
- **PUT** `/api/profile` - Update profile information

### **Trust Score**
- **GET** `/api/profile/trust-score` - Get trust score details

### **Awards & Achievements**
- **GET** `/api/profile/awards` - Get user achievements

### **Notification Settings**
- **PUT** `/api/profile/notifications` - Update notification preferences

### **Security Settings**
- **PUT** `/api/profile/security` - Update security preferences

## 📊 **Database Tables**

### **Core Tables**
1. **user_preferences** - Notification and app preferences
2. **user_security** - Security settings and PIN
3. **user_achievements** - User achievements and progress
4. **trust_score_history** - Trust score change tracking
5. **user_profile_extensions** - Extended profile information

### **Updated Tables**
- **users** - Added `kyc_status`, `trust_score`, `profile_completion_percentage`

## 🎨 **Features**

### **Profile Tab**
- User information display
- Trust score badge
- KYC status
- Account statistics
- Edit profile functionality

### **Trust Tab**
- Overall trust score
- Score breakdown (Payment History, Group Participation, KYC, Network)
- Progress bars and visual indicators
- Trust score benefits explanation

### **Awards Tab**
- Achievement system (5 achievements)
- Progress tracking
- Earned vs. in-progress status
- Achievement descriptions and dates

### **Settings Tab**
- Notification preferences
- Security settings
- Support options
- Toggle switches and action buttons

## 🔐 **Security Features**

- JWT token authentication
- User-specific data access
- Secure preference storage
- Biometric login support
- PIN protection

## 📱 **User Experience**

- **Smooth animations** - Staggered entrance effects
- **Responsive design** - Works on all screen sizes
- **Dark theme** - Consistent with app design
- **Interactive elements** - Haptic feedback and smooth transitions
- **Loading states** - Professional loading indicators

## 🚀 **Getting Started**

### **1. Backend Setup**
```bash
cd backend
# Run database script
mysql -u username -p database_name < database/profile_tables.sql

# Test API endpoints
curl -H "Authorization: Bearer YOUR_TOKEN" https://your-domain.com/api/profile
```

### **2. Flutter Setup**
```bash
cd micronest
# Add profile route to main.dart
# Import profile screen
# Test navigation from home dashboard
```

### **3. Test Profile System**
1. Login to the app
2. Click settings icon in home dashboard
3. Navigate through all 4 tabs
4. Test notification toggles
5. Verify data loading

## 🔍 **Troubleshooting**

### **Common Issues**

1. **Profile not loading**
   - Check JWT token validity
   - Verify database connection
   - Check API endpoint URLs

2. **Database errors**
   - Ensure all tables are created
   - Check foreign key constraints
   - Verify user exists in users table

3. **Animation issues**
   - Check Flutter version compatibility
   - Verify animation controllers are properly disposed
   - Check for null safety issues

### **Debug Mode**
Enable debug logging in PHP:
```php
error_log("Profile API Debug: " . json_encode($data));
```

## 📈 **Performance Optimization**

- Database indexes on frequently queried fields
- Caching for trust score calculations
- Lazy loading for achievements
- Optimized SQL queries with JOINs

## 🔮 **Future Enhancements**

- Profile picture upload
- Social media integration
- Advanced KYC verification
- Achievement sharing
- Trust score analytics
- Profile completion rewards

## 📞 **Support**

For issues or questions:
1. Check the error logs
2. Verify database schema
3. Test API endpoints individually
4. Check Flutter console for errors

---

**🎉 Your Profile System is Ready!** Users can now access a complete profile management system with beautiful animations and full backend integration. 