import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:micronest/services/blockchain_service.dart';

class JoinGroupScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  
  const JoinGroupScreen({super.key, required this.group});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  
  String _selectedPaymentMethod = 'blockchain';
  bool _useBlockchain = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _walletAddress;
  
  final BlockchainService _blockchainService = BlockchainService();

  final List<String> _paymentMethods = [
    'blockchain',
    'cash',
    'bank_transfer',
    'mobile_money'
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.group['contribution_amount'];
    _loadWalletAddress();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paymentMethodController.dispose();
    _blockchainService.dispose();
    super.dispose();
  }

  Future<void> _loadWalletAddress() async {
    try {
      final address = await _blockchainService.getWalletAddress();
      setState(() {
        _walletAddress = address;
      });
    } catch (e) {
      print('Error loading wallet address: $e');
    }
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      final groupId = widget.group['id'];
      
      if (_useBlockchain && _selectedPaymentMethod == 'blockchain') {
        // Join group using blockchain
        if (_walletAddress == null) {
          setState(() {
            _errorMessage = 'Please set up your wallet first';
            _isLoading = false;
          });
          return;
        }
        
        final result = await _blockchainService.joinGroup(
          '0x${groupId.toString().padLeft(40, '0')}', // Mock contract address
          amount.toString(),
        );
        
        if (result['success'] == true) {
          _showSuccessDialog(result);
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      } else {
        // Join group using traditional payment
        final result = await _joinGroupTraditional(groupId, amount);
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
        _errorMessage = 'Failed to join group: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _joinGroupTraditional(int groupId, double amount) async {
    try {
      // This would integrate with the actual API
      await Future.delayed(const Duration(seconds: 1));
      
      return {
        'success': true,
        'message': 'Successfully joined group',
        'group_id': groupId,
        'amount': amount,
        'payment_method': _selectedPaymentMethod,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to join group: $e',
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
            const Text('Welcome!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have successfully joined ${widget.group['name']}!'),
            const SizedBox(height: 16),
            _buildInfoRow('Group:', widget.group['name']),
            _buildInfoRow('Amount:', '₹${result['amount']}'),
            if (result['transaction_hash'] != null)
              _buildInfoRow('Transaction:', result['transaction_hash']),
            _buildInfoRow('Payment Method:', _selectedPaymentMethod),
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
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                backgroundColor: Colors.grey[100],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWalletSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('To use blockchain payments, you need to set up a wallet.'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await _blockchainService.createWallet();
                      if (result['success'] == true) {
                        setState(() {
                          _walletAddress = result['wallet_address'];
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Wallet created: ${result['wallet_address']}'),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    },
                    child: const Text('Create New'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showImportWalletDialog();
                    },
                    child: const Text('Import'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showImportWalletDialog() {
    final privateKeyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your private key to import an existing wallet.'),
            const SizedBox(height: 16),
            TextField(
              controller: privateKeyController,
              decoration: const InputDecoration(
                labelText: 'Private Key',
                hintText: '0x...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Never share your private key with anyone!',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final privateKey = privateKeyController.text.trim();
              if (privateKey.isNotEmpty) {
                Navigator.pop(context);
                final result = await _blockchainService.importWallet(privateKey);
                if (result['success'] == true) {
                  setState(() {
                    _walletAddress = result['wallet_address'];
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Wallet imported: ${result['wallet_address']}'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
        backgroundColor: Colors.green[600],
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
              // Group Information Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group, color: Colors.green[600], size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.group['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.group['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildGroupInfoChip(
                            Icons.people,
                            '${widget.group['current_members']}/${widget.group['max_members']}',
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildGroupInfoChip(
                            Icons.currency_rupee,
                            '₹${widget.group['contribution_amount']}',
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Payment Details Section
              _buildSectionHeader('Payment Details', Icons.payment),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Contribution Amount (₹) *',
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
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                    _useBlockchain = value == 'blockchain';
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Blockchain Integration Section
              if (_useBlockchain) ...[
                _buildSectionHeader('Blockchain Wallet', Icons.account_balance_wallet),
                const SizedBox(height: 16),
                
                if (_walletAddress == null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Wallet Not Setup',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You need to set up a wallet to use blockchain payments.',
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _showWalletSetupDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Setup Wallet'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Wallet Ready',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wallet: ${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _showWalletSetupDialog,
                          child: const Text('Change Wallet'),
                        ),
                      ],
                    ),
                  ),
                ],
                
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
                      _buildBenefitItem('Instant verification'),
                      _buildBenefitItem('Transparent transactions'),
                      _buildBenefitItem('No middleman fees'),
                      _buildBenefitItem('Global accessibility'),
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
              
              // Join Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || (_useBlockchain && _walletAddress == null)) 
                      ? null 
                      : _joinGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
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
                          'Join Group',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Terms and Conditions
              Text(
                'By joining this group, you agree to follow the group rules and contribute regularly.',
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
        Icon(icon, color: Colors.green[600], size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
} 