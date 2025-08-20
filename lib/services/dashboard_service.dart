import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:micronest/services/auth_service.dart';

class DashboardService {
  static const String baseUrl = 'https://micronest.devloperwala.in/micronest/backend/api';
  static const String dashboardEndpoint = '/dashboard.php';
  
  static final http.Client _client = http.Client();

  // Get dashboard data (wallet + groups)
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      // Get access token
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token found. Please login again.',
        };
      }

      final url = '$baseUrl$dashboardEndpoint';
      print('📊 Dashboard URL: $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Dashboard Response Status: ${response.statusCode}');
      print('📡 Dashboard Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'],
            'wallet': data['data']['wallet'],
            'groups': data['data']['groups'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to get dashboard data',
          };
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
          'tokenExpired': true,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get dashboard data. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Dashboard Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get wallet data only
  static Future<Map<String, dynamic>> getWalletData() async {
    final result = await getDashboardData();
    if (result['success']) {
      return {
        'success': true,
        'wallet': result['wallet'],
      };
    }
    return result;
  }

  // Get groups data only
  static Future<Map<String, dynamic>> getGroupsData() async {
    final result = await getDashboardData();
    if (result['success']) {
      return {
        'success': true,
        'groups': result['groups'],
      };
    }
    return result;
  }

  // Format currency for Indian Rupees
  static String formatCurrency(double amount) {
    if (amount < 0) {
      return '-₹${amount.abs().toStringAsFixed(2)}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Format large numbers with K, L, Cr
  static String formatLargeCurrency(double amount) {
    if (amount >= 10000000) { // 1 Crore
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) { // 1 Lakh
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) { // 1 Thousand
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return formatCurrency(amount);
    }
  }

  // Calculate trust score color
  static int getTrustScoreColor(double trustScore) {
    if (trustScore >= 80) return 0xFF4CAF50; // Green
    if (trustScore >= 60) return 0xFFFF9800; // Orange
    if (trustScore >= 40) return 0xFFFF5722; // Red
    return 0xFF9E9E9E; // Grey
  }

  // Get trust score text
  static String getTrustScoreText(double trustScore) {
    if (trustScore >= 80) return 'Excellent';
    if (trustScore >= 60) return 'Good';
    if (trustScore >= 40) return 'Fair';
    return 'Poor';
  }
} 