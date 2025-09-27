import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:micronest/services/auth_service.dart';

class ChatService {
  static const String apiBaseUrl = 'https://micronest.devloperwala.in/api';

  static Future<Map<String, dynamic>> getMessages(int groupId) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/chat/messages?group_id=$groupId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': data['success'],
          'messages': data['data'] ?? [],
          'message': data['message'] ?? 'Messages fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch messages',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> sendMessage(int groupId, String message) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/chat/send',
        body: {
          'group_id': groupId,
          'message': message,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': data['success'],
          'message': data['data'],
          'error': data['message'] ?? 'Message sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send message',
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