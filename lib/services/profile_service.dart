import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProfileService {
  static const String baseUrl = 'https://micronest.devloperwala.in';
  static const String apiBaseUrl = '$baseUrl/micronest/backend/api';
  
  // HTTP client
  static final http.Client _client = http.Client();

  // Get complete profile data
  static Future<Map<String, dynamic>> getProfileData() async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          // Retry with new token
          return await getProfileData();
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load profile data: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update profile information
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.put(
        Uri.parse('$apiBaseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          // Retry with new token
          return await updateProfile(profileData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to update profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update notification settings
  static Future<Map<String, dynamic>> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token available'};
      }

      final response = await _client.put(
        Uri.parse('$apiBaseUrl/profile/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(settings),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'success': false, 'message': 'Failed to update notification settings: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error updating notification settings: $e'};
    }
  }

  // Update security settings
  static Future<Map<String, dynamic>> updateSecuritySettings(Map<String, dynamic> settings) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token available'};
      }

      final response = await _client.put(
        Uri.parse('$apiBaseUrl/profile/security'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(settings),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'success': false, 'message': 'Failed to update security settings: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error updating security settings: $e'};
    }
  }

  // Get trust score details
  static Future<Map<String, dynamic>> getTrustScoreDetails() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token available'};
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/profile/trust-score'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'success': false, 'message': 'Failed to fetch trust score: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error fetching trust score: $e'};
    }
  }

  // Get awards and achievements
  static Future<Map<String, dynamic>> getAwardsAndAchievements() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token available'};
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/profile/awards'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'success': false, 'message': 'Failed to fetch awards: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error fetching awards: $e'};
    }
  }

  // PIN Management Methods
  static Future<Map<String, dynamic>> setPin(String pin) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token available'};
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/profile/pin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'pin': pin}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'success': false, 'message': 'Failed to set PIN: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error setting PIN: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePin(String currentPin, String newPin) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token available'};
      }

      final response = await _client.put(
        Uri.parse('$apiBaseUrl/profile/pin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_pin': currentPin,
          'new_pin': newPin,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'success': false, 'message': 'Failed to update PIN: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error updating PIN: $e'};
    }
  }

  static Future<Map<String, dynamic>> removePin() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token available'};
      }

      final response = await _client.delete(
        Uri.parse('$apiBaseUrl/profile/pin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'success': false, 'message': 'Failed to remove PIN: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error removing PIN: $e'};
    }
  }

  static Future<bool> isPinSet() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        return false;
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['security']?['pin_enabled'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN
  static Future<bool> verifyPin(String pin) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        return false;
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/profile/verify-pin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'pin': pin}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
} 