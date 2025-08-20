import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:micronest/services/group_service.dart';
import 'package:micronest/services/auth_service.dart';

class RequestLoanScreen extends StatefulWidget {
  const RequestLoanScreen({Key? key}) : super(key: key);

  @override
  State<RequestLoanScreen> createState() => _RequestLoanScreenState();
}

class _RequestLoanScreenState extends State<RequestLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _dueDateController = TextEditingController();
  
  List<Map<String, dynamic>> userGroups = [];
  Map<String, dynamic>? selectedGroup;
  bool isLoading = false;
  bool isGroupsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    try {
      setState(() {
        isGroupsLoading = true;
      });
      
      final groups = await GroupService.getUserGroups();
      if (groups['success'] == true) {
        setState(() {
          userGroups = List<Map<String, dynamic>>.from(groups['data'] ?? []);
          if (userGroups.isNotEmpty) {
            selectedGroup = userGroups.first;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading groups: $e')),
      );
    } finally {
      setState(() {
        isGroupsLoading = false;
      });
    }
  }

  Future<void> _requestLoan() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final result = await GroupService.requestLoan({
        'group_id': selectedGroup!['id'],
        'amount': double.parse(_amountController.text),
        'purpose': _purposeController.text,
        'due_date': _dueDateController.text,
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan request submitted successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to submit loan request')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Loan'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Request Loan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submit a loan request to your group',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Group Selection
                  Text(
                    'Select Group',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (isGroupsLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else if (userGroups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You need to join a group first to request a loan',
                              style: TextStyle(color: Colors.red[100]),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: DropdownButtonFormField<Map<String, dynamic>>(
                        value: selectedGroup,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        dropdownColor: const Color(0xFF1E3A8A),
                        style: const TextStyle(color: Colors.white),
                        items: userGroups.map((group) {
                          return DropdownMenuItem(
                            value: group,
                            child: Text(
                              group['group_name'] ?? 'Unknown Group',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGroup = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Please select a group';
                          return null;
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Loan Amount (₹)',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter loan amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Purpose Field
                  TextFormField(
                    controller: _purposeController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Purpose of Loan',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter loan purpose';
                      }
                      if (value.length < 10) {
                        return 'Please provide more details (minimum 10 characters)';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Due Date Field
                  TextFormField(
                    controller: _dueDateController,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Expected Repayment Date',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        _dueDateController.text = date.toIso8601String().split('T')[0];
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select repayment date';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _requestLoan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Loan Request',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[300],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your loan request will be reviewed by group admins. You will be notified once it\'s approved or rejected.',
                            style: TextStyle(
                              color: Colors.blue[100],
                              fontSize: 14,
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
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }
} 