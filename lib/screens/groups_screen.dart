import 'package:flutter/material.dart';
import 'package:micronest/services/auth_service.dart';
import 'package:micronest/services/profile_service.dart';
import 'package:micronest/screens/create_group_screen.dart';
import 'package:micronest/screens/group_details_screen.dart';
import 'package:micronest/screens/join_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _userGroups = [];
  List<Map<String, dynamic>> _availableGroups = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user's groups
      final userGroupsResult = await ProfileService.getProfileData();
      if (userGroupsResult['success'] == true) {
        // This would be replaced with actual groups API call
        _userGroups = [
          {
            'id': 1,
            'name': 'Monthly Savings Group',
            'description': 'Save ₹1000 every month',
            'contribution_amount': '1000',
            'current_members': 8,
            'max_members': 20,
            'total_funds': '8000',
            'role': 'admin',
            'total_contributed': '2000',
            'last_contribution_date': '2025-01-15',
          },
          {
            'id': 2,
            'name': 'Weekly Investment Club',
            'description': 'Invest ₹500 weekly in mutual funds',
            'contribution_amount': '500',
            'current_members': 15,
            'max_members': 25,
            'role': 'member',
            'total_contributed': '1500',
            'last_contribution_date': '2025-01-20',
          },
        ];
      }

      // Load available groups to join
      _availableGroups = [
        {
          'id': 3,
          'name': 'Daily Savings Challenge',
          'description': 'Save ₹100 daily for 30 days',
          'contribution_amount': '100',
          'current_members': 12,
          'max_members': 30,
          'creator_name': 'Rahul Sharma',
        },
        {
          'id': 4,
          'name': 'Emergency Fund Group',
          'description': 'Build emergency fund together',
          'contribution_amount': '2000',
          'current_members': 5,
          'max_members': 15,
          'creator_name': 'Priya Patel',
        },
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load groups: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Join Groups'),
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
                        onPressed: _loadGroups,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyGroupsTab(),
                    _buildJoinGroupsTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateGroupScreen(),
            ),
          ).then((_) => _loadGroups());
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    if (_userGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'You haven\'t joined any groups yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join existing groups or create your own',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.group_add),
              label: const Text('Browse Groups'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userGroups.length,
        itemBuilder: (context, index) {
          final group = _userGroups[index];
          return _buildGroupCard(group, isUserGroup: true);
        },
      ),
    );
  }

  Widget _buildJoinGroupsTab() {
    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableGroups.length,
        itemBuilder: (context, index) {
          final group = _availableGroups[index];
          return _buildGroupCard(group, isUserGroup: false);
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, {required bool isUserGroup}) {
    final isAdmin = group['role'] == 'admin';
    final isFull = group['current_members'] >= group['max_members'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(groupId: group['id']),
            ),
          ).then((_) => _loadGroups());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUserGroup && isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${group['current_members']}/${group['max_members']}',
                    color: isFull ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    icon: Icons.currency_rupee,
                    label: '₹${group['contribution_amount']}',
                    color: Colors.blue,
                  ),
                  if (isUserGroup) ...[
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      icon: Icons.account_balance_wallet,
                      label: '₹${group['total_contributed']}',
                      color: Colors.orange,
                    ),
                  ],
                ],
              ),
              if (isUserGroup && group['last_contribution_date'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Last contribution: ${group['last_contribution_date']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
              if (!isUserGroup) ...[
                const SizedBox(height: 12),
                Text(
                  'Created by: ${group['creator_name']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isFull ? null : () {
                        if (isUserGroup) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupDetailsScreen(groupId: group['id']),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoinGroupScreen(group: group),
                            ),
                          ).then((_) => _loadGroups());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUserGroup ? Colors.blue[600] : Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isUserGroup ? 'View Details' : 'Join Group',
                      ),
                    ),
                  ),
                  if (isUserGroup) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        _showGroupActions(context, group);
                      },
                      child: const Text('Actions'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupActions(BuildContext context, Map<String, dynamic> group) {
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
                _showContributionDialog(context, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Request Withdrawal'),
              onTap: () {
                Navigator.pop(context);
                _showWithdrawalDialog(context, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Request Loan'),
              onTap: () {
                Navigator.pop(context);
                _showLoanDialog(context, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Group Chat'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to group chat
              },
            ),
            if (group['role'] == 'admin') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Manage Group'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to group management
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContributionDialog(BuildContext context, Map<String, dynamic> group) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Group: ${group['name']}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle contribution
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contribution submitted successfully')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalDialog(BuildContext context, Map<String, dynamic> group) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available: ₹${group['total_contributed']}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle withdrawal request
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal request submitted')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showLoanDialog(BuildContext context, Map<String, dynamic> group) {
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    DateTime? selectedDate;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Group: ${group['name']}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(selectedDate?.toString().split(' ')[0] ?? 'Select Due Date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  selectedDate = date;
                  setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle loan request
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loan request submitted')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
} 