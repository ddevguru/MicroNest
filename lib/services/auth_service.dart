import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  static const String baseUrl = 'https://micronest.devloperwala.in';
  static const String apiBaseUrl = '$baseUrl/api';
  static const String loginEndpoint = '/auth/login.php';
  static const String signupEndpoint = '/auth/signup.php';
  static const String refreshEndpoint = '/auth/refresh.php';
  static const String createGroupEndpoint = '/api/groups/create.php';
  static const String joinGroupEndpoint = '/api/groups/join.php';
  static const String userGroupsEndpoint = '/groups/user-groups.php'; // Fixed endpoint
  static const String availableGroupsEndpoint = '/api/groups/available.php'; // Adjusted to match file structure
  static const String leaveGroupEndpoint = '/api/groups/leave.php';
  static const String contributionEndpoint = '/api/auth/contribution.php';
  static const String withdrawalEndpoint = '/api/auth/withdrawal.php';
  static const String loanEndpoint = '/api/auth/loan.php';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  static final http.Client _client = http.Client();

  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenKey);
  }

  static Future<void> storeTokens(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(refreshTokenKey);
      print('⚠️ No refresh token provided, skipping storage');
    }
  }

  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanUserData = _cleanUserData(userData);
      await prefs.setString(userDataKey, jsonEncode(cleanUserData));
      print('✅ User data stored successfully');
    } catch (e) {
      print('❌ Error storing user data: $e');
    }
  }

  static Map<String, dynamic> _cleanUserData(Map<String, dynamic> userData) {
    final cleanData = <String, dynamic>{};
    userData.forEach((key, value) {
      if (value == null) {
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

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(userDataKey);
  }

  static bool isTokenExpired(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      if (!_isValidEmail(email)) {
        print('❌ Invalid email format: $email');
        return {'success': false, 'message': 'Invalid email format'};
      }

      final url = '$apiBaseUrl$loginEndpoint';
      print('🔐 Login URL: $url');
      print('📧 Email: $email');
      print('🔑 Password: $password');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('📡 Login Response Status: ${response.statusCode}');
      print('📡 Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final accessToken = data['data']?['access_token'] ?? data['access_token'];
          final refreshToken = data['data']?['refresh_token'] ?? data['refresh_token'];
          final userData = data['data']?['user'] ?? data['user'];
          
          if (accessToken != null && refreshToken != null && userData != null) {
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
            return {'success': false, 'message': 'Invalid response format from server'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          print('📡 Raw Response Body: ${response.body}');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          print('❌ Login failed: ${errorData['message']}');
          return {'success': false, 'message': errorData['message'] ?? 'Login failed'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          print('📡 Raw Response Body: ${response.body}');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Login Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

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
      if (!_isValidEmail(email)) {
        print('❌ Invalid email format: $email');
        return {'success': false, 'message': 'Invalid email format'};
      }

      final url = '$apiBaseUrl$signupEndpoint';
      print('📝 Signup URL: $url');
      print('📧 Email: $email');
      print('👤 Username: $username');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'username': username,
          'password': password,
          'phone': phone,
          'address': address,
          'profile_image': profileImageBase64,
        }),
      );

      print('📡 Signup Response Status: ${response.statusCode}');
      print('📡 Signup Response Body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final dataField = data['data'] as Map<String, dynamic>?;
          final accessToken = dataField?['access_token'] ?? data['access_token'];
          final refreshToken = dataField?['refresh_token'] ?? data['refresh_token'];
          final userData = dataField?['user'] ?? data['user'];

          if (accessToken != null && userData != null) {
            await storeTokens(accessToken, refreshToken);
            await storeUserData(userData);
            if (refreshToken == null) {
              print('⚠️ Refresh token missing, signup completed with warning');
              return {
                'success': true,
                'message': data['message'] ?? 'Account created with warning: Refresh token missing',
                'user': userData,
              };
            }
            print('✅ Signup process completed successfully');
            return {
              'success': true,
              'message': data['message'] ?? 'Account created successfully',
              'user': userData,
            };
          } else {
            print('❌ Missing required data in response');
            return {
              'success': false,
              'message': 'Invalid response format from server: Missing access_token or user data',
            };
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          print('📡 Raw Response Body: ${response.body}');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          print('❌ Signup failed: ${errorData['message']}');
          return {'success': false, 'message': errorData['message'] ?? 'Signup failed'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          print('📡 Raw Response Body: ${response.body}');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Signup Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    try {
      if (!_isValidEmail(email)) {
        print('❌ Invalid email format: $email');
        return {'success': false, 'message': 'Invalid email format'};
      }

      final url = '$apiBaseUrl/auth/send-otp';
      print('📤 Send OTP URL: $url');
      print('📧 Email: $email');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('📡 Send OTP Response Status: ${response.statusCode}');
      print('📡 Send OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': true, 'message': data['message'] ?? 'OTP sent successfully'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          print('📡 Raw Response Body: ${response.body}');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to send OTP'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          print('📡 Raw Response Body: ${response.body}');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Send OTP Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmailOtp(String email, String otp) async {
    try {
      if (!_isValidEmail(email)) {
        print('❌ Invalid email format: $email');
        return {'success': false, 'message': 'Invalid email format'};
      }

      final url = '$apiBaseUrl/auth/verify-otp';
      print('✅ Verify OTP URL: $url');
      print('📧 Email: $email');
      print('🔢 OTP: $otp');
      
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      print('📡 Verify OTP Response Status: ${response.statusCode}');
      print('📡 Verify OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': true, 'message': data['message'] ?? 'Email verified successfully'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          print('📡 Raw Response Body: ${response.body}');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'OTP verification failed'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          print('📡 Raw Response Body: ${response.body}');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Verify OTP Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return {'success': false, 'message': 'No refresh token available'};
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl$refreshEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final accessToken = data['data']?['access_token'] ?? data['access_token'];
          final refreshTokenNew = data['data']?['refresh_token'] ?? data['refresh_token'];

          if (accessToken != null && refreshTokenNew != null) {
            await storeTokens(accessToken, refreshTokenNew);
            return {'success': true, 'message': 'Token refreshed successfully'};
          } else {
            return {'success': false, 'message': 'Invalid token refresh response format'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          print('📡 Raw Response Body: ${response.body}');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        await clearAllData();
        return {'success': false, 'message': 'Session expired, please login again'};
      }
    } catch (e) {
      print('❌ Refresh Token Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createGroup(Map<String, dynamic> groupData) async {
    try {
      final response = await authenticatedRequest(
        'POST',
        createGroupEndpoint,
        body: groupData,
      );

      print('📡 Create Group Response Status: ${response.statusCode}');
      print('📡 Create Group Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success']) {
            return {
              'success': true,
              'group_id': data['data']['id'] ?? data['data']['group_id'],
              'message': data['message'] ?? 'Group created successfully',
            };
          } else {
            return {'success': false, 'message': data['message'] ?? 'Failed to create group'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to create group'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Create Group Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> joinGroup(int groupId, double amount, String paymentMethod) async {
    try {
      final response = await authenticatedRequest(
        'POST',
        joinGroupEndpoint,
        body: {
          'group_id': groupId,
          'amount': amount,
          'payment_method': paymentMethod,
        },
      );

      print('📡 Join Group Response Status: ${response.statusCode}');
      print('📡 Join Group Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success']) {
            return {
              'success': true,
              'data': data['data'],
              'message': data['message'] ?? 'Successfully joined group',
            };
          } else {
            return {'success': false, 'message': data['message'] ?? 'Failed to join group'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to join group'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Join Group Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getUserGroups() async {
    try {
      final response = await authenticatedRequest('GET', userGroupsEndpoint);

      print('📡 Get User Groups Response Status: ${response.statusCode}');
      print('📡 Get User Groups Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success']) {
            return {
              'success': true,
              'groups': data['data'],
              'message': data['message'] ?? 'Groups fetched successfully',
            };
          } else {
            return {'success': false, 'message': data['message'] ?? 'Failed to fetch groups'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to fetch groups'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Get User Groups Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getAvailableGroups() async {
    try {
      final response = await authenticatedRequest('GET', availableGroupsEndpoint);

      print('📡 Get Available Groups Response Status: ${response.statusCode}');
      print('📡 Get Available Groups Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success']) {
            return {
              'success': true,
              'groups': data['data'],
              'message': data['message'] ?? 'Available groups fetched successfully',
            };
          } else {
            return {'success': false, 'message': data['message'] ?? 'Failed to fetch available groups'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to fetch available groups'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Get Available Groups Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getGroupDetails(int groupId) async {
    try {
      final response = await authenticatedRequest('GET', '/api/groups/details?group_id=$groupId');

      print('📡 Get Group Details Response Status: ${response.statusCode}');
      print('📡 Get Group Details Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success']) {
            return {
              'success': true,
              'group': data['data']['group'],
              'members': data['data']['members'],
              'message': data['message'] ?? 'Group details fetched successfully',
            };
          } else {
            return {'success': false, 'message': data['message'] ?? 'Failed to fetch group details'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to fetch group details'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Get Group Details Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> leaveGroup(int groupId) async {
    try {
      final response = await authenticatedRequest(
        'POST',
        leaveGroupEndpoint,
        body: {'group_id': groupId},
      );

      print('📡 Leave Group Response Status: ${response.statusCode}');
      print('📡 Leave Group Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success']) {
            return {'success': true, 'message': data['message'] ?? 'Successfully left group'};
          } else {
            return {'success': false, 'message': data['message'] ?? 'Failed to leave group'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to leave group'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Leave Group Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> makeContribution(int groupId, double amount) async {
    try {
      final response = await authenticatedRequest(
        'POST',
        contributionEndpoint,
        body: {'group_id': groupId, 'amount': amount},
      );

      print('📡 Contribution Response Status: ${response.statusCode}');
      print('📡 Contribution Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success']) {
            return {'success': true, 'message': data['message'] ?? 'Contribution submitted successfully'};
          } else {
            return {'success': false, 'message': data['message'] ?? 'Failed to submit contribution'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to submit contribution'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Contribution Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> requestWithdrawal(int groupId, double amount, String reason) async {
    try {
      final response = await authenticatedRequest(
        'POST',
        withdrawalEndpoint,
        body: {'group_id': groupId, 'amount': amount, 'reason': reason},
      );

      print('📡 Withdrawal Response Status: ${response.statusCode}');
      print('📡 Withdrawal Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success']) {
            return {'success': true, 'message': data['message'] ?? 'Withdrawal request submitted'};
          } else {
            return {'success': false, 'message': data['message'] ?? 'Failed to submit withdrawal request'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to submit withdrawal request'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Withdrawal Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> requestLoan(int groupId, double amount, String purpose, DateTime dueDate) async {
    try {
      final response = await authenticatedRequest(
        'POST',
        loanEndpoint,
        body: {
          'group_id': groupId,
          'amount': amount,
          'purpose': purpose,
          'due_date': dueDate.toIso8601String(),
        },
      );

      print('📡 Loan Response Status: ${response.statusCode}');
      print('📡 Loan Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success']) {
            return {'success': true, 'message': data['message'] ?? 'Loan request submitted'};
          } else {
            return {'success': false, 'message': data['message'] ?? 'Failed to submit loan request'};
          }
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': false, 'message': errorData['message'] ?? 'Failed to submit loan request'};
        } catch (e) {
          print('❌ JSON Parsing Error: $e');
          return {'success': false, 'message': 'Invalid response format: ${e.toString()}'};
        }
      }
    } catch (e) {
      print('❌ Loan Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<void> logout() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        await _client.post(
          Uri.parse('$apiBaseUrl/auth/logout'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
      }
    } catch (e) {
      // Ignore errors during logout
    } finally {
      await clearAllData();
    }
  }

  static Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;
    
    if (isTokenExpired(accessToken)) {
      final refreshResult = await refreshToken();
      return refreshResult['success'] ?? false;
    }
    
    return true;
  }

  static Future<bool> isLoggedIn() async {
    return await isAuthenticated();
  }

  static Future<Map<String, dynamic>?> getAuthenticatedUser() async {
    if (await isAuthenticated()) {
      return await getUserData();
    }
    return null;
  }

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