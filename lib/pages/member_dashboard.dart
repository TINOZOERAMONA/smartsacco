// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartsacco/pages/loan.dart';
import 'package:smartsacco/models/notification.dart';
import 'package:smartsacco/pages/loanapplication.dart';
import 'package:smartsacco/models/momopayment.dart';
import 'package:smartsacco/pages/login.dart';
import 'package:smartsacco/pages/feedback.dart';

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
  int _unreadNotifications = 0;
  String memberId = '';
  String memberName = '';
  String memberEmail = '';

  double _currentSavings = 0;
  List<Loan> _loans = [];
  List<AppNotification> _notifications = [];
  List<SavingsHistory> _savingsHistory = [];
  final List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      memberId = user.uid;

      final memberDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      setState(() {
        memberName = memberDoc['fullName'] ?? 'Member';
        memberEmail = memberDoc['email'] ?? 'member@sacco.com';
      });

      _fetchSavingsData();
      _fetchLoansData();
      _fetchNotifications();
    }
  }

  Future<void> _fetchSavingsData() async {
    final savingsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .collection('savings')
        .orderBy('date', descending: true)
        .get();

    double totalSavings = 0;
    List<SavingsHistory> history = [];

    for (var doc in savingsSnapshot.docs) {
      final amount = doc['amount']?.toDouble() ?? 0;
      totalSavings += amount;
      history.add(
        SavingsHistory(
          amount: amount,
          date: doc['date'].toDate(),
          type: doc['type'] ?? 'Deposit',
          transactionId: doc.id,
        ),
      );
    }

    setState(() {
      _currentSavings = totalSavings;
      _savingsHistory = history;
    });
  }

  Future<void> _fetchLoansData() async {
    final loansSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .collection('loans')
        .where('status', whereIn: ['Active', 'Overdue', 'Pending'])
        .get();

    List<Loan> loans = [];

    for (var doc in loansSnapshot.docs) {
      final payments = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('loans')
          .doc(doc.id)
          .collection('payments')
          .get();

      loans.add(
        Loan(
          id: doc.id,
          amount: doc['amount']?.toDouble() ?? 0,
          remainingBalance: doc['remainingBalance']?.toDouble() ?? 0,
          disbursementDate: doc['disbursementDate']?.toDate() ?? DateTime.now(),
          dueDate: doc['dueDate']?.toDate() ?? DateTime.now(),
          status: doc['status'] ?? 'Pending',
          type: doc['type'] ?? 'Personal',
          interestRate: doc['interestRate']?.toDouble() ?? 12.0,
          totalRepayment: doc['totalRepayment']?.toDouble() ?? 0,
          repaymentPeriod: doc['repaymentPeriod']?.toInt() ?? 12,
          payments: payments.docs
              .map(
                (p) => Payment(
                  amount: p['amount']?.toDouble() ?? 0,
                  date: p['date']?.toDate() ?? DateTime.now(),
                  reference: p['reference'] ?? '',
                ),
              )
              .toList(),
        ),
      );
    }

    setState(() {
      _loans = loans;
    });
  }

  Future<void> _fetchNotifications() async {
    final notificationsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .collection('notifications')
        .orderBy('date', descending: true)
        .limit(10)
        .get();

    int unread = 0;
    List<AppNotification> notifications = [];

    for (var doc in notificationsSnapshot.docs) {
      final isRead = doc['isRead'] ?? false;
      if (!isRead) unread++;

      notifications.add(
        AppNotification(
          id: doc.id,
          title: doc['title'] ?? 'Notification',
          message: doc['message'] ?? '',
          date: doc['date']?.toDate() ?? DateTime.now(),
          type: NotificationType.values[doc['type'] ?? 0],
          isRead: isRead,
          actionUrl: doc['actionUrl'],
        ),
      );
    }

    setState(() {
      _notifications = notifications;
      _unreadNotifications = unread;
    });
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
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
          memberId: memberId,
          memberSavings: _currentSavings,
          onSubmit: (application) async {
            try {
              final amount = application['amount'];
              final interestRate = application['interestRate'];
              final repaymentPeriod = application['repaymentPeriod'];
              final interest =
                  (amount * interestRate / 100) * (repaymentPeriod / 12);
              final totalRepayment = amount + interest;
              final monthlyPayment = repaymentPeriod > 0
                  ? totalRepayment / repaymentPeriod
                  : 0;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(memberId)
                  .collection('loans')
                  .add({
                    'amount': amount,
                    'remainingBalance': totalRepayment,
                    'disbursementDate': DateTime.now(),
                    'dueDate': DateTime.now().add(
                      Duration(days: repaymentPeriod * 30),
                    ),
                    'status': 'Pending Approval',
                    'type': application['type'] ?? 'Personal',
                    'interestRate': interestRate,
                    'totalRepayment': totalRepayment,
                    'monthlyPayment': monthlyPayment,
                    'purpose': application['purpose'],
                    'applicationDate': DateTime.now(),
                  });

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(memberId)
                  .collection('notifications')
                  .add({
                    'title': 'Loan Application Submitted',
                    'message':
                        'Your loan application of ${_formatCurrency(amount)} is under review',
                    'date': DateTime.now(),
                    'type': NotificationType.loan.index,
                    'isRead': false,
                  });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loan application submitted!')),
              );

              _fetchLoansData();
              _fetchNotifications();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error submitting application: $e')),
              );
            }
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
          amount: loan.nextPaymentAmount,
          onPaymentComplete: (success) async {
            if (success) {
              try {
                final paymentAmount = loan.nextPaymentAmount;
                final paymentRef = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .collection('loans')
                    .doc(loan.id)
                    .collection('payments')
                    .add({
                      'amount': paymentAmount,
                      'date': DateTime.now(),
                      'reference':
                          'MOMO-${DateTime.now().millisecondsSinceEpoch}',
                    });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .collection('loans')
                    .doc(loan.id)
                    .update({
                      'remainingBalance': loan.remainingBalance - paymentAmount,
                      'nextPaymentDate': DateTime.now().add(
                        const Duration(days: 30),
                      ),
                    });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .collection('transactions')
                    .add({
                      'amount': paymentAmount,
                      'date': DateTime.now(),
                      'type': 'Loan Repayment',
                      'status': 'Completed',
                      'method': 'Mobile Money',
                      'loanId': loan.id,
                      'paymentId': paymentRef.id,
                    });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .collection('notifications')
                    .add({
                      'title': 'Payment Received',
                      'message':
                          'Your payment of ${_formatCurrency(paymentAmount)} for loan ${loan.id.substring(0, 8)} has been received',
                      'date': DateTime.now(),
                      'type': NotificationType.payment.index,
                      'isRead': false,
                    });

                _fetchLoansData();
                _fetchNotifications();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment successful!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error recording payment: $e')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showNotifications() {
    setState(() => _currentIndex = 3);

    for (var notification in _notifications.where((n) => !n.isRead)) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('notifications')
          .doc(notification.id)
          .update({'isRead': true});
    }

    _fetchNotifications();
  }

  void _submitFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SaccoFeedbackPage()),
    );
  }

  double _calculateTotalDue() {
    return _loans.fold(0, (acc, loan) => acc + loan.nextPaymentAmount);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Savings';
      case 2:
        return 'Transactions';
      case 3:
        return 'Notifications';
      default:
        return 'Dashboard';
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
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$_unreadNotifications',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _getCurrentScreen(int activeLoans, int overdueLoans, double totalDue) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen(activeLoans, overdueLoans, totalDue);
      case 1:
        return _buildSavingsScreen();
      case 2:
        return _buildTransactionsScreen();
      case 3:
        return _buildNotificationsScreen();
      default:
        return _buildHomeScreen(activeLoans, overdueLoans, totalDue);
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
        const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $memberName',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              memberEmail,
              style: GoogleFonts.poppins(color: _textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    double savings,
    int activeLoans,
    int overdueLoans,
    double totalDue,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        GestureDetector(
          onTap: () => _showSavingsDetails(),
          child: _buildStatCard(
            'Savings',
            _formatCurrency(savings),
            _savingsColor,
          ),
        ),
        GestureDetector(
          onTap: () => _showActiveLoans(),
          child: _buildStatCard(
            'Active Loans',
            activeLoans.toString(),
            _activeLoansColor,
          ),
        ),
        GestureDetector(
          onTap: () => _showOverdueLoans(),
          child: _buildStatCard(
            'Overdue',
            overdueLoans.toString(),
            _overdueColor,
          ),
        ),
        GestureDetector(
          onTap: () => _showTotalDueDetails(),
          child: _buildStatCard(
            'Total Due',
            _formatCurrency(totalDue),
            _totalDueColor,
          ),
        ),
      ],
    );
  }

  void _showSavingsDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SavingsDetailsScreen(
        currentSavings: _currentSavings,
        savingsHistory: _savingsHistory,
      ),
    );
  }

  void _showActiveLoans() {
    final activeLoans = _loans
        .where((loan) => loan.status == 'Active')
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LoansListScreen(
        loans: activeLoans,
        title: 'Active Loans',
        onPayment: _makePayment,
      ),
    );
  }

  void _showOverdueLoans() {
    final overdueLoans = _loans
        .where((loan) => loan.status == 'Overdue')
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LoansListScreen(
        loans: overdueLoans,
        title: 'Overdue Loans',
        onPayment: _makePayment,
      ),
    );
  }

  void _showTotalDueDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TotalDueScreen(
        loans: _loans,
        totalDue: _calculateTotalDue(),
        onPayment: _makePayment,
      ),
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
    final duePayments = _loans
        .where((loan) => loan.status == 'Active' || loan.status == 'Overdue')
        .toList();

    if (duePayments.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 50, color: Colors.green),
              const SizedBox(height: 16),
              Text('No Due Payments', style: GoogleFonts.poppins(fontSize: 18)),
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
    final nextPaymentDate = loan.payments.isEmpty
        ? loan.disbursementDate.add(const Duration(days: 30))
        : loan.payments.last.date.add(const Duration(days: 30));
    final daysRemaining = nextPaymentDate.difference(DateTime.now()).inDays;
    // final double amountDue = loan.remainingBalance;
    // final double nextPaymentAmount = loan.totalRepayment / loan.repaymentPeriod;

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
                'Loan #${loan.id.substring(0, 8)}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
          _buildLoanDetailRow(
            'Next Payment:',
            _formatCurrency(loan.nextPaymentAmount),
          ),
          _buildLoanDetailRow(
            'Amount Due:',
            _formatCurrency(loan.remainingBalance),
          ),
          _buildLoanDetailRow(
            'Due Date:',
            DateFormat('MMM d, y').format(nextPaymentDate),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _makePayment(loan),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
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
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('${DateFormat('MMM d').format(txn.date)} • ${txn.method}'),
      trailing: Chip(
        label: Text(txn.status),
        backgroundColor: _getStatusColor(txn.status),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.withOpacity(0.2);
      case 'pending':
        return Colors.orange.withOpacity(0.2);
      case 'failed':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
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
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.savings, size: 60, color: Colors.green),
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
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showDepositDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                DropdownMenuItem(
                  value: 'Mobile Money',
                  child: Text('Mobile Money'),
                ),
                DropdownMenuItem(
                  value: 'Bank Transfer',
                  child: Text('Bank Transfer'),
                ),
              ],
              onChanged: (value) => methodController.text = value!,
              decoration: const InputDecoration(labelText: 'Payment Method'),
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
              _processDeposit(amount, 'Mobile Money');
            }
          },
        ),
      ),
    );
  }

  Future<void> _processDeposit(double amount, String method) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('savings')
          .add({
            'amount': amount,
            'date': DateTime.now(),
            'type': 'Deposit',
            'method': method,
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .add({
            'amount': amount,
            'date': DateTime.now(),
            'type': 'Deposit',
            'status': 'Completed',
            'method': method,
          });

      setState(() {
        _currentSavings += amount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deposit of ${_formatCurrency(amount)} successful'),
        ),
      );

      _fetchSavingsData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing deposit: $e')));
    }
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
            itemBuilder: (context, index) =>
                _buildTransactionCard(_transactions[index]),
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildNotificationsScreen() {
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) =>
          _buildNotificationCard(_notifications[index]),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          _getNotificationIcon(notification.type),
          color: _getNotificationColor(notification.type),
        ),
        title: Text(notification.title),
        subtitle: Text(notification.message),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(DateFormat('MMM d').format(notification.date)),
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () => _viewNotification(notification),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.loan:
        return Icons.money;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.loan:
        return Colors.purple;
      case NotificationType.promotion:
        return Colors.orange;
      case NotificationType.general:
        return Colors.blue;
    }
  }

  void _viewNotification(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              DateFormat('MMM d, y hh:mm a').format(notification.date),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          if (notification.actionUrl != null)
            TextButton(
              onPressed: () {
                // Handle action URL
                Navigator.pop(context);
              },
              child: const Text('View Details'),
            ),
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
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Transactions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLoans = _loans.where((loan) => loan.status == 'Active').length;
    final overdueLoans = _loans
        .where((loan) => loan.status == 'Overdue')
        .length;
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

class SavingsDetailsScreen extends StatelessWidget {
  final double currentSavings;
  final List<SavingsHistory> savingsHistory;

  const SavingsDetailsScreen({
    super.key,
    required this.currentSavings,
    required this.savingsHistory,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Icon(Icons.drag_handle),
              const SizedBox(height: 10),
              Text(
                'Savings Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Current Savings Balance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(
                          symbol: 'UGX ',
                        ).format(currentSavings),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: savingsHistory.length,
                  itemBuilder: (context, index) {
                    final item = savingsHistory[index];
                    return ListTile(
                      leading: Icon(
                        item.type == 'Deposit'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: item.type == 'Deposit'
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(
                        '${item.type} - ${NumberFormat.currency(symbol: 'UGX ').format(item.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(DateFormat('MMM d, y').format(item.date)),
                      trailing: Text(DateFormat.jm().format(item.date)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LoansListScreen extends StatelessWidget {
  final List<Loan> loans;
  final String title;
  final Function(Loan) onPayment;

  const LoansListScreen({
    super.key,
    required this.loans,
    required this.title,
    required this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Icon(Icons.drag_handle),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    final nextPaymentDate = loan.payments.isEmpty
                        ? loan.disbursementDate.add(const Duration(days: 30))
                        : loan.payments.last.date.add(const Duration(days: 30));
                    final daysRemaining = nextPaymentDate
                        .difference(DateTime.now())
                        .inDays;
                    final isOverdue = daysRemaining < 0;
                    final nextPaymentAmount =
                        loan.totalRepayment /
                        (loan.dueDate.difference(loan.disbursementDate).inDays /
                            30);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Loan #${loan.id.substring(0, 8)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Chip(
                                  label: Text(loan.status),
                                  backgroundColor: loan.status == 'Active'
                                      ? Colors.purple[100]
                                      : Colors.orange[100],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildLoanDetailRow(
                              'Original Amount:',
                              NumberFormat.currency(
                                symbol: 'UGX ',
                              ).format(loan.amount),
                            ),
                            _buildLoanDetailRow(
                              'Remaining Balance:',
                              NumberFormat.currency(
                                symbol: 'UGX ',
                              ).format(loan.remainingBalance),
                            ),
                            _buildLoanDetailRow(
                              'Next Payment:',
                              NumberFormat.currency(
                                symbol: 'UGX ',
                              ).format(nextPaymentAmount),
                            ),
                            _buildLoanDetailRow(
                              'Due Date:',
                              '${DateFormat('MMM d, y').format(nextPaymentDate)} '
                                  '(${isOverdue ? 'Overdue ${-daysRemaining} days' : 'Due in $daysRemaining days'})',
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => onPayment(loan),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                ),
                                child: const Text('Make Payment'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoanDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}

class TotalDueScreen extends StatelessWidget {
  final List<Loan> loans;
  final double totalDue;
  final Function(Loan) onPayment;

  const TotalDueScreen({
    super.key,
    required this.loans,
    required this.totalDue,
    required this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    final activeLoans = loans.where((loan) => loan.status == 'Active').toList();
    final overdueLoans = loans
        .where((loan) => loan.status == 'Overdue')
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Icon(Icons.drag_handle),
              const SizedBox(height: 10),
              Text(
                'Total Due Summary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.teal[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Total Amount Due',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(symbol: 'UGX ').format(totalDue),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[700],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (overdueLoans.isNotEmpty) ...[
                _buildLoanTypeSection('Overdue Loans', overdueLoans, context),
                const SizedBox(height: 16),
              ],
              if (activeLoans.isNotEmpty) ...[
                _buildLoanTypeSection('Active Loans', activeLoans, context),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoanTypeSection(
    String title,
    List<Loan> loans,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...loans.map((loan) {
          final nextPaymentDate = loan.payments.isEmpty
              ? loan.disbursementDate.add(const Duration(days: 30))
              : loan.payments.last.date.add(const Duration(days: 30));
          final daysRemaining = nextPaymentDate
              .difference(DateTime.now())
              .inDays;
          final isOverdue = daysRemaining < 0;
          final nextPaymentAmount =
              loan.totalRepayment /
              (loan.dueDate.difference(loan.disbursementDate).inDays / 30);

          return ListTile(
            title: Text('Loan #${loan.id.substring(0, 8)}'),
            subtitle: Text(
              'Next Payment: ${NumberFormat.currency(symbol: 'UGX ').format(nextPaymentAmount)}\n'
              'Due: ${DateFormat('MMM d').format(nextPaymentDate)} '
              '(${isOverdue ? 'Overdue ${-daysRemaining} days' : 'Due in $daysRemaining days'})',
            ),
            trailing: ElevatedButton(
              onPressed: () => onPayment(loan),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Pay'),
            ),
          );
        }),
      ],
    );
  }
}

class SavingsHistory {
  final double amount;
  final DateTime date;
  final String type;
  final String transactionId;

  SavingsHistory({
    required this.amount,
    required this.date,
    required this.type,
    required this.transactionId,
  });
}

class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String type;
  final String status;
  final String method;
  final String? loanId;
  final String? paymentId;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    required this.method,
    this.loanId,
    this.paymentId,
  });
}
