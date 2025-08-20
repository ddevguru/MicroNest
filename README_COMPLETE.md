# MicroNest - Complete Group Management & Blockchain Integration System

## Overview

MicroNest is a comprehensive savings group management application that combines traditional database management with blockchain technology using Ethereum smart contracts. The system allows users to create, join, and manage savings groups with features like contributions, withdrawals, loans, and real-time chat.

## Features

### 🏦 Core Group Management
- **Create Groups**: Set up savings groups with customizable parameters
- **Join Groups**: Browse and join existing groups
- **Member Management**: Admin controls, member roles, and permissions
- **Contribution Tracking**: Monitor individual and group savings

### 💰 Financial Operations
- **Contributions**: Make regular or one-time contributions
- **Withdrawals**: Request and approve fund withdrawals
- **Loans**: Request and manage group loans with interest
- **Transaction History**: Complete audit trail of all financial activities

### 🔗 Blockchain Integration
- **Smart Contracts**: Ethereum-based group management
- **Transparent Transactions**: All operations recorded on blockchain
- **Wallet Integration**: MetaMask and custom wallet support
- **Gas Optimization**: Efficient transaction handling

### 💬 Communication
- **Group Chat**: Real-time messaging within groups
- **Notifications**: Push notifications for important events
- **Admin Alerts**: Special notifications for group administrators

### 🔐 Security Features
- **JWT Authentication**: Secure API access
- **PIN Protection**: Additional security layer
- **Biometric Login**: Fingerprint and face recognition
- **Trust Scoring**: Member reputation system

## System Architecture

### Backend (PHP/MySQL)
```
micronest/backend/
├── api/                    # REST API endpoints
│   ├── profile.php        # User profile management
│   ├── groups.php         # Group operations
│   └── auth.php           # Authentication
├── models/                 # Business logic
│   ├── Profile.php        # Profile operations
│   ├── Group.php          # Group management
│   └── User.php           # User operations
├── config/                 # Configuration files
│   └── database.php       # Database connection
├── utils/                  # Utility classes
│   ├── JWTUtil.php        # JWT token handling
│   └── ResponseUtil.php    # API response formatting
└── database/               # Database schemas
    ├── schema.sql          # Core tables
    └── group_management_schema.sql  # Group-specific tables
```

### Frontend (Flutter)
```
micronest/lib/
├── screens/                # UI screens
│   ├── groups_screen.dart      # Main groups view
│   ├── create_group_screen.dart # Group creation
│   ├── join_group_screen.dart   # Join existing groups
│   └── group_details_screen.dart # Group details & management
├── services/               # Business logic
│   ├── group_service.dart      # Group API integration
│   ├── blockchain_service.dart # Blockchain operations
│   └── profile_service.dart    # Profile management
└── models/                 # Data models
    └── group.dart              # Group data structure
```

### Blockchain (Solidity)
```
micronest/blockchain/
├── contracts/
│   └── SavingsGroup.sol   # Main smart contract
├── migrations/             # Deployment scripts
└── test/                   # Contract tests
```

## Installation & Setup

### Prerequisites
- PHP 8.0+
- MySQL 8.0+
- Flutter 3.8+
- Node.js 16+
- Truffle/Ganache (for blockchain development)

### 1. Backend Setup

#### Database Configuration
```bash
# Create database
mysql -u root -p
CREATE DATABASE micronest_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Import schemas
mysql -u root -p micronest_db < backend/database/schema.sql
mysql -u root -p micronest_db < backend/database/group_management_schema.sql
```

#### PHP Configuration
```bash
cd micronest/backend
composer install

# Update database configuration
cp config/database.example.php config/database.php
# Edit database.php with your credentials
```

#### API Configuration
```bash
# Set up web server (Apache/Nginx)
# Point document root to micronest/backend/

# Test API endpoints
curl -X GET "https://yourdomain.com/api/profile"
```

### 2. Frontend Setup

#### Flutter Dependencies
```bash
cd micronest
flutter pub get

# Install blockchain dependencies
flutter pub add web3dart
flutter pub add bip39
```

#### Environment Configuration
```bash
# Update blockchain service configuration
lib/services/blockchain_service.dart
# Set your Infura project ID and contract addresses
```

### 3. Blockchain Setup

#### Smart Contract Deployment
```bash
cd micronest/blockchain
npm install -g truffle
npm install

# Configure networks in truffle-config.js
# Deploy contracts
truffle migrate --network sepolia
```

#### Contract Addresses
After deployment, update the following files:
- `lib/services/blockchain_service.dart`
- `backend/models/Group.php`

## Usage Guide

### Creating a Group

1. **Navigate to Groups Screen**
   - Tap "Create Group" button
   - Fill in group details (name, description, contribution amount)

2. **Configure Group Settings**
   - Set contribution frequency (daily/weekly/monthly)
   - Define maximum members
   - Set interest rate for loans

3. **Blockchain Integration**
   - Enable blockchain for transparency
   - Smart contract automatically deployed
   - Group address generated

### Joining a Group

1. **Browse Available Groups**
   - View group details and requirements
   - Check member count and contribution amount

2. **Join Process**
   - Traditional: Cash/bank transfer
   - Blockchain: ETH payment via smart contract
   - Automatic member verification

3. **First Contribution**
   - Make initial contribution
   - Receive confirmation on blockchain
   - Access group features unlocked

### Managing Contributions

1. **Regular Contributions**
   - Set up automatic reminders
   - Multiple payment methods supported
   - Real-time balance updates

