import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  // Update with your actual backend server URL
  static const String baseUrl = 'https://micronest.devloperwala.in';
  static const String apiBaseUrl = '$baseUrl/api';
  static const String loginEndpoint = '/auth/login';
  static const String signupEndpoint = '/auth/signup';
  static const String refreshEndpoint = '/auth/refresh';
  
  // Token storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // HTTP client
  static final http.Client _client = http.Client();

  // Get stored access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(accessTokenKey);
  }

  // Get stored refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenKey);
  }

  // Store tokens
  static Future<void> storeTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessTokenKey, accessToken);
    await prefs.setString(refreshTokenKey, refreshToken);
  }

  // Store user data
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clean the user data to handle null values
      final cleanUserData = _cleanUserData(userData);
      
      await prefs.setString(userDataKey, jsonEncode(cleanUserData));
      print('✅ User data stored successfully');
    } catch (e) {
      print('❌ Error storing user data: $e');
      // If there's an error, try storing with cleaned data
      try {
        final prefs = await SharedPreferences.getInstance();
        final cleanUserData = _cleanUserData(userData);
        await prefs.setString(userDataKey, jsonEncode(cleanUserData));
        print('✅ User data stored successfully after cleanup');
      } catch (e2) {
        print('❌ Failed to store user data even after cleanup: $e2');
      }
    }
  }

  // Clean user data to handle null values
  static Map<String, dynamic> _cleanUserData(Map<String, dynamic> userData) {
    final cleanData = <String, dynamic>{};
    
    userData.forEach((key, value) {
      if (value == null) {
        // Convert null to empty string for string fields, 0 for numbers, false for booleans
        if (key == 'id' || key == 'trust_score') {
          cleanData[key] = 0;
        } else if (key == 'email_verified') {
          cleanData[key] = false;
        } else if (key == 'status') {
          cleanData[key] = 'active';
        } else {
          cleanData[key] = '';
        }
      } else {
        cleanData[key] = value;
      }
    });
    
    print('🧹 Cleaned user data: $cleanData');
    return cleanData;
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Clear all stored data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(userDataKey);
  }

  // Check if token is expired
  static bool isTokenExpired(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true; // If token can't be decoded, consider it expired
    }
  }

  // Hash password using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Login method
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final hashedPassword = hashPassword(password);
      final url = '$apiBaseUrl$loginEndpoint';
      
      print('🔐 Login URL: $url');
      print('📧 Email: $email');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': hashedPassword,
        }),
      );

      print('📡 Login Response Status: ${response.statusCode}');
      print('📡 Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('📊 Parsed response data: $data');
        
        // Handle nested response structure
        final accessToken = data['data']?['access_token'] ?? data['access_token'];
        final refreshToken = data['data']?['refresh_token'] ?? data['refresh_token'];
        final userData = data['data']?['user'] ?? data['user'];
        
        print('🔑 Access Token: ${accessToken != null ? 'Present' : 'Missing'}');
        print('🔄 Refresh Token: ${refreshToken != null ? 'Present' : 'Missing'}');
        print('👤 User Data: ${userData != null ? 'Present' : 'Missing'}');
        
        if (accessToken != null && refreshToken != null && userData != null) {
          print('✅ All required data present, proceeding to store...');
          
          // Store tokens and user data
          await storeTokens(accessToken, refreshToken);
          await storeUserData(userData);
          
          print('✅ Login process completed successfully');
          
          return {
            'success': true,
            'message': data['message'] ?? 'Login successful',
            'user': userData,
          };
        } else {
          print('❌ Missing required data in response');
          return {
            'success': false,
            'message': 'Invalid response format from server',
          };
        }
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ Login Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Signup method
  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String username,
    required String password,
    required String phone,
    required String address,
    String? profileImageBase64,
  }) async {
    try {
      final hashedPassword = hashPassword(password);
      final url = '$apiBaseUrl$signupEndpoint';
      
      print('📝 Signup URL: $url');
      print('📧 Email: $email');
      print('👤 Username: $username');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'username': username,
          'password': hashedPassword,
          'phone': phone,
          'address': address,
          'profile_image': profileImageBase64,
        }),
      );

      print('📡 Signup Response Status: ${response.statusCode}');
      print('📡 Signup Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Store tokens and user data
        await storeTokens(data['access_token'], data['refresh_token']);
        await storeUserData(data['user']);
        
        return {
          'success': true,
          'message': 'Account created successfully',
          'user': data['user'],
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': errorData['message'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      print('❌ Signup Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Send email OTP method
  static Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    try {
      final url = '$apiBaseUrl/auth/send-otp';
      print('📤 Send OTP URL: $url');
      print('📧 Email: $email');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      print('📡 Send OTP Response Status: ${response.statusCode}');
      print('📡 Send OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      print('❌ Send OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Verify email OTP method
  static Future<Map<String, dynamic>> verifyEmailOtp(String email, String otp) async {
    try {
      final url = '$apiBaseUrl/auth/verify-otp';
      print('✅ Verify OTP URL: $url');
      print('📧 Email: $email');
      print('🔢 OTP: $otp');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      print('📡 Verify OTP Response Status: ${response.statusCode}');
      print('📡 Verify OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Email verified successfully',
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': errorData['message'] ?? 'OTP verification failed',
        };
      }
    } catch (e) {
      print('❌ Verify OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Refresh token method
  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return {
          'success': false,
          'message': 'No refresh token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$baseUrl$refreshEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Store new tokens
        await storeTokens(data['access_token'], data['refresh_token']);
        
        return {
          'success': true,
          'message': 'Token refreshed successfully',
        };
      } else {
        // Refresh token is invalid, clear all data
        await clearAllData();
        return {
          'success': false,
          'message': 'Session expired, please login again',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Logout method
  static Future<void> logout() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        // Call logout endpoint if available
        await _client.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );
      }
    } catch (e) {
      // Ignore errors during logout
    } finally {
      // Clear all stored data
      await clearAllData();
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;
    
    if (isTokenExpired(accessToken)) {
      // Try to refresh token
      final refreshResult = await refreshToken();
      return refreshResult['success'] ?? false;
    }
    
    return true;
  }

  // Check if user is logged in (alias for isAuthenticated)
  static Future<bool> isLoggedIn() async {
    return await isAuthenticated();
  }

  // Get authenticated user data
  static Future<Map<String, dynamic>?> getAuthenticatedUser() async {
    if (await isAuthenticated()) {
      return await getUserData();
    }
    return null;
  }

  // Make authenticated API request
  static Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final accessToken = await getAccessToken();
    
    if (accessToken == null) {
      throw Exception('No access token available');
    }

    if (isTokenExpired(accessToken)) {
      final refreshResult = await refreshToken();
      if (!(refreshResult['success'] ?? false)) {
        throw Exception('Failed to refresh token');
      }
    }

    final finalAccessToken = await getAccessToken();
    final finalHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $finalAccessToken',
      ...?headers,
    };

    final uri = Uri.parse('$baseUrl$endpoint');
    
    switch (method.toUpperCase()) {
      case 'GET':
        return await _client.get(uri, headers: finalHeaders);
      case 'POST':
        return await _client.post(
          uri,
          headers: finalHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await _client.put(
          uri,
          headers: finalHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await _client.delete(uri, headers: finalHeaders);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }
} 