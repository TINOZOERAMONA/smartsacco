import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_validation_service.dart';

class TransactionMonitorPage extends StatefulWidget {
  const TransactionMonitorPage({super.key});

  @override
  State<TransactionMonitorPage> createState() => _TransactionMonitorPageState();
}

class _TransactionMonitorPageState extends State<TransactionMonitorPage> {
  final TransactionValidationService _validationService =
      TransactionValidationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  Map<String, dynamic>? _validationResults;
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _integrityResults;
  List<Map<String, dynamic>> _recentTransactions = [];

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load recent transactions
      await _loadRecentTransactions();

      // Get statistics
      _statistics = await _validationService.getTransactionStatistics(
        _currentUserId!,
      );

      // Validate all transactions
      _validationResults = await _validationService.validateAllUserTransactions(
        _currentUserId!,
      );

      // Check integrity
      _integrityResults = await _validationService.verifyTransactionIntegrity(
        _currentUserId!,
      );
    } catch (e) {
      print('Error loading transaction data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      _recentTransactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'amount': data['amount'] ?? 0,
          'type': data['type'] ?? 'Unknown',
          'method': data['method'] ?? 'Unknown',
          'status': data['status'] ?? 'Unknown',
          'date': data['date'] ?? Timestamp.now(),
          'description': data['description'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error loading recent transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Transaction Monitor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF007C91),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),
                  _buildValidationCard(),
                  const SizedBox(height: 16),
                  _buildIntegrityCard(),
                  const SizedBox(height: 16),
                  _buildRecentTransactionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007C91), Color(0xFF005A6B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Monitor',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Real-time validation and monitoring',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_statistics == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: const Color(0xFF007C91)),
              const SizedBox(width: 12),
              Text(
                'Transaction Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Transactions',
                  _statistics!['totalTransactions'].toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Deposits',
                  '${_statistics!['totalDeposits']?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Withdrawals',
                  '${_statistics!['totalWithdrawals']?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.trending_down,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Net Amount',
                  '${_statistics!['netAmount']?.toStringAsFixed(2) ?? '0.00'}',
                  Icons.account_balance_wallet,
                  _statistics!['netAmount'] != null &&
                          _statistics!['netAmount'] >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Success Rate',
                  '${_statistics!['successRate'] ?? '0.00'}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCard() {
    if (_validationResults == null) return const SizedBox.shrink();

    final validCount = _validationResults!['validTransactions'] ?? 0;
    final invalidCount = _validationResults!['invalidTransactions'] ?? 0;
    final totalCount = _validationResults!['totalTransactions'] ?? 0;
    final isValid = invalidCount == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.verified : Icons.warning,
                color: isValid ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Text(
                'Transaction Validation',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isValid ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isValid ? 'VALID' : 'ISSUES FOUND',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildValidationStat(
                  'Valid',
                  validCount,
                  totalCount,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildValidationStat(
                  'Invalid',
                  invalidCount,
                  totalCount,
                  Colors.red,
                ),
              ),
            ],
          ),
          if (_validationResults!['errors'] != null &&
              (_validationResults!['errors'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Validation Errors:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ...(_validationResults!['errors'] as List).map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $error',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationStat(String label, int count, int total, Color color) {
    final percentage = total > 0
        ? (count / total * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '$percentage%',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrityCard() {
    if (_integrityResults == null) return const SizedBox.shrink();

    final isBalanced = _integrityResults!['isBalanced'] ?? false;
    final expectedSavings = _integrityResults!['expectedSavings'] ?? 0.0;
    final actualSavings = _integrityResults!['actualSavings'] ?? 0.0;
    final difference = _integrityResults!['difference'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBalanced ? Icons.check_circle : Icons.error,
                color: isBalanced ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                'Data Integrity',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isBalanced ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBalanced ? 'BALANCED' : 'UNBALANCED',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIntegrityStat(
                  'Expected',
                  expectedSavings.toStringAsFixed(2),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildIntegrityStat(
                  'Actual',
                  actualSavings.toStringAsFixed(2),
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildIntegrityStat(
                  'Difference',
                  difference.toStringAsFixed(2),
                  difference > 0.01 ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrityStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: const Color(0xFF007C91)),
              const SizedBox(width: 12),
              Text(
                'Recent Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentTransactions.isEmpty)
            Center(
              child: Text(
                'No transactions found',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            )
          else
            ..._recentTransactions.map(
              (transaction) => _buildTransactionItem(transaction),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final amount = transaction['amount'] as double;
    final method = transaction['method'] as String;
    final status = transaction['status'] as String;
    final date = transaction['date'] as Timestamp;
    final isDeposit = type == 'Deposit';
    final isCompleted = status == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDeposit ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDeposit ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  method,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDeposit ? '+' : '-'}${amount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDeposit ? Colors.green : Colors.orange,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
