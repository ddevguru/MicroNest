import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:micronest/services/auth_service.dart';

class DashboardService {
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

  // Placeholder for dashboard data (to be implemented based on backend)
  static Future<Map<String, dynamic>> getDashboardData() async {
    // Since no dashboard.php exists, use getUserGroups as a fallback
    final groupsResult = await AuthService.getUserGroups();
    if (groupsResult['success']) {
      return {
        'success': true,
        'message': 'Dashboard data fetched (groups only)',
        'groups': groupsResult['groups'],
      };
    }
    return {'success': false, 'message': groupsResult['message']};
  }

  // Get wallet data (to be implemented if backend provides a wallet endpoint)
  static Future<Map<String, dynamic>> getWalletData() async {
    return {'success': false, 'message': 'Wallet data not implemented'};
  }

  // Get groups data
  static Future<Map<String, dynamic>> getGroupsData() async {
    final result = await AuthService.getUserGroups();
    if (result['success']) {
      return {
        'success': true,
        'groups': result['groups'],
      };
    }
    return result;
  }
}