import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:micronest/services/auth_service.dart';
import 'package:micronest/services/dashboard_service.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

// Material Icons Used for Better Diversity and Reliability:
// - Groups: Icons.group_work (Team/Group icon)
// - Loans: Icons.attach_money (Money/Loan icon)
// - Withdraw: Icons.file_download (Download/Transfer icon)
// - Transactions: Icons.bar_chart (Chart/Graph icon)
// - Notifications: Icons.notifications (Bell/Notification icon)
// - Settings: Icons.settings (Gear/Settings icon)
// - Empty State: Icons.group_add (Add Group icon)
// - Loading State: CircularProgressIndicator (Loading animation)
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with TickerProviderStateMixin {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? walletData;
  List<dynamic>? groupsData;
  bool isLoading = true;
  bool isBalanceVisible = true;
  
  // Animation controllers
  AnimationController? _glowController;
  AnimationController? _pulseController;
  AnimationController? _slideController;
  AnimationController? _fadeController;
  AnimationController? _bounceController;
  
  Animation<double>? _glowAnimation;
  Animation<double>? _pulseAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;
  Animation<double>? _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    
    // Start animations with delays for smooth entrance
    _startEntranceAnimations();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController!,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController!,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController!,
      curve: Curves.bounceOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _glowController?.repeat(reverse: true);
    _pulseController?.repeat(reverse: true);
    _slideController?.forward();
    _fadeController?.forward();
    _bounceController?.forward();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load user data
      final userResult = await AuthService.getUserData();
      
      // Load dashboard data
      final dashboardResult = await DashboardService.getDashboardData();
      
      if (mounted) {
        setState(() {
          userData = userResult;
          if (dashboardResult['success']) {
            walletData = dashboardResult['wallet'];
            groupsData = dashboardResult['groups'] ?? [];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _startEntranceAnimations() async {
    // Staggered entrance animations
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController?.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController?.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _glowController?.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _pulseController?.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _bounceController?.forward();
  }

  @override
  void dispose() {
    _glowController?.dispose();
    _pulseController?.dispose();
    _slideController?.dispose();
    _fadeController?.dispose();
    _bounceController?.dispose();
    super.dispose();
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
              Color(0xFF1B4332), // Dark forest green
              Color(0xFF081C15), // Very dark green
              Color(0xFF000000), // Black
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background with organic shapes and flowing elements
            _buildSafeBackground(),
            
            // Main content
            SafeArea(
              child: isLoading 
                ? _buildLoadingState()
                : Column(
                    children: [
                      // Header with greeting, name, and icons
                      _buildHeader(),
                      
                      // Main content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              
                              // Wallet Balance Card
                              _buildWalletCard(),
                              const SizedBox(height: 30),
                              
                              // Quick Actions
                              _buildQuickActions(),
                              const SizedBox(height: 30),
                              
                              // Groups Section
                              _buildGroupsSection(),
                              const SizedBox(height: 30),
                            ],
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF52B788),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your dashboard...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundPainter(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Left side - Greeting and Name
          Expanded(
            child: _slideAnimation != null && _fadeAnimation != null
                ? SlideTransition(
                    position: _slideAnimation!,
                    child: FadeTransition(
                      opacity: _fadeAnimation!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userData?['full_name'] ?? 'User',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userData?['full_name'] ?? 'User',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
          
          // Right side - Notification and Settings Icons
          Row(
            children: [
              // Notification Icon with Animation
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: _glowAnimation != null
                    ? AnimatedBuilder(
                        animation: _glowAnimation!,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _glowAnimation!.value * 2),
                            child: IconButton(
                              onPressed: () {
                                // Handle notification tap
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notifications coming soon!'),
                                    backgroundColor: Color(0xFF52B788),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      )
                    : IconButton(
                        onPressed: () {
                          // Handle notification tap
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications coming soon!'),
                              backgroundColor: Color(0xFF52B788),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // Settings Icon with Animation
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: _glowAnimation != null
                    ? AnimatedBuilder(
                        animation: _glowAnimation!,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _glowAnimation!.value * 2),
                            child: IconButton(
                              onPressed: () {
                                // Navigate to profile screen
                                Navigator.pushNamed(context, '/profile');
                              },
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      )
                    : IconButton(
                        onPressed: () {
                          // Navigate to profile screen
                          Navigator.pushNamed(context, '/profile');
                        },
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    final balance = walletData?['net_balance'] ?? 0.0;
    final trustScore = walletData?['trust_score'] ?? 0.0;
    
    if (_slideAnimation == null || _fadeAnimation == null || _glowAnimation == null) {
      return _buildWalletCardWithoutAnimation(balance, trustScore);
    }
    
    return SlideTransition(
      position: _slideAnimation!,
      child: FadeTransition(
        opacity: _fadeAnimation!,
        child: _pulseAnimation != null
            ? AnimatedBuilder(
                animation: _pulseAnimation!,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.98 + (_pulseAnimation!.value * 0.02),
                    child: _buildWalletCardContent(balance, trustScore),
                  );
                },
              )
            : _buildWalletCardContent(balance, trustScore),
      ),
    );
  }

  Widget _buildWalletCardWithoutAnimation(double balance, double trustScore) {
    return _buildWalletCardContent(balance, trustScore);
  }

  Widget _buildWalletCardContent(double balance, double trustScore) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF52B788).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF52B788),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF52B788).withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    isBalanceVisible = !isBalanceVisible;
                  });
                },
                icon: Icon(
                  isBalanceVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isBalanceVisible 
              ? DashboardService.formatLargeCurrency(balance)
              : '****',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: const Color(0xFF52B788).withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: const Color(0xFFFFD700),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Trust Score: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(DashboardService.getTrustScoreColor(trustScore)).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(DashboardService.getTrustScoreColor(trustScore)).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${trustScore.toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(DashboardService.getTrustScoreColor(trustScore)),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: const Color(0xFF4CAF50),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+12.5%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    if (_slideAnimation == null || _fadeAnimation == null) {
      return _buildQuickActionsWithoutAnimation();
    }
    
    return SlideTransition(
      position: _slideAnimation!,
      child: FadeTransition(
        opacity: _fadeAnimation!,
        child: _buildQuickActionsContent(),
      ),
    );
  }

  Widget _buildQuickActionsWithoutAnimation() {
    return _buildQuickActionsContent();
  }

  Widget _buildQuickActionsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _fadeAnimation != null
                ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionButton(
              icon: Icons.group_work,
              title: 'Join/Create\nGroup',
              color: const Color(0xFF52B788).withOpacity(0.2),
              iconColor: const Color(0xFF52B788),
            ),
            _buildActionButton(
              icon: Icons.attach_money,
              title: 'Request\nLoan',
              color: const Color(0xFFFF9800).withOpacity(0.2),
              iconColor: const Color(0xFFFF9800),
            ),
            _buildActionButton(
              icon: Icons.file_download,
              title: 'Withdraw\nFunds',
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              iconColor: const Color(0xFF4CAF50),
            ),
            _buildActionButton(
              icon: Icons.bar_chart,
              title: 'View\nTransactions',
              color: const Color(0xFF9C27B0).withOpacity(0.2),
              iconColor: const Color(0xFF9C27B0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
  }) {
    if (_bounceAnimation == null) {
      return _buildActionButtonWithoutAnimation(icon, title, color, iconColor);
    }
    
    return AnimatedBuilder(
      animation: _bounceAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation!.value,
          child: _buildActionButtonContent(icon, title, color, iconColor),
        );
      },
    );
  }

  Widget _buildActionButtonWithoutAnimation(IconData icon, String title, Color color, Color iconColor) {
    return _buildActionButtonContent(icon, title, color, iconColor);
  }

  Widget _buildActionButtonContent(IconData icon, String title, Color color, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Add subtle tap animation and haptic feedback
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(20),
          onHover: (isHovered) {
            // Add hover effect if needed
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsSection() {
    if (groupsData == null || groupsData!.isEmpty) {
      return _buildEmptyGroupsState();
    }

    if (_slideAnimation == null || _fadeAnimation == null) {
      return _buildGroupsSectionWithoutAnimation();
    }

    return SlideTransition(
      position: _slideAnimation!,
      child: FadeTransition(
        opacity: _fadeAnimation!,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          child: _buildGroupsSectionContent(),
        ),
      ),
    );
  }

  Widget _buildGroupsSectionWithoutAnimation() {
    return _buildGroupsSectionContent();
  }

  Widget _buildGroupsSectionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your Groups',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF52B788),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF52B788).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...groupsData!.map((group) => _buildGroupCard(group)).toList(),
      ],
    );
  }

  Widget _buildEmptyGroupsState() {
    if (_slideAnimation == null || _fadeAnimation == null) {
      return _buildEmptyGroupsStateWithoutAnimation();
    }

    return SlideTransition(
      position: _slideAnimation!,
      child: FadeTransition(
        opacity: _fadeAnimation!,
        child: _buildEmptyGroupsStateContent(),
      ),
    );
  }

  Widget _buildEmptyGroupsStateWithoutAnimation() {
    return _buildEmptyGroupsStateContent();
  }

  Widget _buildEmptyGroupsStateContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your Groups',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF52B788),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.group_add,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Groups Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join or create your first savings group to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name = group['name'] ?? 'Group';
    final memberCount = group['member_count'] ?? 0;
    final daysRemaining = group['days_remaining'] ?? 0;
    final progress = group['progress_percentage'] ?? 0.0;
    final currentAmount = group['current_amount'] ?? 0.0;
    final targetAmount = group['target_amount'] ?? 1.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF52B788).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.group_work,
                  color: Color(0xFF52B788),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$memberCount members',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: daysRemaining <= 3 
                    ? const Color(0xFFFF5722).withOpacity(0.2)
                    : const Color(0xFF52B788).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: daysRemaining <= 3 
                      ? const Color(0xFFFF5722).withOpacity(0.5)
                      : const Color(0xFF52B788).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$daysRemaining days',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: daysRemaining <= 3 
                      ? const Color(0xFFFF5722)
                      : const Color(0xFF52B788),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Group Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                '${progress.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF52B788),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current: ${DashboardService.formatLargeCurrency(currentAmount)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                'Target: ${DashboardService.formatLargeCurrency(targetAmount)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.logout,
                color: Color(0xFFFF6B6B),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out? You will need to login again to access your account.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Show loading
                Navigator.of(context).pop(); // Close dialog
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF52B788),
                    ),
                  ),
                );
                
                // Perform logout
                await AuthService.logout();
                
                // Close loading and navigate to login
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/login', 
                    (route) => false, // Remove all previous routes
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Draw organic shapes
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

    // Draw floating circles
    final circlePaint = Paint()
      ..color = const Color(0xFF52B788).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      40,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.6),
      30,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}