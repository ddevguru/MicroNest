import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:micronest/services/auth_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contributionAmountController = TextEditingController();
  final _maxMembersController = TextEditingController();
  
  String _selectedGroupType = 'monthly';
  double _interestRate = 5.0;
  bool _isLoading = false;
  String? _errorMessage;

  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  final List<String> _groupTypes = [
    'daily',
    'weekly', 
    'monthly',
    'quarterly',
    'yearly'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    _nameController.dispose();
    _descriptionController.dispose();
    _contributionAmountController.dispose();
    _maxMembersController.dispose();
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groupData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'group_type': _selectedGroupType,
        'contribution_amount': double.parse(_contributionAmountController.text),
        'max_members': int.parse(_maxMembersController.text),
        'interest_rate': _interestRate,
      };

      final result = await AuthService.createGroup(groupData);
      if (result['success']) {
        _showSuccessDialog(result);
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create group: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 8),
            const Text('Success!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message'], style: TextStyle(color: Colors.white.withOpacity(0.9))),
            const SizedBox(height: 16),
            _buildInfoRow('Group ID:', result['group_id'].toString()),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to groups screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18 * MediaQuery.of(context).textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF52B788),
                        strokeWidth: 3,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: FadeTransition(
                        opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
                        child: SlideTransition(
                          position: _slideAnimation ?? AlwaysStoppedAnimation(Offset.zero),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Create Group',
                                    style: TextStyle(
                                      fontSize: 28 * MediaQuery.of(context).textScaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(Icons.close, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Group Information Section
                                    _buildSectionHeader('Group Information', Icons.group),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: 'Group Name *',
                                        hintText: 'Enter a unique name for your group',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                        prefixIcon: Icon(Icons.label, color: Colors.white),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Group name is required';
                                        }
                                        if (value.trim().length < 3) {
                                          return 'Group name must be at least 3 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _descriptionController,
                                      decoration: InputDecoration(
                                        labelText: 'Description *',
                                        hintText: 'Enter a brief description',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                        prefixIcon: Icon(Icons.description, color: Colors.white),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      maxLines: 3,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Description is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: _selectedGroupType,
                                      decoration: InputDecoration(
                                        labelText: 'Contribution Frequency *',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                        prefixIcon: Icon(Icons.schedule, color: Colors.white),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      dropdownColor: const Color(0xFF1A1A1A),
                                      items: _groupTypes.map((type) {
                                        return DropdownMenuItem(
                                          value: type,
                                          child: Text(type.capitalize()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGroupType = value!;
                                        });
                                      },
                                      validator: (value) => value == null ? 'Please select a frequency' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    // Contribution Amount Section
                                    _buildSectionHeader('Financial Details', Icons.attach_money),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _contributionAmountController,
                                      decoration: InputDecoration(
                                        labelText: 'Contribution Amount (₹) *',
                                        hintText: 'Enter amount per contribution',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                        prefixIcon: Icon(Icons.currency_rupee, color: Colors.white),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Amount is required';
                                        }
                                        final amount = double.tryParse(value);
                                        if (amount == null || amount <= 0) {
                                          return 'Amount must be greater than 0';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _maxMembersController,
                                      decoration: InputDecoration(
                                        labelText: 'Max Members *',
                                        hintText: 'Enter maximum number of members',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                        prefixIcon: Icon(Icons.people, color: Colors.white),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Max members is required';
                                        }
                                        final maxMembers = int.tryParse(value);
                                        if (maxMembers == null || maxMembers < 2) {
                                          return 'Max members must be at least 2';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Slider(
                                      value: _interestRate,
                                      min: 0.0,
                                      max: 10.0,
                                      divisions: 20,
                                      label: '${_interestRate.toStringAsFixed(1)}%',
                                      activeColor: Colors.green[600],
                                      inactiveColor: Colors.white.withOpacity(0.3),
                                      onChanged: (value) {
                                        setState(() {
                                          _interestRate = value;
                                        });
                                      },
                                    ),
                                    Text(
                                      'Interest Rate: ${_interestRate.toStringAsFixed(1)}%',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 32),
                                    // Error Message
                                    if (_errorMessage != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.red[600]),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: TextStyle(color: Colors.red[600]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    // Create Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _createGroup,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[600],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              )
                                            : const Text(
                                                'Create Group',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}