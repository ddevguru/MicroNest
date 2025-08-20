import 'package:flutter/material.dart';
import 'package:micronest/services/blockchain_service.dart';

class GroupDetailsScreen extends StatefulWidget {
  final int groupId;
  
  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _groupDetails;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _chatMessages = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  final BlockchainService _blockchainService = BlockchainService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadGroupDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _blockchainService.dispose();
    super.dispose();
  }

  Future<void> _loadGroupDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mock data - replace with actual API calls
      await Future.delayed(const Duration(seconds: 1));
      
      _groupDetails = {
        'id': widget.groupId,
        'name': 'Monthly Savings Group',
        'description': 'Save ₹1000 every month for emergency fund',
        'group_type': 'monthly',
        'contribution_amount': '1000',
        'max_members': 20,
        'current_members': 8,
        'total_funds': '8000',
        'blockchain_address': '0x1234567890abcdef',
        'smart_contract_address': '0xabcdef1234567890',
        'created_by': 'Rahul Sharma',
        'created_at': '2025-01-01',
        'status': 'active',
      };

      _members = [
        {
          'id': 1,
          'name': 'Rahul Sharma',
          'role': 'admin',
          'total_contributed': '2000',
          'last_contribution_date': '2025-01-15',
          'trust_score': 95,
          'profile_image': null,
        },
        {
          'id': 2,
          'name': 'Priya Patel',
          'role': 'member',
          'total_contributed': '1000',
          'last_contribution_date': '2025-01-10',
          'trust_score': 88,
          'profile_image': null,
        },
        {
          'id': 3,
          'name': 'Amit Kumar',
          'role': 'member',
          'total_contributed': '1000',
          'last_contribution_date': '2025-01-12',
          'trust_score': 92,
          'profile_image': null,
        },
      ];

      _transactions = [
        {
          'id': 1,
          'type': 'contribution',
          'amount': '1000',
          'user_name': 'Priya Patel',
          'date': '2025-01-10',
          'status': 'completed',
          'blockchain_hash': '0xabc123...',
        },
        {
          'id': 2,
          'type': 'contribution',
          'amount': '1000',
          'user_name': 'Amit Kumar',
          'date': '2025-01-12',
          'status': 'completed',
          'blockchain_hash': '0xdef456...',
        },
        {
          'id': 3,
          'type': 'withdrawal',
          'amount': '500',
          'user_name': 'Rahul Sharma',
          'date': '2025-01-08',
          'status': 'completed',
          'blockchain_hash': '0xghi789...',
        },
      ];

      _chatMessages = [
        {
          'id': 1,
          'user_name': 'Rahul Sharma',
          'message': 'Welcome everyone to our new savings group!',
          'timestamp': '2025-01-01 10:00',
          'is_admin': true,
        },
        {
          'id': 2,
          'user_name': 'Priya Patel',
          'message': 'Thanks for creating this group, Rahul!',
          'timestamp': '2025-01-01 10:05',
          'is_admin': false,
        },
        {
          'id': 3,
          'user_name': 'Amit Kumar',
          'message': 'Looking forward to saving together!',
          'timestamp': '2025-01-01 10:10',
          'is_admin': false,
        },
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load group details: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupDetails?['name'] ?? 'Group Details'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroupDetails,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showGroupOptions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Members'),
            Tab(text: 'Transactions'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadGroupDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildMembersTab(),
                    _buildTransactionsTab(),
                    _buildChatTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, color: Colors.blue[600], size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _groupDetails!['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _groupDetails!['description'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Type:', _groupDetails!['group_type'].toString().toUpperCase()),
                  _buildInfoRow('Contribution:', '₹${_groupDetails!['contribution_amount']}'),
                  _buildInfoRow('Members:', '${_groupDetails!['current_members']}/${_groupDetails!['max_members']}'),
                  _buildInfoRow('Total Funds:', '₹${_groupDetails!['total_funds']}'),
                  _buildInfoRow('Created by:', _groupDetails!['created_by']),
                  _buildInfoRow('Created:', _groupDetails!['created_at']),
                  _buildInfoRow('Status:', _groupDetails!['status'].toString().toUpperCase()),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Blockchain Info Card
          if (_groupDetails!['blockchain_address'] != null) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.block, color: Colors.green[600], size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Blockchain Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildBlockchainInfoRow('Group Address:', _groupDetails!['blockchain_address']),
                    _buildBlockchainInfoRow('Smart Contract:', _groupDetails!['smart_contract_address']),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _viewOnBlockchain(_groupDetails!['blockchain_address']),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('View on Explorer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyToClipboard(_groupDetails!['blockchain_address']),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Address'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Quick Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Funds',
                  '₹${_groupDetails!['total_funds']}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Members',
                  '${_groupDetails!['current_members']}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Contribution',
                  '₹${_groupDetails!['contribution_amount']}',
                  Icons.currency_rupee,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Available Slots',
                  '${_groupDetails!['max_members'] - _groupDetails!['current_members']}',
                  Icons.event_seat,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: member['profile_image'] != null 
                  ? Colors.transparent 
                  : Colors.blue[100],
              child: member['profile_image'] != null
                  ? ClipOval(
                      child: Image.network(
                        member['profile_image'],
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, color: Colors.blue[600]);
                        },
                      ),
                    )
                  : Icon(Icons.person, color: Colors.blue[600]),
            ),
            title: Row(
              children: [
                Text(member['name']),
                if (member['role'] == 'admin') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contributed: ₹${member['total_contributed']}'),
                Text('Trust Score: ${member['trust_score']}%'),
                if (member['last_contribution_date'] != null)
                  Text('Last: ${member['last_contribution_date']}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('View Profile'),
                ),
                const PopupMenuItem(
                  value: 'transactions',
                  child: Text('View Transactions'),
                ),
                if (member['role'] != 'admin')
                  const PopupMenuItem(
                    value: 'promote',
                    child: Text('Promote to Admin'),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove Member'),
                ),
              ],
              onSelected: (value) => _handleMemberAction(value, member),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isContribution = transaction['type'] == 'contribution';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isContribution ? Colors.green[100] : Colors.red[100],
              child: Icon(
                isContribution ? Icons.add : Icons.remove,
                color: isContribution ? Colors.green[600] : Colors.red[600],
              ),
            ),
            title: Row(
              children: [
                Text(
                  isContribution ? 'Contribution' : 'Withdrawal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '₹${transaction['amount']}',
                  style: TextStyle(
                    color: isContribution ? Colors.green[600] : Colors.red[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('By: ${transaction['user_name']}'),
                Text('Date: ${transaction['date']}'),
                if (transaction['blockchain_hash'] != null)
                  Text(
                    'Hash: ${transaction['blockchain_hash']}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: transaction['status'] == 'completed' 
                    ? Colors.green[100] 
                    : Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction['status'].toString().toUpperCase(),
                style: TextStyle(
                  color: transaction['status'] == 'completed' 
                      ? Colors.green[800] 
                      : Colors.orange[800],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[index];
              final isCurrentUser = message['user_name'] == 'Rahul Sharma'; // Mock current user
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser) ...[
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(Icons.person, color: Colors.blue[600]),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isCurrentUser 
                            ? CrossAxisAlignment.end 
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isCurrentUser)
                            Text(
                              message['user_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrentUser 
                                  ? Colors.blue[600] 
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message['message'],
                              style: TextStyle(
                                color: isCurrentUser ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message['timestamp'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.blue[600],
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // Send message
                },
                icon: const Icon(Icons.send),
                color: Colors.blue[600],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildBlockchainInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Group'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit group screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Invite Members'),
              onTap: () {
                Navigator.pop(context);
                // Show invite dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Group Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Leave Group'),
              onTap: () {
                Navigator.pop(context);
                _showLeaveGroupDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Make Contribution'),
              onTap: () {
                Navigator.pop(context);
                // Show contribution dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Request Withdrawal'),
              onTap: () {
                Navigator.pop(context);
                // Show withdrawal dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Request Loan'),
              onTap: () {
                Navigator.pop(context);
                // Show loan dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(3); // Switch to chat tab
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMemberAction(String action, Map<String, dynamic> member) {
    switch (action) {
      case 'profile':
        // Navigate to member profile
        break;
      case 'transactions':
        // Show member transactions
        break;
      case 'promote':
        _showPromoteDialog(member);
        break;
      case 'remove':
        _showRemoveDialog(member);
        break;
    }
  }

  void _showPromoteDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote Member'),
        content: Text('Are you sure you want to promote ${member['name']} to admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle promotion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member['name']} promoted to admin')),
              );
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member['name']} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle removal
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member['name']} removed from group')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group? You will lose access to all group features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to groups screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You have left the group')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _viewOnBlockchain(String address) {
    // Open blockchain explorer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening blockchain explorer for $address')),
    );
  }

  void _copyToClipboard(String text) {
    // Copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
  }
} 