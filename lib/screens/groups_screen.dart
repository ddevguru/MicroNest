import 'package:flutter/material.dart';
import 'package:micronest/services/auth_service.dart';
import 'package:micronest/screens/create_group_screen.dart';
import 'package:micronest/screens/group_details_screen.dart';
import 'package:micronest/screens/join_group_screen.dart';
import 'package:micronest/screens/group_chat_screen.dart';

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

  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _loadGroups();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController!, curve: Curves.easeOut),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController?.forward();
    _slideController?.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userGroupsResult = await AuthService.getUserGroups();
      final availableGroupsResult = await AuthService.getAvailableGroups();

      setState(() {
        if (userGroupsResult['success']) {
          _userGroups = List<Map<String, dynamic>>.from(userGroupsResult['groups']);
        } else {
          _errorMessage = userGroupsResult['message'];
        }

        if (availableGroupsResult['success']) {
          _availableGroups = List<Map<String, dynamic>>.from(availableGroupsResult['groups']);
        } else {
          _errorMessage = _errorMessage ?? availableGroupsResult['message'];
        }

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF1B4332),
              Color(0xFF081C15),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            CustomPaint(painter: BackgroundPainter()),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Groups',
                          style: TextStyle(
                            fontSize: 28 * MediaQuery.of(context).textScaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadGroups,
                        ),
                      ],
                    ),
                  ),
                  // TabBar
                  Container(
                    color: Colors.white.withOpacity(0.1),
                    child: TabBar(
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
                  // TabBarView
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF52B788),
                              strokeWidth: 3,
                            ),
                          )
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[600],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : FadeTransition(
                                opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
                                child: SlideTransition(
                                  position: _slideAnimation ?? AlwaysStoppedAnimation(Offset.zero),
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildMyGroupsTab(),
                                      _buildJoinGroupsTab(),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          ).then((_) => _loadGroups());
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Group', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    if (_userGroups.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_add, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                'No Groups Yet',
                style: TextStyle(
                  fontSize: 20 * MediaQuery.of(context).textScaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join or create your first group',
                style: TextStyle(
                  fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.group_add, color: Colors.white),
                label: const Text('Browse Groups', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
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
    final isFull = int.parse(group['current_members'].toString()) >= int.parse(group['max_members'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(groupId: int.parse(group['id'].toString())),
            ),
          ).then((_) => _loadGroups());
        },
        borderRadius: BorderRadius.circular(20),
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
                        style: TextStyle(
                          fontSize: 18 * MediaQuery.of(context).textScaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group['description'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14 * MediaQuery.of(context).textScaleFactor,
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
                        fontSize: 12 * MediaQuery.of(context).textScaleFactor,
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
                    label: '₹${group['total_contributed'] ?? 0}',
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
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12 * MediaQuery.of(context).textScaleFactor,
                ),
              ),
            ],
            if (!isUserGroup) ...[
              const SizedBox(height: 12),
              Text(
                'Created by: ${group['created_by_name'] ?? 'Unknown'}', // Show name instead of ID
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12 * MediaQuery.of(context).textScaleFactor,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isFull
                        ? null
                        : () {
                            if (isUserGroup) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupDetailsScreen(groupId: int.parse(group['id'].toString())),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isUserGroup ? 'View Details' : 'Join Group'),
                  ),
                ),
                if (isUserGroup) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _showGroupActions(context, group),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Actions', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ],
            ),
          ],
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
              fontSize: 12 * MediaQuery.of(context).textScaleFactor,
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
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.white),
              title: const Text('Make Contribution', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showContributionDialog(context, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.white),
              title: const Text('Request Withdrawal', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showWithdrawalDialog(context, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.white),
              title: const Text('Request Loan', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showLoanDialog(context, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              title: const Text('Group Chat', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupChatScreen(
                      groupId: int.parse(group['id'].toString()),
                      groupName: group['name'],
                    ),
                  ),
                );
              },
            ),
            if (group['role'] == 'admin') ...[
              const Divider(color: Colors.white30),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.white),
                title: const Text('Manage Group', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group management coming soon')));
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
    String selectedPaymentMethod = 'cash';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Make Contribution', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Group: ${group['name']}', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF52B788)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPaymentMethod,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Payment Method',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'razorpay', child: Text('Razorpay', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (value) {
                selectedPaymentMethod = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  Navigator.pop(context);
                  await _makeContribution(context, group, amount, selectedPaymentMethod);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF52B788),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Contribute', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _makeContribution(BuildContext context, Map<String, dynamic> group, double amount, String paymentMethod) async {
    try {
      final result = await AuthService.makeContribution(
        group['id'].toString(),
        amount,
        paymentMethod,
      );
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution made successfully')),
        );
        _loadGroups(); // Reload all groups to update contribution count
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to make contribution: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showWithdrawalDialog(BuildContext context, Map<String, dynamic> group) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Withdrawal', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Group: ${group['name']}', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Purpose',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty && reasonController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  Navigator.pop(context);
                  await _requestWithdrawal(context, group, amount, reasonController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF52B788),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestWithdrawal(BuildContext context, Map<String, dynamic> group, double amount, String purpose) async {
    try {
      final result = await AuthService.requestWithdrawal(
        group['id'].toString(),
        amount,
        purpose,
      );
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal request submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit withdrawal request: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showLoanDialog(BuildContext context, Map<String, dynamic> group) {
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    final repaymentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Loan', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Group: ${group['name']}', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: purposeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Purpose',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repaymentController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Repayment Period (months)',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty && purposeController.text.isNotEmpty && repaymentController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text);
                final repaymentPeriod = int.tryParse(repaymentController.text) ?? 0;
                if (amount != null && amount > 0 && repaymentPeriod > 0) {
                  Navigator.pop(context);
                  await _requestLoan(context, group, amount, purposeController.text, repaymentPeriod);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid amount and repayment period')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF52B788),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLoan(BuildContext context, Map<String, dynamic> group, double amount, String purpose, int repaymentPeriod) async {
    try {
      final result = await AuthService.requestLoan(
        group['id'].toString(),
        amount,
        purpose,
        repaymentPeriod,
      );
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan request submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit loan request: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.4,
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final circlePaint = Paint()
      ..color = const Color(0xFF52B788).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 40, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.6), 30, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}