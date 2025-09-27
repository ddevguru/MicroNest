import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:micronest/services/auth_service.dart';

class GroupService {
  static const String apiBaseUrl = 'https://micronest.devloperwala.in/api';

  // Get user's groups (using AuthService endpoint)
  static Future<Map<String, dynamic>> getUserGroups() async {
    return await AuthService.getUserGroups();
  }

  // Get available groups to join
  static Future<Map<String, dynamic>> getAvailableGroups() async {
    return await AuthService.getAvailableGroups();
  }

  // Create a new group
  static Future<Map<String, dynamic>> createGroup(Map<String, dynamic> groupData) async {
    return await AuthService.createGroup(groupData);
  }

  // Join a group
  static Future<Map<String, dynamic>> joinGroup(int groupId, double amount, String paymentMethod) async {
    return await AuthService.joinGroup(groupId, amount, paymentMethod);
  }

  // Make a contribution to a group
  static Future<Map<String, dynamic>> makeContribution(String groupId, double amount, String paymentMethod) async {
    return await AuthService.makeContribution(groupId, amount, paymentMethod);
  }

  // Request withdrawal from a group
  static Future<Map<String, dynamic>> requestWithdrawal(String groupId, double amount, String purpose) async {
    return await AuthService.requestWithdrawal(groupId, amount, purpose);
  }

  // Request loan from a group
  static Future<Map<String, dynamic>> requestLoan(String groupId, double amount, String purpose, int repaymentPeriod) async {
    return await AuthService.requestLoan(groupId, amount, purpose, repaymentPeriod);
  }

  // Get group details
  static Future<Map<String, dynamic>> getGroupDetails(int groupId) async {
    return await AuthService.getGroupDetails(groupId);
  }
}