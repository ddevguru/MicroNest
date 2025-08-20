import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProfileService {
  static const String baseUrl = 'https://micronest.devloperwala.in';
  static const String apiBaseUrl = '$baseUrl/api';
  
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
        final data = json.decode(response.body);
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
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.put(
        Uri.parse('$apiBaseUrl/profile/notifications'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(settings),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          // Retry with new token
          return await updateNotificationSettings(settings);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to update notification settings: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update security settings
  static Future<Map<String, dynamic>> updateSecuritySettings(Map<String, dynamic> settings) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.put(
        Uri.parse('$apiBaseUrl/profile/security'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(settings),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          // Retry with new token
          return await updateSecuritySettings(settings);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to update security settings: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get trust score details
  static Future<Map<String, dynamic>> getTrustScoreDetails() async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/profile/trust-score'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          // Retry with new token
          return await getTrustScoreDetails();
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load trust score: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get awards and achievements
  static Future<Map<String, dynamic>> getAwardsAndAchievements() async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/profile/awards'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          // Retry with new token
          return await getAwardsAndAchievements();
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load awards: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
} 