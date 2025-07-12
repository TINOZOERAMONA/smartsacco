import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MemberDetailsPage extends StatefulWidget {
  final String userId;
  const MemberDetailsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX');
  final _expandedSections = <String, bool>{
    'transactions': true,
    'loans': false,
  };

  Future<Map<String, dynamic>> _fetchUserDetails() async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    return userSnapshot.data() ?? {};
  }

  Stream<List<Map<String, dynamic>>> _fetchUserTransactions() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(5) // Show only recent 5 transactions
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> _fetchUserLoans() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('loans')
        .orderBy('applicationDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[800],
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDetails(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }
          if (userSnapshot.hasError) {
            return _buildErrorWidget(userSnapshot.error.toString());
          }

          final userData = userSnapshot.data ?? {};
          final fullName = userData['fullName'] ?? 'N/A';
          final email = userData['email'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(fullName, email),
                const SizedBox(height: 24),

                // Transaction Section
                _buildFinancialSection(
                  title: 'Transaction History',
                  expanded: _expandedSections['transactions']!,
                  onExpand: (expanded) => setState(() => _expandedSections['transactions'] = expanded),
                  child: _buildTransactionHistory(),
                ),
                const SizedBox(height: 16),

                // Loan Section
                _buildFinancialSection(
                  title: 'Loan History',
                  expanded: _expandedSections['loans']!,
                  onExpand: (expanded) => setState(() => _expandedSections['loans'] = expanded),
                  child: _buildLoanHistory(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String fullName, String email) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[100],
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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

  Widget _buildFinancialSection({
    required String title,
    required bool expanded,
    required Function(bool) onExpand,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          expanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.grey[600],
        ),
        initiallyExpanded: expanded,
        onExpansionChanged: onExpand,
        children: [child],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchUserTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading transactions',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }

        final transactions = snapshot.data ?? [];
        final summary = _calculateTransactionSummary(transactions);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  _buildSummaryCard(
                    title: 'Deposits',
                    value: currencyFormat.format(summary['deposits']),
                    color: Colors.green[600]!,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    title: 'Withdrawals',
                    value: currencyFormat.format(summary['withdrawals']),
                    color: Colors.red[600]!,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    title: 'Balance',
                    value: currencyFormat.format(summary['balance']),
                    color: Colors.blue[600]!,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Transaction List
              if (transactions.isEmpty)
                _buildEmptyState('No transactions found')
              else
                ...transactions.map((tx) => _buildTransactionItem(tx)).toList(),
              
              // View All Button
              if (transactions.isNotEmpty)
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to full transaction history
                    },
                    child: const Text('View All Transactions'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoanHistory() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchUserLoans(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading loans',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }

        final loans = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (loans.isEmpty)
                _buildEmptyState('No loans found')
              else
                ...loans.map((loan) => _buildLoanItem(loan)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isDeposit = (transaction['type'] ?? '').toString().toLowerCase() == 'deposit';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final date = transaction['date']?.toDate() ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDeposit ? Colors.green[100] : Colors.red[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isDeposit ? Colors.green[600] : Colors.red[600],
          ),
        ),
        title: Text(
          '${transaction['type']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat.yMMMd().add_jm().format(date)),
        trailing: Text(
          currencyFormat.format(amount),
          style: TextStyle(
            color: isDeposit ? Colors.green[600] : Colors.red[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoanItem(Map<String, dynamic> loan) {
    final status = (loan['status'] ?? '').toString().toLowerCase();
    final amount = (loan['amount'] ?? 0).toDouble();
    final repaid = (loan['repaidAmount'] ?? 0).toDouble();
    final date = loan['applicationDate']?.toDate() ?? DateTime.now();

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
      case 'pending':
        statusColor = Colors.orange;
      case 'rejected':
        statusColor = Colors.red;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loan Amount',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  currencyFormat.format(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Repaid',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  currencyFormat.format(repaid),
                  style: TextStyle(
                    color: repaid >= amount ? Colors.green[600] : Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Applied',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  DateFormat.yMMMd().format(date),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.list_alt, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading member details...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
          const SizedBox(height: 16),
          const Text(
            'Failed to load member',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateTransactionSummary(List<Map<String, dynamic>> transactions) {
    double deposits = 0;
    double withdrawals = 0;

    for (var tx in transactions) {
      final amount = (tx['amount'] ?? 0).toDouble();
      final type = (tx['type'] ?? '').toLowerCase();
      if (type == 'deposit') deposits += amount;
      if (type == 'withdraw') withdrawals += amount;
    }

    return {
      'deposits': deposits,
      'withdrawals': withdrawals,
      'balance': deposits - withdrawals,
    };
  }
}