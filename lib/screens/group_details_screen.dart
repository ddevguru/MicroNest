import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:micronest/services/auth_service.dart';

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
    _loadGroupDetails();
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

  Future<void> _loadGroupDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.getGroupDetails(widget.groupId);
      if (result['success']) {
        setState(() {
          _groupDetails = result['group'];
          _members = List<Map<String, dynamic>>.from(result['members']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load group details: $e';
      });
    }
  }

  void _showGroupOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF081C15),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.white70),
            title: const Text('Leave Group', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              _leaveGroup();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.white70),
            title: const Text('Refresh', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _loadGroupDetails();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      final result = await AuthService.leaveGroup(widget.groupId);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully left the group')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave group: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                          _groupDetails?['name'] ?? 'Group Details',
                          style: TextStyle(
                            fontSize: 28 * MediaQuery.of(context).textScaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              onPressed: _loadGroupDetails,
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              onPressed: _showGroupOptions,
                            ),
                          ],
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
                        Tab(text: 'Overview'),
                        Tab(text: 'Members'),
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
                                      onPressed: _loadGroupDetails,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF52B788),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
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
                                      // Overview Tab
                                      SingleChildScrollView(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoCard('Group Name', _groupDetails?['name'] ?? 'N/A'),
                                            _buildInfoCard('Description', _groupDetails?['description'] ?? 'No description'),
                                            _buildInfoCard('Contribution Amount', '₹${_groupDetails?['contribution_amount'] ?? 0.00}'),
                                            _buildInfoCard('Total Funds', '₹${_groupDetails?['total_funds'] ?? 0.00}'),
                                            _buildInfoCard('Members', '${_groupDetails?['current_members'] ?? 0}/${_groupDetails?['max_members'] ?? 0}'),
                                            _buildInfoCard('Status', _groupDetails?['status'] ?? 'N/A'),
                                            _buildInfoCard('Created By', _groupDetails?['created_by_name'] ?? 'N/A'),
                                            _buildInfoCard('Created At', _groupDetails?['created_at']?.substring(0, 10) ?? 'N/A'),
                                          ],
                                        ),
                                      ),
                                      // Members Tab
                                      _members.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No members found',
                                                style: TextStyle(color: Colors.white70, fontSize: 16),
                                              ),
                                            )
                                          : ListView.builder(
                                              padding: const EdgeInsets.all(20),
                                              itemCount: _members.length,
                                              itemBuilder: (context, index) {
                                                final member = _members[index];
                                                return Card(
                                                  color: Colors.white.withOpacity(0.1),
                                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor: const Color(0xFF52B788),
                                                      child: Text(
                                                        member['full_name']?.substring(0, 1) ?? 'U',
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                    ),
                                                    title: Text(
                                                      member['full_name'] ?? 'Unknown',
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                    subtitle: Text(
                                                      'Role: ${member['role']}\nContributed: ₹${member['total_contributed'] ?? 0.00}',
                                                      style: const TextStyle(color: Colors.white70),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
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
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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