import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:micronest/services/auth_service.dart';
import 'package:micronest/services/blockchain_service.dart';

class GroupService {
  static const String baseUrl = 'https://micronest.devloperwala.in';
  static const String apiBaseUrl = '$baseUrl/micronest/backend/api';
  
  static final http.Client _client = http.Client();
  static final BlockchainService _blockchainService = BlockchainService();

  // Get user's groups
  static Future<Map<String, dynamic>> getUserGroups() async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/groups?action=list'),
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
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await getUserGroups();
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load groups: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get available groups to join
  static Future<Map<String, dynamic>> getAvailableGroups() async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/groups?action=available'),
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
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await getAvailableGroups();
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load available groups: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Create a new group
  static Future<Map<String, dynamic>> createGroup(Map<String, dynamic> groupData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=create'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(groupData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await createGroup(groupData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to create group: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Join a group
  static Future<Map<String, dynamic>> joinGroup(int groupId, {String? paymentMethod}) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final data = {
        'group_id': groupId,
        'payment_method': paymentMethod ?? 'cash',
      };

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=join'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'data': result,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await joinGroup(groupId, paymentMethod: paymentMethod);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to join group: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Join group using blockchain
  static Future<Map<String, dynamic>> joinGroupBlockchain(int groupId, String amount) async {
    try {
      // First join the group in the database
      final joinResult = await joinGroup(groupId, paymentMethod: 'blockchain');
      if (!joinResult['success']) {
        return joinResult;
      }

      // Then interact with blockchain
      final blockchainResult = await _blockchainService.joinGroup(
        '0x${groupId.toString().padLeft(40, '0')}', // Mock contract address
        amount,
      );

      if (blockchainResult['success']) {
        return {
          'success': true,
          'message': 'Successfully joined group on blockchain',
          'transaction_hash': blockchainResult['transaction_hash'],
          'data': joinResult['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Joined group but blockchain transaction failed: ${blockchainResult['message']}',
          'data': joinResult['data'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to join group: ${e.toString()}',
      };
    }
  }

  // Leave a group
  static Future<Map<String, dynamic>> leaveGroup(int groupId) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final data = {'group_id': groupId};

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=leave'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'data': result,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await leaveGroup(groupId);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to leave group: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get group details
  static Future<Map<String, dynamic>> getGroupDetails(int groupId) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/groups?action=details&group_id=$groupId'),
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
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await getGroupDetails(groupId);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load group details: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get group members
  static Future<Map<String, dynamic>> getGroupMembers(int groupId) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/groups?action=members&group_id=$groupId'),
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
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await getGroupMembers(groupId);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load group members: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Make a contribution
  static Future<Map<String, dynamic>> makeContribution(Map<String, dynamic> contributionData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=contribute'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(contributionData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await makeContribution(contributionData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to make contribution: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Make blockchain contribution
  static Future<Map<String, dynamic>> makeBlockchainContribution(
    int groupId, 
    String amount,
    String contributionDate,
  ) async {
    try {
      // First record contribution in database
      final contributionData = {
        'group_id': groupId,
        'amount': amount,
        'contribution_date': contributionDate,
        'payment_method': 'blockchain',
      };

      final dbResult = await makeContribution(contributionData);
      if (!dbResult['success']) {
        return dbResult;
      }

      // Then interact with blockchain
      final blockchainResult = await _blockchainService.makeContribution(
        '0x${groupId.toString().padLeft(40, '0')}', // Mock contract address
        amount,
      );

      if (blockchainResult['success']) {
        return {
          'success': true,
          'message': 'Contribution recorded successfully on blockchain',
          'transaction_hash': blockchainResult['transaction_hash'],
          'data': dbResult['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Contribution recorded but blockchain transaction failed: ${blockchainResult['message']}',
          'data': dbResult['data'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to make contribution: ${e.toString()}',
      };
    }
  }

  // Request withdrawal
  static Future<Map<String, dynamic>> requestWithdrawal(Map<String, dynamic> withdrawalData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=withdraw'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(withdrawalData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await requestWithdrawal(withdrawalData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to request withdrawal: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Request deposit
  static Future<Map<String, dynamic>> requestDeposit(Map<String, dynamic> depositData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=deposit'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(depositData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await requestDeposit(depositData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to request deposit: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Request loan
  static Future<Map<String, dynamic>> requestLoan(Map<String, dynamic> loanData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=request-loan'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(loanData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await requestLoan(loanData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to request loan: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get group loans
  static Future<Map<String, dynamic>> getGroupLoans(int groupId) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/groups?action=loans&group_id=$groupId'),
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
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await getGroupLoans(groupId);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load group loans: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user loans
  static Future<Map<String, dynamic>> getUserLoans() async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/groups?action=loans'),
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
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await getUserLoans();
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load user loans: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get group transactions
  static Future<Map<String, dynamic>> getGroupTransactions(int groupId) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/groups?action=transactions&group_id=$groupId'),
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
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await getGroupTransactions(groupId);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load group transactions: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user transactions
  static Future<Map<String, dynamic>> getUserTransactions() async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/groups?action=transactions'),
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
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await getUserTransactions();
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load user transactions: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get group chat
  static Future<Map<String, dynamic>> getGroupChat(int groupId) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.get(
        Uri.parse('$apiBaseUrl/groups?action=chat&group_id=$groupId'),
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
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await getGroupChat(groupId);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load group chat: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Send message to group chat
  static Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> messageData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=chat'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(messageData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await sendMessage(messageData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to send message: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Approve contribution (admin only)
  static Future<Map<String, dynamic>> approveContribution(Map<String, dynamic> approvalData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=approve-contribution'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(approvalData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await approveContribution(approvalData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to approve contribution: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Approve withdrawal (admin only)
  static Future<Map<String, dynamic>> approveWithdrawal(Map<String, dynamic> approvalData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=approve-withdrawal'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(approvalData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await approveWithdrawal(approvalData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to approve withdrawal: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Approve loan (admin only)
  static Future<Map<String, dynamic>> approveLoan(Map<String, dynamic> approvalData) async {
    try {
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'No access token available',
        };
      }

      final response = await _client.post(
        Uri.parse('$apiBaseUrl/groups?action=approve-loan'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(approvalData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshToken();
        if (refreshResult['success'] == true) {
          return await approveLoan(approvalData);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to approve loan: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Dispose resources
  static void dispose() {
    _client.close();
    _blockchainService.dispose();
  }
} 