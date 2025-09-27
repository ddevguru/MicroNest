# MicroNest Authentication Backend

A complete PHP/MySQL backend for user authentication with email OTP verification using SMTP2GO.

## Features

- User registration and login
- Email OTP verification using SMTP2GO
- JWT-based authentication (access & refresh tokens)
- Password hashing with Argon2ID
- CORS support
- Input validation and sanitization
- Error handling and logging
- Clean API responses

## Setup Instructions

### 1. Install Dependencies

\`\`\`bash
composer install
\`\`\`

### 2. Database Setup

1. Create a MySQL database named `micronest_auth`
2. Import the schema from `database/schema.sql`
3. Update database credentials in `config/database.php`

### 3. Configuration

1. Update `config/config.php` with your settings:
   - Change `JWT_SECRET` to a secure random string
   - Add your SMTP2GO API key
   - Set your domain and email settings
   - Configure CORS allowed origins

### 4. SMTP2GO Setup

1. Sign up at [SMTP2GO](https://www.smtp2go.com/)
2. Get your API key from the dashboard
3. Update `SMTP2GO_API_KEY` in `config/config.php`
4. Set your sender email in `FROM_EMAIL`

### 5. Web Server Configuration

#### Apache
- Ensure mod_rewrite is enabled
- The `.htaccess` file is already configured

#### Nginx
Add this to your server block:
\`\`\`nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
\`\`\`

## API Endpoints

### POST /api/auth/signup
Create a new user account.

**Request Body:**
\`\`\`json
{
    "full_name": "John Doe",
    "email": "john@example.com",
    "username": "johndoe",
    "password": "hashed_password",
    "phone": "1234567890",
    "address": "123 Main St, City, Country",
    "profile_image": "base64_image_data"
}
\`\`\`

### POST /api/auth/login
User login with email and password.

**Request Body:**
\`\`\`json
{
    "email": "john@example.com",
    "password": "hashed_password"
}
\`\`\`

### POST /api/auth/send-otp
Send OTP to email for verification.

**Request Body:**
\`\`\`json
{
    "email": "john@example.com"
}
\`\`\`

### POST /api/auth/verify-otp
Verify email OTP.

**Request Body:**
\`\`\`json
{
    "email": "john@example.com",
    "otp": "123456"
}
\`\`\`

### POST /api/auth/refresh
Refresh access token using refresh token.

**Headers:**
\`\`\`
Authorization: Bearer <refresh_token>
\`\`\`

### POST /api/auth/logout
Logout user and invalidate tokens.

**Headers:**
\`\`\`
Authorization: Bearer <access_token>
\`\`\`

## Security Features

- Password hashing with Argon2ID
- JWT tokens with expiration
- Refresh token rotation
- Input validation and sanitization
- CORS protection
- SQL injection prevention with prepared statements
- XSS protection headers

## Error Handling

All endpoints return consistent JSON responses:

**Success Response:**
\`\`\`json
{
    "success": true,
    "message": "Operation successful",
    "data": {...},
    "timestamp": "2024-01-01T00:00:00+00:00"
}
\`\`\`

**Error Response:**
\`\`\`json
{
    "success": false,
    "message": "Error description",
    "errors": [...],
    "timestamp": "2024-01-01T00:00:00+00:00"
}
\`\`\`

## Maintenance

### Cleanup Expired Data
Run these queries periodically to clean up expired data:

\`\`\`sql
DELETE FROM email_otps WHERE expires_at < NOW();
DELETE FROM refresh_tokens WHERE expires_at < NOW();
\`\`\`

### Logs
Error logs are stored in `logs/error.log`. Monitor this file for any issues.

## Production Deployment

1. Set `display_errors = 0` in PHP configuration
2. Use environment variables for sensitive configuration
3. Enable HTTPS
4. Set up proper database user with minimal privileges
5. Configure proper file permissions
6. Set up log rotation
7. Enable PHP OPcache for better performance
