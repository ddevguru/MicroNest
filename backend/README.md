# MicroNest Backend API

A PHP-based backend API for the MicroNest financial application with JWT authentication, email verification, and MySQL database.

## Features

- **User Authentication**: Login, signup with JWT tokens
- **Email Verification**: OTP-based email verification using SMTP2GO
- **User Management**: Profile management, trust score system
- **Security**: JWT tokens, password hashing, input validation
- **Database**: MySQL with proper indexing and relationships

## Requirements

- PHP 7.4 or higher
- MySQL 5.7 or higher
- Apache/Nginx web server
- cURL extension for PHP
- PDO extension for PHP

## Installation

### 1. Database Setup

1. Create a MySQL database:
```sql
CREATE DATABASE micronest_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. Import the database schema:
```bash
mysql -u root -p micronest_db < database/schema.sql
```

### 2. Backend Setup

1. Clone or download the backend files to your web server directory
2. Update database configuration in `config/database.php`:
```php
private $host = "localhost";
private $db_name = "micronest_db";
private $username = "your_mysql_username";
private $password = "your_mysql_password";
```

3. Update SMTP2GO API key in `models/Auth.php`:
```php
$apiKey = 'YOUR_ACTUAL_SMTP2GO_API_KEY';
```

4. Update JWT secret key in `utils/JWTUtil.php`:
```php
$this->secretKey = 'your-secure-secret-key-here';
```

### 3. SMTP2GO Setup

1. Sign up for SMTP2GO account at [https://www.smtp2go.com/](https://www.smtp2go.com/)
2. Get your API key from the dashboard
3. Verify your sender email domain
4. Update the API key in the Auth model

### 4. Web Server Configuration

#### Apache (.htaccess)
```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ api/index.php [QSA,L]

# CORS headers
Header always set Access-Control-Allow-Origin "*"
Header always set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
Header always set Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With"
```

#### Nginx
```nginx
location / {
    try_files $uri $uri/ /api/index.php?$query_string;
}

location ~ \.php$ {
    fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

## API Endpoints

### Authentication

#### POST /api/auth/login
Login with email and password
```json
{
    "email": "user@example.com",
    "password": "password123"
}
```

#### POST /api/auth/signup
Create new user account
```json
{
    "full_name": "John Doe",
    "email": "john@example.com",
    "username": "johndoe",
    "password": "password123",
    "phone": "+1234567890",
    "address": "123 Main St, City, Country",
    "profile_image": "base64_encoded_image_data"
}
```

#### POST /api/auth/send-otp
Send email verification OTP
```json
{
    "email": "user@example.com"
}
```

#### POST /api/auth/verify-otp
Verify email OTP
```json
{
    "email": "user@example.com",
    "otp": "123456"
}
```

#### POST /api/auth/refresh
Refresh access token using refresh token
```http
Authorization: Bearer <refresh_token>
```

#### POST /api/auth/logout
Logout user (invalidate tokens)
```http
Authorization: Bearer <access_token>
```

### User Management

#### GET /api/users/profile
Get user profile (requires authentication)
```http
Authorization: Bearer <access_token>
```

#### PUT /api/users/profile
Update user profile (requires authentication)
```http
Authorization: Bearer <access_token>
Content-Type: application/json

{
    "full_name": "John Smith",
    "phone": "+1234567890",
    "address": "456 Oak St, City, Country"
}
```

#### GET /api/users/trust-score
Get user trust score and history (requires authentication)
```http
Authorization: Bearer <access_token>
```

## Database Schema

### Core Tables

- **users**: User accounts and profiles
- **email_otps**: Email verification OTPs
- **user_tokens**: JWT refresh tokens
- **trust_score_history**: Trust score changes tracking

### Financial Tables

- **savings_groups**: Savings group information
- **group_members**: Group membership
- **contributions**: User contributions to groups
- **loans**: Loan applications and details
- **loan_payments**: Loan repayment records

### System Tables

- **admin_users**: Admin user accounts
- **system_settings**: Application configuration
- **notifications**: User notifications

## Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: Bcrypt password hashing
- **Input Validation**: Server-side input validation
- **SQL Injection Prevention**: Prepared statements
- **CORS Protection**: Cross-origin resource sharing headers
- **Rate Limiting**: API rate limiting (to be implemented)

## Trust Score System

The trust score system tracks user behavior and financial reliability:

- **Contribution**: +1.0 per confirmed contribution
- **Loan Default**: -5.0 for loan default
- **Admin Adjustment**: Manual score adjustments by administrators

## Error Handling

All API responses follow a consistent format:

### Success Response
```json
{
    "success": true,
    "message": "Operation completed successfully",
    "data": {...},
    "timestamp": "2024-01-01 12:00:00"
}
```

### Error Response
```json
{
    "success": false,
    "message": "Error description",
    "timestamp": "2024-01-01 12:00:00"
}
```

## Testing

Test the API endpoints using tools like Postman or curl:

```bash
# Test login
curl -X POST http://localhost/micronest/backend/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Test protected endpoint
curl -X GET http://localhost/micronest/backend/api/users/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Production Deployment

1. **Environment Variables**: Use environment variables for sensitive data
2. **HTTPS**: Enable SSL/TLS encryption
3. **Database Security**: Use dedicated database user with minimal privileges
4. **JWT Secret**: Use a strong, random secret key
5. **SMTP2GO**: Verify sender domain and use production API keys
6. **Logging**: Implement proper error logging and monitoring
7. **Backup**: Regular database backups

## Troubleshooting

### Common Issues

1. **Database Connection Error**: Check database credentials and connection
2. **JWT Token Invalid**: Verify secret key and token expiration
3. **Email Not Sending**: Check SMTP2GO API key and sender verification
4. **CORS Issues**: Verify web server CORS configuration

### Debug Mode

Enable error reporting in PHP for development:
```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

## Support

For issues and questions:
1. Check the error logs
2. Verify database connectivity
3. Test API endpoints individually
4. Check web server configuration

## License

This project is licensed under the MIT License. 