2. **Withdrawal Requests**
   - Submit withdrawal request
   - Admin approval required
   - Funds transferred to wallet

3. **Loan Management**
   - Request loans from group funds
   - Interest calculation automatic
   - Repayment tracking

### Group Administration

1. **Member Management**
   - Approve new members
   - Promote to admin role
   - Remove inactive members

2. **Financial Oversight**
   - Approve contributions
   - Process withdrawal requests
   - Monitor group funds

3. **Communication**
   - Send group announcements
   - Moderate chat messages
   - Set group rules

## API Endpoints

### Authentication
```
POST /api/auth/login          # User login
POST /api/auth/register       # User registration
POST /api/auth/refresh        # Token refresh
```

### Profile Management
```
GET  /api/profile             # Get user profile
PUT  /api/profile             # Update profile
PUT  /api/profile/notifications # Update notifications
PUT  /api/profile/security    # Update security settings
```

### Group Management
```
GET  /api/groups              # Get user's groups
GET  /api/groups?action=available # Get available groups
POST /api/groups?action=create    # Create new group
POST /api/groups?action=join      # Join existing group
POST /api/groups?action=contribute # Make contribution
POST /api/groups?action=withdraw  # Request withdrawal
POST /api/groups?action=request-loan # Request loan
```

### Group Operations
```
GET  /api/groups?action=details&group_id=X     # Group details
GET  /api/groups?action=members&group_id=X     # Group members
GET  /api/groups?action=transactions&group_id=X # Group transactions
GET  /api/groups?action=chat&group_id=X        # Group chat
POST /api/groups?action=chat                    # Send message
```

## Smart Contract Functions

### Core Functions
```solidity
// Group Management
function joinGroup() external payable
function leaveGroup() external
function makeContribution() external payable

// Financial Operations
function requestWithdrawal(uint256 amount, string reason) external
function requestLoan(uint256 amount, string purpose, uint256 dueDate) external
function repayLoan(uint256 requestId) external payable

// Admin Functions
function confirmContribution(uint256 contributionId) external
function approveWithdrawal(uint256 requestId) external
function approveLoan(uint256 requestId) external
```

### View Functions
```solidity
function getMember(address memberAddress) external view returns (Member memory)
function getGroupStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256)
function getAllMembers() external view returns (address[] memory)
```

## Database Schema

### Core Tables
- `users` - User accounts and profiles
- `savings_groups` - Group information and settings
- `group_members` - Member relationships and roles
- `group_contributions` - Contribution records
- `withdrawal_requests` - Withdrawal requests
- `loans` - Loan information and status
- `transactions` - Complete transaction history

### Blockchain Integration Tables
- `blockchain_wallets` - User wallet addresses
- `smart_contracts` - Deployed contract information
- `group_messages` - Group chat messages
- `group_notifications` - Group-specific notifications

## Security Considerations

### Authentication
- JWT tokens with refresh mechanism
- Secure password hashing (bcrypt)
- Rate limiting on API endpoints

### Blockchain Security
- Smart contract access controls
- Reentrancy protection
- Input validation and sanitization

### Data Protection
- SQL injection prevention (prepared statements)
- XSS protection
- CSRF token validation

## Testing

### Backend Testing
```bash
cd micronest/backend
php test_api_endpoints.php
php test_login.php
php test_registration.php
```

### Smart Contract Testing
```bash
cd micronest/blockchain
truffle test
```

### Flutter Testing
```bash
cd micronest
flutter test
```

## Deployment

### Production Environment
1. **Backend**
   - Use HTTPS with valid SSL certificate
   - Set up proper firewall rules
   - Configure database backups
   - Enable error logging

2. **Frontend**
   - Build release APK/IPA
   - Configure production API endpoints
   - Test on multiple devices

3. **Blockchain**
   - Deploy to mainnet (Ethereum)
   - Verify smart contracts
   - Monitor gas costs

### Environment Variables
```bash
# Database
DB_HOST=localhost
DB_NAME=micronest_db
DB_USER=micronest_user
DB_PASS=secure_password

# JWT
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRY=3600

# Blockchain
INFURA_PROJECT_ID=your_infura_id
CONTRACT_ADDRESS=deployed_contract_address
NETWORK_ID=1  # 1 for mainnet, 11155111 for Sepolia
```

## Troubleshooting

### Common Issues

1. **Profile Loading Failed**
   - Check database connection
   - Verify JWT token validity
   - Check API endpoint configuration

2. **Blockchain Transactions Failing**
   - Verify wallet has sufficient ETH
   - Check gas price settings
   - Ensure correct network configuration

3. **Group Creation Issues**
   - Validate input parameters
   - Check database permissions
   - Verify smart contract deployment

### Debug Mode
Enable debug logging in development:
```php
// backend/config/database.php
define('DEBUG_MODE', true);
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Submit pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create GitHub issue
- Check documentation
- Review troubleshooting guide

## Roadmap

### Phase 2 Features
- [ ] Mobile app optimization
- [ ] Advanced analytics dashboard
- [ ] Multi-currency support
- [ ] Integration with DeFi protocols

### Phase 3 Features
- [ ] AI-powered risk assessment
- [ ] Cross-chain compatibility
- [ ] Advanced governance features
- [ ] Mobile wallet integration

---

**Note**: This is a comprehensive system that combines traditional web technologies with blockchain innovation. Ensure proper testing and security audits before production deployment. 