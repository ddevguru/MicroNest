import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  int _currentTabIndex = 0;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? profileData;
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProfileData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _startEntranceAnimations();
  }

  void _startEntranceAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _slideController.forward();
        _fadeController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _bounceController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get user data from AuthService
      final userData = await AuthService.getAuthenticatedUser();
      print('🔍 User Data: $userData'); // Debug log

      // Get profile data from ProfileService
      final profileResult = await ProfileService.getProfileData();
      print('🔍 Profile Result: $profileResult'); // Debug log

      if (profileResult['success'] == true) {
        final profileDataFromService = profileResult['data'];
        print('🔍 Profile Data from Service: $profileDataFromService'); // Debug log

        // Merge user data with profile data
        setState(() {
          profileData = {
            'user': userData,
            ...profileDataFromService,
          };
          _isLoading = false;
        });

        print('🔍 Final Profile Data: $profileData'); // Debug log
        print('🔍 Profile Image: ${profileData?['user']?['profile_image']}'); // Debug log
      } else {
        print('❌ Profile loading failed: ${profileResult['message']}'); // Debug log
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${profileResult['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading profile: $e'); // Debug log
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateNotificationSetting(String setting, bool value) async {
    try {
      final result = await ProfileService.updateNotificationSettings({
        setting: value,
      });
      
      if (result['success'] == true) {
        // Update local state
        setState(() {
          if (profileData != null) {
            if (profileData!['preferences'] == null) {
              profileData!['preferences'] = {};
            }
            profileData!['preferences'][setting] = value;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${setting.replaceAll('_', ' ').toUpperCase()} updated successfully'),
            backgroundColor: const Color(0xFF52B788),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating setting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateSecuritySetting(String setting, bool value) async {
    try {
      // Special handling for biometric login
      if (setting == 'biometric_login') {
        await _handleBiometricToggle(value);
        return;
      }
      
      final result = await ProfileService.updateSecuritySettings({
        setting: value,
      });
      
      if (result['success'] == true) {
        // Update local state
        setState(() {
          if (profileData != null) {
            if (profileData!['security'] == null) {
              profileData!['security'] = {};
            }
            profileData!['security'][setting] = value;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${setting.replaceAll('_', ' ').toUpperCase()} updated successfully'),
            backgroundColor: const Color(0xFF52B788),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating setting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleBiometricToggle(bool enable) async {
    if (enable) {
      // User wants to enable biometric authentication
      await _enableBiometricAuth();
    } else {
      // User wants to disable biometric authentication
      await _disableBiometricAuth();
    }
  }

  Future<void> _enableBiometricAuth() async {
    try {
      // First check if biometric authentication is available
      final setupResult = await BiometricService.promptBiometricSetup();
      
      if (!setupResult.success) {
        // Show error and don't enable the setting
        _showBiometricSetupDialog(setupResult);
        return;
      }
      
      // Prompt user to authenticate to confirm they want to enable it
      final authResult = await BiometricService.authenticate(
        reason: 'Please authenticate to enable biometric login for MicroNest',
      );
      
      if (authResult.success) {
        // Authentication successful, enable biometric login
        await BiometricService.setBiometricEnabled(true);
        
        // Update backend
        final result = await ProfileService.updateSecuritySettings({
          'biometric_login': true,
        });
        
        if (result['success'] == true) {
          // Update local state
          setState(() {
            if (profileData != null) {
              if (profileData!['security'] == null) {
                profileData!['security'] = {};
              }
              profileData!['security']['biometric_login'] = true;
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric login enabled successfully!'),
              backgroundColor: Color(0xFF52B788),
            ),
          );
        } else {
          // Backend update failed, revert local setting
          await BiometricService.setBiometricEnabled(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enable biometric login: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Authentication failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authResult.error ?? 'Biometric authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enabling biometric login: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disableBiometricAuth() async {
    try {
      // Disable biometric authentication
      await BiometricService.setBiometricEnabled(false);
      
      // Update backend
      final result = await ProfileService.updateSecuritySettings({
        'biometric_login': false,
      });
      
      if (result['success'] == true) {
        // Update local state
        setState(() {
          if (profileData != null) {
            if (profileData!['security'] == null) {
              profileData!['security'] = {};
            }
            profileData!['security']['biometric_login'] = false;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric login disabled successfully'),
            backgroundColor: Color(0xFF52B788),
          ),
        );
      } else {
        // Backend update failed, revert local setting
        await BiometricService.setBiometricEnabled(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disable biometric login: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disabling biometric login: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBiometricSetupDialog(BiometricSetupResult setupResult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Biometric Setup Required',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            setupResult.message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            if (setupResult.shouldShowSettings)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openDeviceSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52B788),
                ),
                child: const Text('Open Settings'),
              ),
          ],
        );
      },
    );
  }

  void _openDeviceSettings() {
    // Show instruction to user since we can't directly open biometric settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please go to Settings > Security > Biometric authentication to set up fingerprint, face unlock, or pattern'),
        backgroundColor: Color(0xFF52B788),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _updateProfileImage() async {
    // TODO: Implement profile image update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile image update feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              _loadProfileData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: const Color(0xFF52B788),
              backgroundColor: const Color(0xFF1A1A1A),
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.5),
                        indicatorColor: const Color(0xFF52B788),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Profile'),
                          Tab(text: 'Trust'),
                          Tab(text: 'Awards'),
                          Tab(text: 'Settings'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildProfileTab(),
                          _buildTrustTab(),
                          _buildAwardsTab(),
                          _buildSettingsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Profile', 'Trust', 'Awards', 'Settings'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _currentTabIndex;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentTabIndex = index;
                });
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF52B788).withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF52B788),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? const Color(0xFF52B788) : Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    switch (_currentTabIndex) {
      case 0:
        return _buildProfileTab();
      case 1:
        return _buildTrustTab();
      case 2:
        return _buildAwardsTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildProfileTab();
    }
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
            'Loading your profile...',
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

  Widget _buildProfileTab() {
    if (profileData == null) {
      return const Center(
        child: Text(
          'No profile data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final userData = profileData!['user'] ?? {};
    final fullName = userData['full_name'] ?? 'User';
    final username = userData['username'] ?? '';
    final email = userData['email'] ?? '';
    final phone = userData['phone'] ?? '';
    final profileImage = userData['profile_image'] ?? '';
    final trustScore = userData['trust_score'] ?? 0;
    final kycStatus = userData['kyc_status'] ?? 'pending';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(fullName, username, profileImage, trustScore),
          
          const SizedBox(height: 32),
          
          // Account Stats
          if (profileData!['stats'] != null) _buildAccountStatsCard(profileData!['stats']),
          
          const SizedBox(height: 24),
          
          // Profile Actions
          _buildProfileActions(),
          
          const SizedBox(height: 24),
          
          // KYC Status
          _buildKYCStatus(kycStatus),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String fullName, String username, String profileImage, int trustScore) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF52B788),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: profileImage.isNotEmpty
                  ? _buildProfileImage(profileImage)
                  : Container(
                      color: const Color(0xFF52B788),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // Trust Score
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: const Color(0xFF52B788),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Trust Score: $trustScore',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Edit Button
          IconButton(
            onPressed: _showEditProfileDialog,
            icon: const Icon(
              Icons.edit,
              color: Color(0xFF52B788),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String imageData) {
    try {
      // Check if it's a base64 image
      if (imageData.startsWith('/9j/') || imageData.startsWith('data:image/')) {
        // Handle base64 image
        String base64String = imageData;
        if (imageData.startsWith('data:image/')) {
          // Remove data URL prefix
          base64String = imageData.split(',')[1];
        }
        
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            );
          },
        );
      } else if (imageData.startsWith('http')) {
        // Handle network image
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            );
          },
        );
      } else {
        // Fallback to default icon
        return const Icon(
          Icons.person,
          color: Colors.white,
          size: 40,
        );
      }
    } catch (e) {
      // If any error occurs, show default icon
      return const Icon(
        Icons.person,
        color: Colors.white,
        size: 40,
      );
    }
  }

  Widget _buildAccountStatsCard(Map<String, dynamic> stats) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Stats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '${stats['groups_joined'] ?? 0}',
                    'Groups\nJoined',
                    const Color(0xFF52B788),
                  ),
                  _buildStatItem(
                    '₹${stats['total_contributed'] ?? 0}',
                    'Total\nContributed',
                    const Color(0xFFFF9800),
                  ),
                  _buildStatItem(
                    '${stats['active_loans'] ?? 0}',
                    'Active\nLoans',
                    const Color(0xFF9C27B0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildKYCStatusCard(Map<String, dynamic> user) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KYC Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verification Pending',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete verification for higher loan limits',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement KYC completion
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('KYC completion coming soon!'),
                        backgroundColor: Color(0xFF52B788),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52B788),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Complete KYC',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustTab() {
    final trustData = (profileData?['trust'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildOverallTrustScore(trustData),
          const SizedBox(height: 20),
          _buildTrustBreakdown(trustData),
        ],
      ),
    );
  }

  Widget _buildOverallTrustScore(Map<String, dynamic> trustData) {
    final overallScore = trustData['overall_score'] ?? 75;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '$overallScore%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF52B788),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Overall Trust Score',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: overallScore / 100,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF52B788).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFF52B788),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Excellent! ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF52B788),
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: 'Your trust score qualifies you for premium loan rates and higher limits.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildTrustBreakdown(Map<String, dynamic> trustData) {
    // Use real breakdown data or fallback to sample data
    final breakdown = (trustData['breakdown'] as List<dynamic>?) ?? [
      {
        'name': 'Payment History',
        'score': trustData['payment_score'] ?? 85,
        'max_score': 100,
        'description': 'Based on your loan repayment history'
      },
      {
        'name': 'Group Participation',
        'score': trustData['group_score'] ?? 90,
        'max_score': 100,
        'description': 'Your active participation in savings groups'
      },
      {
        'name': 'Verification Status',
        'score': trustData['verification_score'] ?? 75,
        'max_score': 100,
        'description': 'KYC and document verification completion'
      },
      {
        'name': 'Community Rating',
        'score': trustData['community_score'] ?? 88,
        'max_score': 100,
        'description': 'Rating from other group members'
      }
    ];
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score Breakdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ...breakdown.map((item) => _buildTrustItem(item as Map<String, dynamic>)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustItem(Map<String, dynamic> item) {
    final score = item['score'] ?? 0;
    final maxScore = item['max_score'] ?? 100;
    final name = item['name'] ?? '';
    final description = item['description'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '$score/$maxScore',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF52B788),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / maxScore,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsTab() {
    final awardsData = (profileData?['awards'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildAwardsHeader(awardsData),
          const SizedBox(height: 20),
          _buildAwardsList(awardsData),
        ],
      ),
    );
  }

  Widget _buildAwardsHeader(Map<String, dynamic> awardsData) {
    final earnedCount = awardsData['earned_count'] ?? 0;
    final totalCount = awardsData['total_count'] ?? 5;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$earnedCount of $totalCount earned',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAwardsList(Map<String, dynamic> awardsData) {
    // Use real awards data or fallback to sample data
    final awards = (awardsData['list'] as List<dynamic>?) ?? [
      {
        'name': 'First Loan',
        'description': 'Successfully completed your first loan',
        'is_earned': true,
        'progress': 100,
        'earned_date': '2024-01-15'
      },
      {
        'name': 'Group Leader',
        'description': 'Became a group leader for 3 months',
        'is_earned': true,
        'progress': 100,
        'earned_date': '2024-02-20'
      },
      {
        'name': 'Perfect Payment',
        'description': 'Made 12 consecutive on-time payments',
        'is_earned': false,
        'progress': 75,
        'earned_date': null
      },
      {
        'name': 'Savings Master',
        'description': 'Save ₹50,000 in your groups',
        'is_earned': false,
        'progress': 60,
        'earned_date': null
      },
      {
        'name': 'Community Helper',
        'description': 'Help 5 other members with advice',
        'is_earned': true,
        'progress': 100,
        'earned_date': '2024-03-10'
      }
    ];
    
    return Column(
      children: awards.map((award) => _buildAwardCard(award as Map<String, dynamic>)).toList(),
    );
  }

  Widget _buildAwardCard(Map<String, dynamic> award) {
    final isEarned = award['is_earned'] ?? false;
    final progress = award['progress'] ?? 0;
    final earnedDate = award['earned_date'];
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isEarned 
                      ? const Color(0xFF52B788)
                      : Colors.grey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: isEarned ? Colors.white : Colors.grey,
                  size: 30,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      award['name'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      award['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    if (isEarned && earnedDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Earned on $earnedDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
                        minHeight: 4,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${progress.toInt()}% complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isEarned 
                      ? const Color(0xFF52B788)
                      : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isEarned ? 'Earned' : 'In Progress',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEarned ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildNotificationSettings(),
          const SizedBox(height: 20),
          _buildSecuritySettings(),
          const SizedBox(height: 20),
          _buildSupportSettings(),
          const SizedBox(height: 20),
          _buildLogoutSection(),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingItem(
                'Push Notifications',
                'Get notified about group activities',
                profileData?['preferences']?['push_notifications'] ?? true,
                (value) async {
                  await _updateNotificationSetting('push_notifications', value);
                },
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                'Loan Reminders',
                'Reminders for upcoming payments',
                profileData?['preferences']?['loan_reminders'] ?? true,
                (value) async {
                  await _updateNotificationSetting('loan_reminders', value);
                },
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                'Group Chat',
                'Messages from group members',
                profileData?['preferences']?['group_chat'] ?? true,
                (value) async {
                  await _updateNotificationSetting('group_chat', value);
                },
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                'Email Notifications',
                'Receive updates via email',
                profileData?['preferences']?['email_notifications'] ?? true,
                (value) async {
                  await _updateNotificationSetting('email_notifications', value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingItem(
                'Biometric Login',
                'Use fingerprint or face ID',
                profileData?['security']?['biometric_login'] ?? false,
                (value) async {
                  await _updateSecuritySetting('biometric_login', value);
                },
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                'Change PIN',
                Icons.lock,
                () {
                  _showChangePinDialog();
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                'Update KYC Documents',
                Icons.camera_alt,
                () {
                  _showKYCUpdateDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSettings() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                'Help Center',
                Icons.help,
                () {
                  _showHelpCenter();
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                'Contact Support',
                Icons.support_agent,
                () {
                  _showContactSupport();
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                'About App',
                Icons.info,
                () {
                  _showAboutApp();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                'Logout',
                Icons.logout,
                () {
                  _showLogoutDialog();
                },
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePinDialog() {
    final TextEditingController currentPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'PIN Management',
                style: TextStyle(color: Colors.white),
              ),
              content: FutureBuilder<bool>(
                future: ProfileService.isPinSet(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
                      ),
                    );
                  }
                  
                  final bool isPinSet = snapshot.data ?? false;
                  
                  if (!isPinSet) {
                    // PIN not set, show set PIN option
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No PIN is currently set. Would you like to set a 4-digit PIN for additional security?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: newPinController,
                          decoration: const InputDecoration(
                            labelText: 'New PIN (4 digits)',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF52B788)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmPinController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm PIN',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF52B788)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                        ),
                      ],
                    );
                  } else {
                    // PIN is set, show change PIN option
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Enter your current PIN and new PIN:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: currentPinController,
                          decoration: const InputDecoration(
                            labelText: 'Current PIN',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF52B788)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: newPinController,
                          decoration: const InputDecoration(
                            labelText: 'New PIN (4 digits)',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF52B788)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmPinController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm New PIN',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF52B788)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                        ),
                      ],
                    );
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                FutureBuilder<bool>(
                  future: ProfileService.isPinSet(),
                  builder: (context, snapshot) {
                    final bool isPinSet = snapshot.data ?? false;
                    
                    if (!isPinSet) {
                      // Show Set PIN button
                      return ElevatedButton(
                        onPressed: () async {
                          if (newPinController.text.length == 4 && 
                              newPinController.text == confirmPinController.text) {
                            final result = await ProfileService.setPin(newPinController.text);
                            Navigator.of(context).pop();
                            
                            if (result['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN set successfully!'),
                                  backgroundColor: Color(0xFF52B788),
                                ),
                              );
                              // Reload profile data
                              _loadProfileData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to set PIN: ${result['message']}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('PINs do not match or are not 4 digits'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF52B788),
                        ),
                        child: const Text('Set PIN'),
                      );
                    } else {
                      // Show Change PIN button
                      return ElevatedButton(
                        onPressed: () async {
                          if (currentPinController.text.length == 4 &&
                              newPinController.text.length == 4 && 
                              newPinController.text == confirmPinController.text) {
                            final result = await ProfileService.updatePin(
                              currentPinController.text,
                              newPinController.text,
                            );
                            Navigator.of(context).pop();
                            
                            if (result['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN updated successfully!'),
                                  backgroundColor: Color(0xFF52B788),
                                ),
                              );
                              // Reload profile data
                              _loadProfileData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update PIN: ${result['message']}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields correctly'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF52B788),
                        ),
                        child: const Text('Change PIN'),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showKYCUpdateDialog() {
    final TextEditingController aadhaarController = TextEditingController();
    String? frontImagePath;
    String? backImagePath;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'KYC Verification',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please upload your Aadhaar card images and enter the number:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: aadhaarController,
                      decoration: const InputDecoration(
                        labelText: 'Aadhaar Number',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF52B788)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Front Side',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _pickImage(true, (path) {
                                  setState(() {
                                    frontImagePath = path;
                                  });
                                }),
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: frontImagePath != null 
                                          ? const Color(0xFF52B788)
                                          : Colors.white30,
                                    ),
                                  ),
                                  child: frontImagePath != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(frontImagePath!),
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white70,
                                          size: 40,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Back Side',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _pickImage(false, (path) {
                                  setState(() {
                                    backImagePath = path;
                                  });
                                }),
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: backImagePath != null 
                                          ? const Color(0xFF52B788)
                                          : Colors.white30,
                                    ),
                                  ),
                                  child: backImagePath != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(backImagePath!),
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white70,
                                          size: 40,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Note: Your KYC will be verified by admin within 24-48 hours.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (aadhaarController.text.length == 12 && 
                        frontImagePath != null && 
                        backImagePath != null) {
                      await _submitKYC(
                        aadhaarController.text,
                        frontImagePath!,
                        backImagePath!,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields correctly'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52B788),
                  ),
                  child: const Text('Submit KYC'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage(bool isFront, Function(String) onImagePicked) async {
    // TODO: Implement image picker functionality
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image picker for ${isFront ? 'front' : 'back'} side coming soon!'),
        backgroundColor: const Color(0xFF52B788),
      ),
    );
  }

  Future<void> _submitKYC(String aadhaarNumber, String frontImage, String backImage) async {
    try {
      // TODO: Implement KYC submission to backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KYC submitted successfully! Will be verified within 24-48 hours.'),
          backgroundColor: Color(0xFF52B788),
        ),
      );
      
      // Update local state
      setState(() {
        if (profileData != null) {
          profileData!['kyc_status'] = 'pending';
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting KYC: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHelpCenter() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Help Center',
            style: TextStyle(color: Colors.white),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Frequently Asked Questions:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '• How to create a savings group?\n'
                  '• How to apply for a loan?\n'
                  '• How to improve trust score?\n'
                  '• How to update KYC documents?\n'
                  '• How to contact support?',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 16),
                Text(
                  'For detailed answers, visit our help portal or contact support.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening help portal...'),
                    backgroundColor: Color(0xFF52B788),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52B788),
              ),
              child: const Text('Visit Portal'),
            ),
          ],
        );
      },
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Contact Support',
            style: TextStyle(color: Colors.white),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get in touch with our support team:',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.email, color: Color(0xFF52B788), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'support@micronest.in',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, color: Color(0xFF52B788), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '+91 1800-123-4567',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Color(0xFF52B788), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '24/7 Support Available',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening email client...'),
                    backgroundColor: Color(0xFF52B788),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52B788),
              ),
              child: const Text('Send Email'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'About MicroNest',
            style: TextStyle(color: Colors.white),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MicroNest - Your Trusted Financial Partner',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Version: 1.0.0\n'
                'Build: 2024.1.1\n'
                'Developer: MicroNest Team\n\n'
                'MicroNest helps you save money, build trust, and access financial services through community-based savings groups.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to logout? You will need to login again to access your account.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Color(0xFF52B788),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSettingItem(String title, String description, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF52B788),
          activeTrackColor: const Color(0xFF52B788).withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed, {bool isDestructive = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive 
              ? Colors.red.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDestructive 
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(
      text: profileData?['user']?['full_name'] ?? '',
    );
    final TextEditingController phoneController = TextEditingController(
      text: profileData?['user']?['phone'] ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF52B788)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF52B788)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateProfile({
                  'full_name': nameController.text,
                  'phone': phoneController.text,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52B788),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile(Map<String, dynamic> profileData) async {
    try {
      final result = await ProfileService.updateProfile(profileData);
      
      if (result['success'] == true) {
        // Refresh profile data
        await _loadProfileData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF52B788),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _updateProfileImage,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'Update Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52B788),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditProfileDialog(),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showKYCSubmissionDialog() {
    // Show a dialog to collect KYC information
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KYC submission dialog coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildKYCStatus(String kycStatus) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (kycStatus) {
      case 'verified':
        statusColor = const Color(0xFF52B788);
        statusIcon = Icons.verified;
        statusText = 'KYC Verified';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'KYC Pending';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'KYC Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'KYC Status Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'KYC Status',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor,
                width: 1,
              ),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (kycStatus == 'pending') ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showKYCSubmissionDialog,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text(
                'Submit KYC',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52B788),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 