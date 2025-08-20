import 'package:flutter/material.dart';
import 'package:micronest/services/group_service.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> groupTransactions = [];
  List<Map<String, dynamic>> walletTransactions = [];
  bool isLoading = true;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load group transactions
      final groupResult = await GroupService.getUserTransactions();
      if (groupResult['success'] == true) {
        groupTransactions = List<Map<String, dynamic>>.from(groupResult['data'] ?? []);
      }

      // Load wallet transactions (you can add wallet service later)
      walletTransactions = [];

      // Combine all transactions
      allTransactions = [...groupTransactions, ...walletTransactions];
      
      // Sort by date (newest first)
      allTransactions.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> getFilteredTransactions() {
    switch (selectedFilter) {
      case 'contributions':
        return allTransactions.where((t) => t['type'] == 'contribution').toList();
      case 'withdrawals':
        return allTransactions.where((t) => t['type'] == 'withdrawal').toList();
      case 'loans':
        return allTransactions.where((t) => t['type'] == 'loan').toList();
      case 'deposits':
        return allTransactions.where((t) => t['type'] == 'deposit').toList();
      default:
        return allTransactions;
    }
  }

  String getTransactionIcon(String type) {
    switch (type) {
      case 'contribution':
        return '💰';
      case 'withdrawal':
        return '💸';
      case 'loan':
        return '🏦';
      case 'deposit':
        return '💳';
      default:
        return '📊';
    }
  }

  Color getTransactionColor(String type) {
    switch (type) {
      case 'contribution':
      case 'deposit':
        return Colors.green;
      case 'withdrawal':
        return Colors.red;
      case 'loan':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String getTransactionStatus(String status) {
    switch (status) {
      case 'pending':
        return '⏳ Pending';
      case 'approved':
        return '✅ Approved';
      case 'rejected':
        return '❌ Rejected';
      case 'completed':
        return '✅ Completed';
      default:
        return '📋 Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Groups'),
            Tab(text: 'Wallet'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          ),
        ),
        child: Column(
          children: [
            // Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Filter:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedFilter,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        dropdownColor: const Color(0xFF1E3A8A),
                        style: const TextStyle(color: Colors.white),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('All Transactions')),
                          DropdownMenuItem(value: 'contributions', child: Text('Contributions')),
                          DropdownMenuItem(value: 'withdrawals', child: Text('Withdrawals')),
                          DropdownMenuItem(value: 'loans', child: Text('Loans')),
                          DropdownMenuItem(value: 'deposits', child: Text('Deposits')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedFilter = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Transactions List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionsList(getFilteredTransactions()),
                  _buildTransactionsList(groupTransactions),
                  _buildTransactionsList(walletTransactions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Map<String, dynamic>> transactions) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final type = transaction['type'] ?? 'unknown';
        final amount = transaction['amount'] ?? 0.0;
        final status = transaction['status'] ?? 'pending';
        final date = DateTime.tryParse(transaction['created_at'] ?? '') ?? DateTime.now();
        final description = transaction['description'] ?? transaction['purpose'] ?? 'No description';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: getTransactionColor(type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  getTransactionIcon(type),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: getTransactionColor(type),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getTransactionColor(type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          color: getTransactionColor(type),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      getTransactionStatus(status),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(date),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                if (transaction['group_name'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Group: ${transaction['group_name']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              _showTransactionDetails(transaction);
            },
          ),
        );
      },
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1E3A8A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: getTransactionColor(transaction['type'] ?? 'unknown').withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              getTransactionIcon(transaction['type'] ?? 'unknown'),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction['type']?.toString().toUpperCase() ?? 'TRANSACTION',
                                style: TextStyle(
                                  color: getTransactionColor(transaction['type'] ?? 'unknown'),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${(transaction['amount'] ?? 0.0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildDetailRow('Status', getTransactionStatus(transaction['status'] ?? 'pending')),
                    _buildDetailRow('Date', DateFormat('EEEE, MMMM dd, yyyy').format(
                      DateTime.tryParse(transaction['created_at'] ?? '') ?? DateTime.now()
                    )),
                    _buildDetailRow('Time', DateFormat('HH:mm:ss').format(
                      DateTime.tryParse(transaction['created_at'] ?? '') ?? DateTime.now()
                    )),
                    
                    if (transaction['description'] != null)
                      _buildDetailRow('Description', transaction['description']),
                    if (transaction['purpose'] != null)
                      _buildDetailRow('Purpose', transaction['purpose']),
                    if (transaction['reason'] != null)
                      _buildDetailRow('Reason', transaction['reason']),
                    if (transaction['group_name'] != null)
                      _buildDetailRow('Group', transaction['group_name']),
                    if (transaction['transaction_hash'] != null)
                      _buildDetailRow('Transaction Hash', transaction['transaction_hash']),
                    
                    const Spacer(),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 