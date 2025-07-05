

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartloan_sacco/pages/loan.dart';
import 'package:smartloan_sacco/models/notification_model.dart';
import 'package:smartloan_sacco/models/transaction_model.dart';
import 'package:smartloan_sacco/pages/feedback_page.dart';
import 'package:smartloan_sacco/pages/loan_application.dart';
import 'package:smartloan_sacco/models/momo_payment.dart';
import 'package:smartloan_sacco/pages/login.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final Color _savingsColor = const Color(0xFF4CAF50);
  final Color _activeLoansColor = const Color(0xFF9C27B0);
  final Color _overdueColor = const Color(0xFFFF9800);
  final Color _totalDueColor = const Color(0xFF009688);
  final Color _primaryColor = Colors.blue;
  final Color _bgColor = const Color(0xFFF5F6FA);
  final Color _textSecondary = const Color.fromARGB(255, 8, 56, 71);

  int _currentIndex = 0;
  final int _unreadNotifications = 2;

  double _currentSavings = 250000;
  final List<Loan> _loans = [
    Loan(
      id: 'LN-2023-001',
      amount: 500000,
      remainingBalance: 300000,
      disbursementDate: DateTime(2023, 6, 1),
      dueDate: DateTime.now().add(const Duration(days: 15)),
      status: 'Active',
      type: 'Personal',
      interestRate: 12.0,
      totalRepayment: 560000,
    ),
    Loan(
      id: 'LN-2023-002',
      amount: 300000,
      remainingBalance: 150000,
      disbursementDate: DateTime(2023, 8, 15),
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Overdue',
      type: 'Business',
      interestRate: 12.0,
      totalRepayment: 336000,
    ),
  ];

  final List<Transaction> _transactions = [
    Transaction(
      id: 'TR-2023-001',
      amount: 50000,
      date: DateTime(2023, 10, 1),
      type: 'Deposit',
      status: 'Completed',
      method: 'Mobile Money',
    ),
    Transaction(
      id: 'TR-2023-002',
      amount: 20000,
      date: DateTime(2023, 10, 5),
      type: 'Withdrawal',
      status: 'Completed',
      method: 'Bank Transfer',
    ),
  ];

  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'NT-001',
      title: 'Payment Due',
      message: 'Your loan payment of UGX 50,000 is due soon',
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.payment,
    ),
    AppNotification(
      id: 'NT-002',
      title: 'New Offer',
      message: 'Special loan offer available for members',
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.promotion,
    ),
  ];

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showLoanApplication() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanApplicationScreen(
          memberId: 'MEMBER-001',
          memberSavings: _currentSavings,
          onSubmit: (application) {
            final newLoan = Loan(
              id: 'LN-${DateTime.now().millisecondsSinceEpoch}',
              amount: application['amount'],
              remainingBalance: application['amount'] * 1.12,
              disbursementDate: DateTime.now(),
              dueDate: DateTime.now().add(Duration(days: 30 * (application['repaymentPeriod'] as int))),
              status: 'Pending Approval',
              type: application['type'],
              interestRate: 12.0,
              totalRepayment: application['amount'] * 1.12,
            );
            
            setState(() {
              _loans.add(newLoan);
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loan application submitted!')),
            );
          },
        ),
      ),
    );
  }

  void _makePayment(Loan loan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomoPaymentPage(
          amount: loan.remainingBalance,
          onPaymentComplete: (success) {
            if (success) {
              setState(() {
                loan.remainingBalance = 0;
                loan.status = 'Paid';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment successful!')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showNotifications() {
    setState(() => _currentIndex = 3);
  }

  void _submitFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SaccoFeedbackPage()),
    );
  }

  double _calculateTotalDue() {
    return _loans.fold(0, (sum, loan) => sum + loan.remainingBalance);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0).format(amount);
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Savings';
      case 2: return 'Transactions';
      case 3: return 'Notifications';
      default: return 'Dashboard';
    }
  }

  Widget _buildNotificationBadge() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _showNotifications,
        ),
        if (_unreadNotifications > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_unreadNotifications',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _getCurrentScreen(int activeLoans, int overdueLoans, double totalDue) {
    switch (_currentIndex) {
      case 0: return _buildHomeScreen(activeLoans, overdueLoans, totalDue);
      case 1: return _buildSavingsScreen();
      case 2: return _buildTransactionsScreen();
      case 3: return _buildNotificationsScreen();
      default: return _buildHomeScreen(activeLoans, overdueLoans, totalDue);
    }
  }

  Widget _buildHomeScreen(int activeLoans, int overdueLoans, double totalDue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 20),
          _buildStatsGrid(_currentSavings, activeLoans, overdueLoans, totalDue),
          const SizedBox(height: 20),
          _buildDuePaymentsSection(),
          const SizedBox(height: 20),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          child: Icon(Icons.person, size: 30),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Member',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'member@sacco.com',
              style: GoogleFonts.poppins(
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(double savings, int activeLoans, int overdueLoans, double totalDue) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard('Savings', _formatCurrency(savings), _savingsColor),
        _buildStatCard('Active Loans', activeLoans.toString(), _activeLoansColor),
        _buildStatCard('Overdue', overdueLoans.toString(), _overdueColor),
        _buildStatCard('Total Due', _formatCurrency(totalDue), _totalDueColor),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuePaymentsSection() {
    final duePayments = _loans.where((loan) => 
        loan.status == 'Active' || loan.status == 'Overdue').toList();

    if (duePayments.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 50, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'No Due Payments',
                style: GoogleFonts.poppins(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'You have no active or overdue loans at this time',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Repayments Due',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...duePayments.map((loan) => _buildLoanDueCard(loan)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDueCard(Loan loan) {
    final isOverdue = loan.status == 'Overdue';
    final daysRemaining = loan.dueDate.difference(DateTime.now()).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue 
            ? _overdueColor.withOpacity(0.1)
            : _activeLoansColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue ? _overdueColor : _activeLoansColor,
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
                'Loan #${loan.id}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isOverdue 
                    ? '${-daysRemaining} days overdue'
                    : '$daysRemaining days remaining',
                style: GoogleFonts.poppins(
                  color: isOverdue ? _overdueColor : _activeLoansColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLoanDetailRow('Amount Due:', _formatCurrency(loan.remainingBalance)),
          _buildLoanDetailRow('Due Date:', DateFormat('MMM d, y').format(loan.dueDate)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _makePayment(loan),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              child: const Text('Make Payment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          Text(value, style: GoogleFonts.poppins()),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recentTransactions = _transactions.take(3).toList();
    
    if (recentTransactions.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 2),
                  child: const Text('View All'),
                ),
              ],
            ),
            ...recentTransactions.map((txn) => _buildTransactionItem(txn)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction txn) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        txn.type == 'Deposit' ? Icons.arrow_downward : Icons.arrow_upward,
        color: txn.type == 'Deposit' ? Colors.green : Colors.red,
      ),
      title: Text(
        '${txn.type} - ${_formatCurrency(txn.amount)}',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${DateFormat('MMM d').format(txn.date)} • ${txn.method}',
      ),
      trailing: Chip(
        label: Text(txn.status),
        backgroundColor: _getStatusColor(txn.status),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green.withOpacity(0.2);
      case 'pending': return Colors.orange.withOpacity(0.2);
      case 'failed': return Colors.red.withOpacity(0.2);
      default: return Colors.grey.withOpacity(0.2);
    }
  }

  Widget _buildSavingsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.savings, size: 60, color: _primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Savings Account Balance',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(_currentSavings),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showDepositDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Make Deposit',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Future<void> _showDepositDialog() async {
    final amountController = TextEditingController();
    final methodController = TextEditingController(text: 'Mobile Money');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Deposit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (UGX)',
                prefixText: 'UGX ',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: methodController.text,
              items: const [
                DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (value) => methodController.text = value!,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
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
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                if (methodController.text == 'Mobile Money') {
                  Navigator.pop(context);
                  _initiateMobileMoneyPayment(amount);
                } else {
                  _processDeposit(amount, methodController.text);
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
  }

  void _initiateMobileMoneyPayment(double amount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomoPaymentPage(
          amount: amount,
          onPaymentComplete: (success) {
            if (success) {
              setState(() {
                _currentSavings += amount;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment successful!')),
              );
            }
          },
        ),
      ),
    ).then((result) {
      if (result != null && result['success'] == true) {
        _processDeposit(amount, 'Mobile Money');
      }
    });
  }

  Future<void> _processDeposit(double amount, String method) async {
    setState(() {
      _currentSavings += amount;
      _transactions.insert(0, Transaction(
        id: 'TR-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        date: DateTime.now(),
        type: 'Deposit',
        status: 'Completed',
        method: method,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deposit of ${_formatCurrency(amount)} successful')),
    );
  }

  Widget _buildTransactionHistory() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._transactions.take(5).map((txn) => _buildTransactionItem(txn)),
            if (_transactions.length > 5)
              TextButton(
                onPressed: () => setState(() => _currentIndex = 2),
                child: const Text('View All Transactions'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction History',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _filterTransactions,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _transactions.length,
            itemBuilder: (context, index) => _buildTransactionCard(_transactions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction txn) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          txn.type == 'Deposit' ? Icons.arrow_downward : Icons.arrow_upward,
          color: txn.type == 'Deposit' ? Colors.green : Colors.red,
        ),
        title: Text(
          '${txn.type} - ${_formatCurrency(txn.amount)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${DateFormat('MMM d, y').format(txn.date)} • ${txn.method}',
        ),
        trailing: Chip(
          label: Text(txn.status),
          backgroundColor: _getStatusColor(txn.status),
        ),
        onTap: () => _showTransactionDetails(txn),
      ),
    );
  }

  void _filterTransactions() {
    // Implement filtering logic
  }

  void _showTransactionDetails(Transaction txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID:', txn.id),
            _buildDetailRow('Type:', txn.type),
            _buildDetailRow('Amount:', _formatCurrency(txn.amount)),
            _buildDetailRow('Date:', DateFormat('MMM d, y').format(txn.date)),
            _buildDetailRow('Method:', txn.method),
            _buildDetailRow('Status:', txn.status),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildNotificationsScreen() {
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) => _buildNotificationCard(_notifications[index]),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          notification.type == NotificationType.payment ? Icons.payment : Icons.info,
          color: _primaryColor,
        ),
        title: Text(notification.title),
        subtitle: Text(notification.message),
        trailing: Text(DateFormat('MMM d').format(notification.date)),
        onTap: () => _viewNotification(notification),
      ),
    );
  }

  void _viewNotification(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: _primaryColor,
      unselectedItemColor: _textSecondary,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Transactions'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLoans = _loans.where((loan) => loan.status == 'Active').length;
    final overdueLoans = _loans.where((loan) => loan.status == 'Overdue').length;
    final totalDue = _calculateTotalDue();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          if (_currentIndex == 0) _buildNotificationBadge(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _getCurrentScreen(activeLoans, overdueLoans, totalDue),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 0 
          ? FloatingActionButton(
              onPressed: _showLoanApplication,
              backgroundColor: _primaryColor,
              child: const Icon(Icons.add),
            )
          : _currentIndex == 3 
              ? FloatingActionButton(
                  onPressed: _submitFeedback,
                  child: const Icon(Icons.feedback),
                )
              : null,
    );
  }
}