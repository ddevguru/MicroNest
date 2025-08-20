import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:micronest/services/blockchain_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contributionAmountController = TextEditingController();
  final _maxMembersController = TextEditingController();
  
  String _selectedGroupType = 'monthly';
  double _interestRate = 5.0;
  bool _useBlockchain = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  final BlockchainService _blockchainService = BlockchainService();

  final List<String> _groupTypes = [
    'daily',
    'weekly', 
    'monthly',
    'quarterly',
    'yearly'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contributionAmountController.dispose();
    _maxMembersController.dispose();
    _blockchainService.dispose();
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
        'use_blockchain': _useBlockchain,
      };

      if (_useBlockchain) {
        // Create group on blockchain
        final result = await _createBlockchainGroup(groupData);
        if (result['success'] == true) {
          _showSuccessDialog(result);
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      } else {
        // Create group in database only
        final result = await _createDatabaseGroup(groupData);
        if (result['success'] == true) {
          _showSuccessDialog(result);
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
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

  Future<Map<String, dynamic>> _createBlockchainGroup(Map<String, dynamic> groupData) async {
    try {
      // This would integrate with the actual blockchain service
      // For now, simulate the process
      await Future.delayed(const Duration(seconds: 2));
      
      return {
        'success': true,
        'message': 'Group created successfully on blockchain',
        'group_id': DateTime.now().millisecondsSinceEpoch,
        'blockchain_address': '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
        'smart_contract_address': '0x${(DateTime.now().millisecondsSinceEpoch + 1000).toRadixString(16)}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Blockchain creation failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _createDatabaseGroup(Map<String, dynamic> groupData) async {
    try {
      // This would integrate with the actual API
      await Future.delayed(const Duration(seconds: 1));
      
      return {
        'success': true,
        'message': 'Group created successfully',
        'group_id': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Database creation failed: $e',
      };
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 8),
            const Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message']),
            const SizedBox(height: 16),
            if (result['blockchain_address'] != null) ...[
              _buildInfoRow('Blockchain Address:', result['blockchain_address']),
              _buildInfoRow('Smart Contract:', result['smart_contract_address']),
            ],
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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey[100],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Group'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Information Section
              _buildSectionHeader('Group Information', Icons.group),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  hintText: 'Enter a unique name for your group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the purpose and goals of your group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().length > 500) {
                    return 'Description must be less than 500 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Group Settings Section
              _buildSectionHeader('Group Settings', Icons.settings),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGroupType,
                      decoration: const InputDecoration(
                        labelText: 'Contribution Frequency *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: _groupTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type[0].toUpperCase() + type.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroupType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _contributionAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹) *',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
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
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxMembersController,
                      decoration: const InputDecoration(
                        labelText: 'Max Members *',
                        hintText: '20',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Max members is required';
                        }
                        final members = int.tryParse(value);
                        if (members == null || members < 2 || members > 100) {
                          return 'Members must be between 2 and 100';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interest Rate (%)',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _interestRate,
                                  min: 0.0,
                                  max: 20.0,
                                  divisions: 40,
                                  label: '${_interestRate.toStringAsFixed(1)}%',
                                  onChanged: (value) {
                                    setState(() {
                                      _interestRate = value;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '${_interestRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Blockchain Integration Section
              _buildSectionHeader('Blockchain Integration', Icons.block),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Use Blockchain'),
                subtitle: Text(
                  _useBlockchain 
                    ? 'Group will be created on Ethereum blockchain with smart contracts'
                    : 'Group will be managed in traditional database only',
                  style: TextStyle(fontSize: 12),
                ),
                value: _useBlockchain,
                onChanged: (value) {
                  setState(() {
                    _useBlockchain = value;
                  });
                },
                secondary: Icon(
                  _useBlockchain ? Icons.block : Icons.storage,
                  color: _useBlockchain ? Colors.blue[600] : Colors.grey[600],
                ),
              ),
              
              if (_useBlockchain) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Blockchain Benefits',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem('Transparent transactions', Icons.visibility),
                      _buildBenefitItem('Immutable records', Icons.lock),
                      _buildBenefitItem('Smart contract automation', Icons.auto_awesome),
                      _buildBenefitItem('Decentralized management', Icons.share),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
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
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Group',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Terms and Conditions
              Text(
                'By creating this group, you agree to our Terms of Service and Privacy Policy.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 