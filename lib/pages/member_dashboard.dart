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
import 'package:smartsacco/services/momoservices.dart';
import 'package:smartsacco/services/user_preferences_service.dart';

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

  bool _isBlindUser = false;

  @override
  void initState() {
    super.initState();
    print('MemberDashboard initialized');
    _checkUserMode();
    _fetchTransactions();
  }

  // Check if user is blind to conditionally enable/disable features
  Future<void> _checkUserMode() async {
    final accessibilityMode = UserPreferencesService().getAccessibilityMode();
    setState(() {
      _isBlindUser = accessibilityMode == 'blind';
    });
    print('User mode: ${_isBlindUser ? 'Blind' : 'Sighted'}');
  }

  // Speak welcome message
  Future<void> _speakWelcome() async {
    // This functionality has been removed as per instructions
  }

  // Speak current balance
  Future<void> _speakBalance() async {
    // This functionality has been removed as per instructions
  }

  // Speak help information
  Future<void> _speakHelp() async {
    // This functionality has been removed as per instructions
  }

  // Navigate to loans
  void _navigateToLoans() {
    Navigator.pushNamed(context, '/loans');
  }

  // Navigate to transactions
  void _navigateToTransactions() {
    setState(() {
      _currentIndex = 1; // Switch to transactions tab
    });
  }

  // Navigate to settings
  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  // Navigate to loan application
  void _navigateToLoanApplication() {
    Navigator.pushNamed(context, '/loan-application');
  }

  // Handle logout
  void _handleLogout() async {
    // This functionality has been removed as per instructions
  }

  // Handle go back
  void _handleGoBack() {
    Navigator.pop(context);
  }

  // Navigate to savings
  void _navigateToSavings() {
    // This would navigate to a dedicated savings screen
    // For now, we'll show the savings information in a dialog
    _showSavingsDialog();
  }

  // Show savings dialog
  void _showSavingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Your Savings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ${_formatCurrency(_currentSavings)}'),
            SizedBox(height: 10),
            Text('Active Loans: ${_loans.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchTransactions() async {
    print('🔄 Fetching transactions for member dashboard');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      memberId = user.uid;
      print('✅ Current user ID: $memberId');

      try {
        final memberDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();

        if (memberDoc.exists) {
          print('✅ Member document found: ${memberDoc.data()}');

          setState(() {
            memberName = memberDoc['fullName'] ?? 'Member';
            memberEmail = memberDoc['email'] ?? 'member@sacco.com';
          });

          print('✅ Member details loaded:');
          print('   - Name: $memberName');
          print('   - Email: $memberEmail');

          // Fetch all data in parallel for better performance
          await Future.wait([
            _fetchSavingsData(),
            _fetchLoansData(),
            _fetchNotifications(),
            _fetchTransactionHistory(),
          ]);

          print('✅ All data fetched successfully');
        } else {
          print('❌ Member document not found for ID: $memberId');
          // Handle missing member document
          _showErrorDialog(
            'Data Error',
            'Member data not found. Please contact support.',
          );
        }
      } catch (e) {
        print('❌ Error fetching member data: $e');
        debugPrint('Error fetching member data: $e');
        _showErrorDialog('Connection Error', 'Failed to load member data: $e');
      }
    } else {
      print('❌ No current user found in MemberDashboard');
      _showErrorDialog(
        'Authentication Error',
        'User not authenticated. Please login again.',
      );
    }
  }

  // New method to fetch transaction history
  Future<void> _fetchTransactionHistory() async {
    try {
      print('🔄 Fetching transaction history for member: $memberId');

      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      List<Transaction> transactions = [];

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();

        // Validate transaction data
        if (data['amount'] != null && data['date'] != null) {
          transactions.add(
            Transaction(
              id: doc.id,
              amount: data['amount']?.toDouble() ?? 0,
              type: data['type'] ?? 'Unknown',
              date: data['date']?.toDate() ?? DateTime.now(),
              status: data['status'] ?? 'Pending',
              method: data['method'] ?? 'Unknown',
              description: data['description'] ?? '',
            ),
          );
        } else {
          print('⚠️ Skipping invalid transaction: ${doc.id}');
        }
      }

      if (mounted) {
        setState(() {
          _transactions.clear();
          _transactions.addAll(transactions);
        });
      }

      print('✅ Transaction history fetched:');
      print('   - Total transactions: ${transactions.length}');
      print(
        '   - Recent transactions: ${transactions.take(5).map((t) => '${t.type}: ${_formatCurrency(t.amount)}').join(', ')}',
      );
    } catch (e) {
      print('❌ Error fetching transaction history: $e');
      debugPrint('Error fetching transaction history: $e');
    }
  }

  Future<void> _fetchSavingsData() async {
    try {
      print('🔄 Fetching savings data for member: $memberId');

      final savingsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('savings')
          .orderBy('date', descending: true)
          .get();

      double totalSavings = 0;
      List<SavingsHistory> history = [];

      for (var doc in savingsSnapshot.docs) {
        final data = doc.data();

        // Validate savings data
        if (data['amount'] != null && data['date'] != null) {
          final amount = data['amount']?.toDouble() ?? 0;
          totalSavings += amount;
          history.add(
            SavingsHistory(
              amount: amount,
              date: data['date'].toDate(),
              type: data['type'] ?? 'Deposit',
              transactionId: doc.id,
            ),
          );
        } else {
          print('⚠️ Skipping invalid savings record: ${doc.id}');
        }
      }

      if (mounted) {
        setState(() {
          _currentSavings = totalSavings;
          _savingsHistory = history;
        });
      }

      print('✅ Savings data fetched:');
      print('   - Total savings: ${_formatCurrency(totalSavings)}');
      print('   - Number of transactions: ${history.length}');
      print('   - Previous balance: ${_formatCurrency(_currentSavings)}');
      print('   - New balance: ${_formatCurrency(_currentSavings)}');
      print(
        '   - Balance change: ${_formatCurrency(totalSavings - _currentSavings)}',
      );
    } catch (e) {
      print('❌ Error fetching savings data: $e');
      debugPrint('Error fetching savings data: $e');
    }
  }

  Future<void> _fetchLoansData() async {
    try {
      print('🔄 Fetching loans data for member: $memberId');

      // Fetch all loans with different statuses
      final loansSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('loans')
          .where(
            'status',
            whereIn: [
              'Active',
              'Approved',
              'Overdue',
              'Pending',
              'Pending Approval',
              'Rejected',
            ],
          )
          .get();

      List<Loan> loans = [];

      for (var doc in loansSnapshot.docs) {
        final loanData = doc.data();

        // Validate loan data
        if (loanData['amount'] != null) {
          final status = loanData['status'] ?? 'Pending';

          // Fetch payments for this loan
          try {
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
                amount: loanData['amount']?.toDouble() ?? 0,
                remainingBalance: loanData['remainingBalance']?.toDouble() ?? 0,
                disbursementDate:
                    loanData['disbursementDate']?.toDate() ?? DateTime.now(),
                dueDate: loanData['dueDate']?.toDate() ?? DateTime.now(),
                status: status,
                type: loanData['type'] ?? 'Personal',
                interestRate: loanData['interestRate']?.toDouble() ?? 12.0,
                totalRepayment: loanData['totalRepayment']?.toDouble() ?? 0,
                monthlyPayment:
                    loanData['monthlyPayment']?.toDouble() ??
                    0, // ✅ Added monthlyPayment
                repaymentPeriod: loanData['repaymentPeriod']?.toInt() ?? 12,
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
          } catch (paymentError) {
            print(
              '⚠️ Error fetching payments for loan ${doc.id}: $paymentError',
            );
            // Add loan without payments
            loans.add(
              Loan(
                id: doc.id,
                amount: loanData['amount']?.toDouble() ?? 0,
                remainingBalance: loanData['remainingBalance']?.toDouble() ?? 0,
                disbursementDate:
                    loanData['disbursementDate']?.toDate() ?? DateTime.now(),
                dueDate: loanData['dueDate']?.toDate() ?? DateTime.now(),
                status: status,
                type: loanData['type'] ?? 'Personal',
                interestRate: loanData['interestRate']?.toDouble() ?? 12.0,
                totalRepayment: loanData['totalRepayment']?.toDouble() ?? 0,
                monthlyPayment:
                    loanData['monthlyPayment']?.toDouble() ??
                    0, // ✅ Added monthlyPayment
                repaymentPeriod: loanData['repaymentPeriod']?.toInt() ?? 12,
                payments: [],
              ),
            );
          }
        } else {
          print('⚠️ Skipping invalid loan: ${doc.id}');
        }
      }

      if (mounted) {
        setState(() {
          _loans = loans;
        });

        print('✅ Loans data updated:');
        print('   - Total loans: ${loans.length}');
        print(
          '   - Active loans: ${loans.where((l) => l.status == 'Active' || l.status == 'Approved').length}',
        );
        print(
          '   - Pending loans: ${loans.where((l) => l.status == 'Pending' || l.status == 'Pending Approval').length}',
        );
        print(
          '   - Overdue loans: ${loans.where((l) => l.status == 'Overdue').length}',
        );
        print(
          '   - Rejected loans: ${loans.where((l) => l.status == 'Rejected').length}',
        );
      }
    } catch (e) {
      print('❌ Error fetching loans data: $e');
      debugPrint('Error fetching loans data: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      print('🔄 Fetching notifications for member: $memberId');

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
        final data = doc.data();
        final isRead = data['isRead'] ?? false;
        if (!isRead) unread++;

        notifications.add(
          AppNotification(
            id: doc.id,
            title: data['title'] ?? 'Notification',
            message: data['message'] ?? '',
            date: data['date']?.toDate() ?? DateTime.now(),
            type: NotificationType.values[data['type'] ?? 0],
            isRead: isRead,
            actionUrl:
                data['actionUrl'], // This field is optional and can be null
          ),
        );
      }

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _unreadNotifications = unread;
        });

        print('✅ Notifications fetched:');
        print('   - Total notifications: ${notifications.length}');
        print('   - Unread notifications: $unread');

        // Voice feedback for new notifications
        if (unread > 0) {
          // This functionality has been removed as per instructions
        }
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      debugPrint('Error fetching notifications: $e');
    }
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

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loan application submitted!')),
              );

              _fetchLoansData();
              _fetchNotifications();
            } catch (e) {
              if (!mounted) return;
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

                // final remainingBalance = (await FirebaseFirestore.instance
                //     .collection('users')
                //     .doc(memberId)
                //     .collection('loans')
                //     .doc(loan.id).get()).data()?['remainingBalance'];

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
                      ...((loan.remainingBalance - paymentAmount) <= 0 ? {'status': 'Completed'} : {}),
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

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment successful!')),
                );
              } catch (e) {
                if (!mounted) return;
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
    return _loans.fold(0, (acc, loan) {
      // Only include active and approved loans
      if (loan.status != 'Active' && loan.status != 'Approved') {
        return acc;
      }

      // Calculate the next payment date
      final nextPaymentDate = loan.payments.isEmpty
          ? loan.disbursementDate.add(const Duration(days: 30))
          : loan.payments.last.date.add(const Duration(days: 30));

      // Check if the next payment is overdue or due soon
      final daysUntilPayment = nextPaymentDate
          .difference(DateTime.now())
          .inDays;
      final isOverdue = daysUntilPayment < 0;
      final isDueSoon = daysUntilPayment <= 7 && daysUntilPayment >= 0;

      // Calculate overdue amount if applicable
      double overdueAmount = 0;
      if (isOverdue) {
        // Calculate how many months are overdue
        final overdueMonths = (daysUntilPayment.abs() / 30).ceil();
        overdueAmount = loan.monthlyPayment * overdueMonths;
      }

      // Return the appropriate amount based on payment status
      if (isOverdue) {
        return acc + overdueAmount;
      } else if (isDueSoon) {
        return acc + loan.monthlyPayment;
      } else {
        // For loans that are not due yet, only include if they're overdue
        return acc;
      }
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Voice feedback methods
  Future<void> _speakVoiceFeedback(String message) async {
    // This functionality has been removed as per instructions
  }

  Future<void> _speak(String message) async {
    // This functionality has been removed as per instructions
  }

  // Voice confirmation deposit method removed as per instructions

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
          _buildQuickActionsSection(),
          const SizedBox(height: 20),
          _buildMonthlyPaymentsSection(),
          const SizedBox(height: 20),
          _buildDuePaymentsSection(),
          const SizedBox(height: 20),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memberName.length > 20
                      ? '${memberName.substring(0, 20)}...'
                      : memberName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  memberEmail.length > 30
                      ? '${memberEmail.substring(0, 30)}...'
                      : memberEmail,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    double savings,
    int activeLoans,
    int overdueLoans,
    double totalDue,
  ) {
    // Calculate additional stats
    final pendingLoans = _loans
        .where(
          (loan) =>
              loan.status == 'Pending' || loan.status == 'Pending Approval',
        )
        .length;
    final totalDeposits = _savingsHistory
        .where((item) => item.type.toLowerCase().contains('deposit'))
        .fold(0.0, (sum, item) => sum + item.amount);
    final totalWithdrawals = _savingsHistory
        .where((item) => item.type.toLowerCase().contains('withdraw'))
        .fold(0.0, (sum, item) => sum + item.amount);
    final recentTransactions = _savingsHistory.take(5).length;

    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final childAspectRatio = isSmallScreen ? 1.5 : 1.3;

    return Column(
      children: [
        // First row - Main financial info
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            GestureDetector(
              onTap: () => _showSavingsDetails(),
              child: Stack(
                children: [
                  _buildStatCard(
                    'Current Savings',
                    _formatCurrency(savings),
                    _savingsColor,
                    Icons.account_balance_wallet,
                    subtitle: 'Available Balance',
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        await _verifyBalanceCalculation();
                        await _fetchSavingsData();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showActiveLoans(),
              child: _buildStatCard(
                'Active Loans',
                activeLoans.toString(),
                _activeLoansColor,
                Icons.credit_card,
                subtitle: 'Currently Active',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - Loan status
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            GestureDetector(
              onTap: () => _showPendingLoans(),
              child: _buildStatCard(
                'Pending Loans',
                pendingLoans.toString(),
                Colors.blue,
                Icons.pending_actions,
                subtitle: 'Awaiting Approval',
              ),
            ),
            GestureDetector(
              onTap: () => _showOverdueLoans(),
              child: _buildStatCard(
                'Overdue Loans',
                overdueLoans.toString(),
                _overdueColor,
                Icons.warning,
                subtitle: 'Requires Attention',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Third row - Transaction summary
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            GestureDetector(
              onTap: () => _showDepositHistory(),
              child: _buildStatCard(
                'Total Deposits',
                _formatCurrency(totalDeposits),
                Colors.green,
                Icons.trending_up,
                subtitle: 'All Time',
              ),
            ),
            GestureDetector(
              onTap: () => _showWithdrawalHistory(),
              child: _buildStatCard(
                'Total Withdrawals',
                _formatCurrency(totalWithdrawals),
                Colors.red,
                Icons.trending_down,
                subtitle: 'All Time',
              ),
            ),
          ],
        ),
        // const SizedBox(height: 12),
        // Fourth row - Additional info
        // GridView.count(
        //   shrinkWrap: true,
        //   physics: const NeverScrollableScrollPhysics(),
        //   crossAxisCount: 2,
        //   childAspectRatio: childAspectRatio,
        //   mainAxisSpacing: 12,
        //   crossAxisSpacing: 12,
        //   children: [
        //     GestureDetector(
        //       onTap: () => _showTotalDueDetails(),
        //       child: _buildEnhancedTotalDueCard(totalDue),
        //     ),
        //     GestureDetector(
        //       onTap: () => setState(() => _currentIndex = 2),
        //       child: _buildStatCard(
        //         'Recent Transactions',
        //         recentTransactions.toString(),
        //         Colors.purple,
        //         Icons.receipt_long,
        //         subtitle: 'Last 5 Transactions',
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildEnhancedTotalDueCard(double totalDue) {
    // Calculate breakdown of total due
    final overdueLoans = _loans.where((loan) {
      if (loan.status != 'Active' && loan.status != 'Approved') return false;
      final nextPaymentDate = loan.payments.isEmpty
          ? loan.disbursementDate.add(const Duration(days: 30))
          : loan.payments.last.date.add(const Duration(days: 30));
      return nextPaymentDate.difference(DateTime.now()).inDays < 0;
    }).toList();

    final dueSoonLoans = _loans.where((loan) {
      if (loan.status != 'Active' && loan.status != 'Approved') return false;
      final nextPaymentDate = loan.payments.isEmpty
          ? loan.disbursementDate.add(const Duration(days: 30))
          : loan.payments.last.date.add(const Duration(days: 30));
      final daysUntilPayment = nextPaymentDate
          .difference(DateTime.now())
          .inDays;
      return daysUntilPayment <= 7 && daysUntilPayment >= 0;
    }).toList();

    final overdueAmount = overdueLoans.fold(0.0, (acc, loan) {
      final nextPaymentDate = loan.payments.isEmpty
          ? loan.disbursementDate.add(const Duration(days: 30))
          : loan.payments.last.date.add(const Duration(days: 30));
      final daysUntilPayment = nextPaymentDate
          .difference(DateTime.now())
          .inDays;
      final overdueMonths = (daysUntilPayment.abs() / 30).ceil();
      return acc + (loan.monthlyPayment * overdueMonths);
    });

    final dueSoonAmount = dueSoonLoans.fold(
      0.0,
      (acc, loan) => acc + loan.monthlyPayment,
    );

    // Determine the color based on the breakdown
    Color cardColor = _totalDueColor;
    String statusText = 'Loan Repayments';

    if (overdueAmount > 0) {
      cardColor = Colors.red;
      statusText =
          'Overdue: ${overdueLoans.length} loan${overdueLoans.length > 1 ? 's' : ''}';
    } else if (dueSoonAmount > 0) {
      cardColor = Colors.orange;
      statusText =
          'Due Soon: ${dueSoonLoans.length} loan${dueSoonLoans.length > 1 ? 's' : ''}';
    } else if (totalDue > 0) {
      cardColor = _totalDueColor;
      statusText = 'Upcoming Payments';
    } else {
      cardColor = Colors.green;
      statusText = 'All Caught Up';
    }

    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  totalDue > 0 ? Icons.payment : Icons.check_circle,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
                if (overdueAmount > 0) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 20,
                  ),
                ],
              ],
            ),
            // SizedBox(height: isSmallScreen ? 6 : 8),
            // Flexible(
            //   child: Text(
            //     'Total Due',
            //     style: GoogleFonts.poppins(
            //       color: Colors.white,
            //       fontSize: isSmallScreen ? 12 : 14,
            //       fontWeight: FontWeight.w500,
            //     ),
            //     textAlign: TextAlign.center,
            //     maxLines: 2,
            //     overflow: TextOverflow.ellipsis,
            //   ),
            // ),
            // const SizedBox(height: 4),
            // Flexible(
            //   child: FittedBox(
            //     fit: BoxFit.scaleDown,
            //     child: Text(
            //       _formatCurrency(totalDue),
            //       style: GoogleFonts.poppins(
            //         color: Colors.white,
            //         fontSize: isSmallScreen ? 16 : 20,
            //         fontWeight: FontWeight.bold,
            //       ),
            //       textAlign: TextAlign.center,
            //       maxLines: 1,
            //       overflow: TextOverflow.ellipsis,
            //     ),
            //   ),
            // ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                statusText,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isSmallScreen ? 9 : 10,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (overdueAmount > 0 || dueSoonAmount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  overdueAmount > 0
                      ? '${overdueLoans.length} overdue'
                      : '${dueSoonLoans.length} due soon',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 8 : 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    String? subtitle,
  }) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: isSmallScreen ? 24 : 28),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isSmallScreen ? 9 : 10,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Deposit',
                  Icons.add_circle,
                  Colors.green,
                  _showDepositDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Withdraw',
                  Icons.remove_circle,
                  _isBlindUser ? Colors.grey : Colors.orange,
                  _isBlindUser
                      ? () {
                          // This functionality has been removed as per instructions
                        }
                      : _initiateWithdrawal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Apply Loan',
                  Icons.credit_card,
                  _primaryColor,
                  _showLoanApplication,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Transactions',
                  Icons.receipt_long,
                  Colors.purple,
                  () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isDisabled = color == Colors.grey;

    return Container(
      height: isSmallScreen ? 70 : 80,
      decoration: BoxDecoration(
        color: color.withOpacity(isDisabled ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(isDisabled ? 0.2 : 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isDisabled ? Colors.grey[400] : color,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isDisabled ? Colors.grey[400] : color,
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDisabled && title == 'Withdraw') ...[
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    'Not Available',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyPaymentsSection() {
    final activeLoans = _loans
        .where((loan) => loan.status == 'Active' || loan.status == 'Approved')
        .toList();

    if (activeLoans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 40, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              'No Active Loans',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You have no active loans requiring monthly payments',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payment, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Loan Payments',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textSecondary,
                      ),
                    ),
                    Text(
                      '${activeLoans.length} active loan${activeLoans.length > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${activeLoans.length}',
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
          ...activeLoans.map((loan) => _buildMonthlyPaymentCard(loan)).toList(),
        ],
      ),
    );
  }

  Widget _buildMonthlyPaymentCard(Loan loan) {
    final nextPaymentDate = loan.payments.isEmpty
        ? loan.disbursementDate.add(const Duration(days: 30))
        : loan.payments.last.date.add(const Duration(days: 30));
    final daysUntilPayment = nextPaymentDate.difference(DateTime.now()).inDays;
    final nextPaymentAmount = loan.nextPaymentAmount;
    final isOverdue = daysUntilPayment < 0;
    final isDueSoon = daysUntilPayment <= 7 && daysUntilPayment >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.withOpacity(0.05)
            : isDueSoon
            ? Colors.orange.withOpacity(0.05)
            : Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withOpacity(0.3)
              : isDueSoon
              ? Colors.orange.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red.withOpacity(0.1)
                      : isDueSoon
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOverdue
                      ? Icons.warning
                      : isDueSoon
                      ? Icons.schedule
                      : Icons.check_circle,
                  color: isOverdue
                      ? Colors.red
                      : isDueSoon
                      ? Colors.orange
                      : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan ${loan.id.substring(0, 8)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    Text(
                      '${loan.type} Loan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red
                      : isDueSoon
                      ? Colors.orange
                      : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverdue
                      ? 'OVERDUE'
                      : isDueSoon
                      ? 'DUE SOON'
                      : 'ON TRACK',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Payment',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatCurrency(nextPaymentAmount),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining Balance',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatCurrency(loan.remainingBalance),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment date and action
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Payment Date',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, y').format(nextPaymentDate),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isOverdue
                            ? Colors.red
                            : isDueSoon
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    Text(
                      isOverdue
                          ? 'Overdue by ${daysUntilPayment.abs()} days'
                          : isDueSoon
                          ? 'Due in $daysUntilPayment days'
                          : 'In ${daysUntilPayment} days',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isOverdue
                            ? Colors.red
                            : isDueSoon
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showEnhancedPaymentDialog(loan),
                icon: Icon(
                  isOverdue ? Icons.payment : Icons.payment_outlined,
                  size: 16,
                ),
                label: Text(
                  isOverdue ? 'Pay Now' : 'Make Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverdue
                      ? Colors.red
                      : isDueSoon
                      ? Colors.orange
                      : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEnhancedPaymentDialog(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.orange[600]),
            const SizedBox(width: 8),
            Text(
              'Loan Payment',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentSummaryCard(loan),
            const SizedBox(height: 16),
            Text(
              'Payment Options',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'Pay Full Amount',
              _formatCurrency(loan.nextPaymentAmount),
              Icons.payment,
              Colors.green,
              () {
                Navigator.pop(context);
                _makePayment(loan);
              },
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              'Pay Partial Amount',
              'Custom amount',
              Icons.edit,
              Colors.blue,
              () {
                Navigator.pop(context);
                _showPartialPaymentDialog(loan);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(Loan loan) {
    final nextPaymentDate = loan.payments.isEmpty
        ? loan.disbursementDate.add(const Duration(days: 30))
        : loan.payments.last.date.add(const Duration(days: 30));
    final daysUntilPayment = nextPaymentDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilPayment < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.credit_card,
                color: isOverdue ? Colors.red : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Loan ${loan.id.substring(0, 8)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   'Monthly Payment',
                  //   style: GoogleFonts.poppins(
                  //     fontSize: 12,
                  //     color: Colors.grey[600],
                  //   ),
                  // ),
                  Text(
                    _formatCurrency(loan.nextPaymentAmount),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Due Date',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(nextPaymentDate),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isOverdue ? Colors.red : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showPartialPaymentDialog(Loan loan) {
    final amountController = TextEditingController();
    amountController.text = loan.nextPaymentAmount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              'Partial Payment',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the amount you want to pay:',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (UGX)',
                prefixText: 'UGX ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText:
                    'Maximum: ${_formatCurrency(loan.remainingBalance)}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0 && amount <= loan.remainingBalance) {
                Navigator.pop(context);
                _makePartialPayment(loan, amount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      amount > loan.remainingBalance
                          ? 'Amount cannot exceed remaining balance'
                          : 'Please enter a valid amount',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Pay',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _makePartialPayment(Loan loan, double amount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomoPaymentPage(
          amount: amount,
          onPaymentComplete: (success) async {
            if (success) {
              try {
                final paymentRef = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .collection('loans')
                    .doc(loan.id)
                    .collection('payments')
                    .add({
                      'amount': amount,
                      'date': DateTime.now(),
                      'reference':
                          'MOMO-${DateTime.now().millisecondsSinceEpoch}',
                      'type': 'Partial Payment',
                    });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .collection('loans')
                    .doc(loan.id)
                    .update({
                      'remainingBalance': loan.remainingBalance - amount,
                    });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .collection('transactions')
                    .add({
                      'amount': amount,
                      'date': DateTime.now(),
                      'type': 'Loan Repayment',
                      'status': 'Completed',
                      'method': 'Mobile Money',
                      'loanId': loan.id,
                      'paymentId': paymentRef.id,
                      'description':
                          'Partial payment for loan ${loan.id.substring(0, 8)}',
                    });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .collection('notifications')
                    .add({
                      'title': 'Partial Payment Received',
                      'message':
                          'Your partial payment of ${_formatCurrency(amount)} for loan ${loan.id.substring(0, 8)} has been received',
                      'date': DateTime.now(),
                      'type': NotificationType.payment.index,
                      'isRead': false,
                    });

                _fetchLoansData();
                _fetchNotifications();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Partial payment of ${_formatCurrency(amount)} successful!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error recording payment: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildDuePaymentsSection() {
    final duePayments = _loans
        .where((loan) => loan.status == 'Active' || loan.status == 'Overdue')
        .toList();

    if (duePayments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 40, color: Colors.green),
            const SizedBox(height: 12),
            Text(
              'No Due Payments',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You have no active or overdue loans at this time',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.green.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Loan Repayments Due',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: duePayments
                .map((loan) => _buildLoanDueCard(loan))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDueCard(Loan loan) {
    final isOverdue = loan.status == 'Overdue';
    final nextPaymentDate = loan.payments.isEmpty
        ? loan.disbursementDate.add(const Duration(days: 30))
        : loan.payments.last.date.add(const Duration(days: 30));
    final daysRemaining = nextPaymentDate.difference(DateTime.now()).inDays;
    final nextPaymentAmount = loan.totalRepayment / loan.repaymentPeriod;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red : Colors.orange,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with overflow protection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Loan ${loan.id.substring(0, 8)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(nextPaymentAmount),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : Colors.orange,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverdue ? 'OVERDUE' : 'DUE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action row with overflow protection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isOverdue
                      ? 'Overdue by ${daysRemaining.abs()} days'
                      : 'Due in $daysRemaining days',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.orange,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _makePayment(loan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverdue ? Colors.red : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Pay Now',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No Recent Transactions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Your transaction history will appear here',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with overflow protection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: _primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recent Transactions',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 2),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Transaction list with overflow protection
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _transactions
                .take(3)
                .map((txn) => _buildTransactionCard(txn))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon container with fixed size
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(txn.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTransactionIcon(txn.type),
              color: _getStatusColor(txn.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Main content area with overflow protection
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  txn.type,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('MMM d').format(txn.date)} • ${txn.method}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount and status with overflow protection
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatCurrency(txn.amount),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(txn.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    txn.status,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(txn.status),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return Icons.add_circle;
      case 'withdrawal':
        return Icons.remove_circle;
      case 'loan repayment':
        return Icons.credit_card;
      default:
        return Icons.receipt;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
        .where((loan) => loan.status == 'Active' || loan.status == 'Approved')
        .toList();
    showDialog(
      context: context,
      builder: (context) => _buildEnhancedLoanDetailsDialog(
        loans: activeLoans,
        title: 'Active Loans',
        icon: Icons.check_circle,
        color: Colors.green,
        showPaymentButton: true,
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
    // Calculate detailed breakdown
    final overdueLoans = _loans.where((loan) {
      if (loan.status != 'Active' && loan.status != 'Approved') return false;
      final nextPaymentDate = loan.payments.isEmpty
          ? loan.disbursementDate.add(const Duration(days: 30))
          : loan.payments.last.date.add(const Duration(days: 30));
      return nextPaymentDate.difference(DateTime.now()).inDays < 0;
    }).toList();

    final dueSoonLoans = _loans.where((loan) {
      if (loan.status != 'Active' && loan.status != 'Approved') return false;
      final nextPaymentDate = loan.payments.isEmpty
          ? loan.disbursementDate.add(const Duration(days: 30))
          : loan.payments.last.date.add(const Duration(days: 30));
      final daysUntilPayment = nextPaymentDate
          .difference(DateTime.now())
          .inDays;
      return daysUntilPayment <= 7 && daysUntilPayment >= 0;
    }).toList();

    final totalDue = _calculateTotalDue();

    showDialog(
      context: context,
      builder: (context) => _buildEnhancedTotalDueDialog(
        totalDue: totalDue,
        overdueLoans: overdueLoans,
        dueSoonLoans: dueSoonLoans,
      ),
    );
  }

  void _showPendingLoans() {
    final pendingLoans = _loans
        .where(
          (loan) =>
              loan.status == 'Pending' || loan.status == 'Pending Approval',
        )
        .toList();
    showDialog(
      context: context,
      builder: (context) => _buildEnhancedLoanDetailsDialog(
        loans: pendingLoans,
        title: 'Pending Loans',
        icon: Icons.pending_actions,
        color: Colors.orange,
        showPaymentButton: false,
      ),
    );
  }

  Widget _buildEnhancedLoanDetailsDialog({
    required List<Loan> loans,
    required String title,
    required IconData icon,
    required Color color,
    required bool showPaymentButton,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          '${loans.length} loan${loans.length > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: color.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: color),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: loans.isEmpty
                  ? _buildLoanEmptyState(title, icon, color)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: loans.length,
                      itemBuilder: (context, index) {
                        final loan = loans[index];
                        return _buildEnhancedLoanCard(
                          loan: loan,
                          index: index,
                          showPaymentButton: showPaymentButton,
                          color: color,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanEmptyState(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No $title',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.toLowerCase().contains('active')
                ? 'You have no active loans at this time'
                : 'You have no pending loan applications',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLoanCard({
    required Loan loan,
    required int index,
    required bool showPaymentButton,
    required Color color,
  }) {
    final nextPaymentDate = loan.payments.isEmpty
        ? loan.disbursementDate.add(const Duration(days: 30))
        : loan.payments.last.date.add(const Duration(days: 30));
    final daysUntilPayment = nextPaymentDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilPayment < 0;
    final isDueSoon = daysUntilPayment <= 7 && daysUntilPayment >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.credit_card, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan ${loan.id.substring(0, 8)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textSecondary,
                        ),
                      ),
                      Text(
                        '${loan.type} Loan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    loan.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Loan Amounts
                // Row(
                //   children: [
                //     Expanded(
                //       child: _buildDetailItem(
                //         'Original Amount',
                //         _formatCurrency(loan.amount),
                //         Icons.account_balance_wallet,
                //         Colors.blue,
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     Expanded(
                //       child: _buildDetailItem(
                //         'Remaining Balance',
                //         _formatCurrency(loan.remainingBalance),
                //         Icons.balance,
                //         Colors.orange,
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 12),

                // // Payment Details
                // if (showPaymentButton) ...[
                //   Row(
                //     children: [
                //       Expanded(
                //         child: _buildDetailItem(
                //           'Monthly Payment',
                //           _formatCurrency(loan.monthlyPayment),
                //           Icons.payment,
                //           Colors.green,
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //       Expanded(
                //         child: _buildDetailItem(
                //           'Interest Rate',
                //           '${loan.interestRate}% p.a.',
                //           Icons.trending_up,
                //           Colors.purple,
                //         ),
                //       ),
                //     ],
                //   ),
                //   const SizedBox(height: 12),
                // ],

                // Dates
                // Row(
                //   children: [
                //     Expanded(
                //       child: _buildDetailItem(
                //         'Application Date',
                //         DateFormat('MMM d, y').format(loan.disbursementDate),
                //         Icons.calendar_today,
                //         Colors.grey,
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     Expanded(
                //       child: _buildDetailItem(
                //         'Due Date',
                //         DateFormat('MMM d, y').format(loan.dueDate),
                //         Icons.event,
                //         Colors.red,
                //       ),
                //     ),
                //   ],
                // ),

                // Payment Status (for active loans)
                if (showPaymentButton) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.withOpacity(0.1)
                          : isDueSoon
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOverdue
                            ? Colors.red.withOpacity(0.3)
                            : isDueSoon
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOverdue
                              ? Icons.warning
                              : isDueSoon
                              ? Icons.schedule
                              : Icons.check_circle,
                          color: isOverdue
                              ? Colors.red
                              : isDueSoon
                              ? Colors.orange
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Payment',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, y').format(nextPaymentDate),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isOverdue
                                      ? Colors.red
                                      : isDueSoon
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                              Text(
                                isOverdue
                                    ? 'Overdue by ${daysUntilPayment.abs()} days'
                                    : isDueSoon
                                    ? 'Due in $daysUntilPayment days'
                                    : 'In $daysUntilPayment days',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? Colors.red
                                      : isDueSoon
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Payment History (for active loans)
                if (showPaymentButton && loan.payments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPaymentHistorySection(loan),
                ],

                // Action Buttons
                if (showPaymentButton) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEnhancedPaymentDialog(loan);
                          },
                          icon: Icon(
                            isOverdue ? Icons.payment : Icons.payment_outlined,
                            size: 16,
                          ),
                          label: Text(
                            isOverdue ? 'Pay Now' : 'Make Payment',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOverdue
                                ? Colors.red
                                : isDueSoon
                                ? Colors.orange
                                : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showLoanDetailsDialog(loan);
                          },
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: Text(
                            'Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection(Loan loan) {
    final recentPayments = loan.payments.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                'Recent Payments',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentPayments
              .map(
                (payment) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d').format(payment.date),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatCurrency(payment.amount),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  void _showLoanDetailsDialog(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              'Loan Details',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoanDetailRow('Loan ID', loan.id.substring(0, 8)),
            _buildLoanDetailRow('Type', loan.type),
            _buildLoanDetailRow(
              'Original Amount',
              _formatCurrency(loan.amount),
            ),
            _buildLoanDetailRow(
              'Remaining Balance',
              _formatCurrency(loan.remainingBalance),
            ),
            _buildLoanDetailRow(
              'Monthly Payment',
              _formatCurrency(loan.monthlyPayment),
            ),
            _buildLoanDetailRow(
              'Interest Rate',
              '${loan.interestRate}% per annum',
            ),
            _buildLoanDetailRow(
              'Repayment Period',
              '${loan.repaymentPeriod} months',
            ),
            _buildLoanDetailRow(
              'Total Repayment',
              _formatCurrency(loan.totalRepayment),
            ),
            _buildLoanDetailRow(
              'Application Date',
              DateFormat('MMM d, y').format(loan.disbursementDate),
            ),
            _buildLoanDetailRow(
              'Due Date',
              DateFormat('MMM d, y').format(loan.dueDate),
            ),
            _buildLoanDetailRow('Status', loan.status),
            _buildLoanDetailRow('Payments Made', '${loan.payments.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTotalDueDialog({
    required double totalDue,
    required List<Loan> overdueLoans,
    required List<Loan> dueSoonLoans,
  }) {
    final overdueAmount = overdueLoans.fold(0.0, (acc, loan) {
      final nextPaymentDate = loan.payments.isEmpty
          ? loan.disbursementDate.add(const Duration(days: 30))
          : loan.payments.last.date.add(const Duration(days: 30));
      final daysUntilPayment = nextPaymentDate
          .difference(DateTime.now())
          .inDays;
      final overdueMonths = (daysUntilPayment.abs() / 30).ceil();
      return acc + (loan.monthlyPayment * overdueMonths);
    });

    final dueSoonAmount = dueSoonLoans.fold(
      0.0,
      (acc, loan) => acc + loan.monthlyPayment,
    );

    // Determine the primary color based on the breakdown
    Color primaryColor = _totalDueColor;
    if (overdueAmount > 0) {
      primaryColor = Colors.red;
    } else if (dueSoonAmount > 0) {
      primaryColor = Colors.orange;
    } else if (totalDue == 0) {
      primaryColor = Colors.green;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      totalDue > 0 ? Icons.payment : Icons.check_circle,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Due Breakdown',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          totalDue > 0
                              ? '${overdueLoans.length + dueSoonLoans.length} loans require attention'
                              : 'All payments are up to date',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: primaryColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: primaryColor),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount Due',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                              Text(
                                _formatCurrency(totalDue),
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (totalDue > 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildBreakdownItem(
                                    'Overdue',
                                    overdueAmount,
                                    overdueLoans.length,
                                    Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildBreakdownItem(
                                    'Due Soon',
                                    dueSoonAmount,
                                    dueSoonLoans.length,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Overdue Loans Section
                    if (overdueLoans.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Overdue Loans',
                        Icons.warning,
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      ...overdueLoans
                          .map(
                            (loan) => _buildLoanSummaryCard(
                              loan: loan,
                              isOverdue: true,
                              onPayment: () {
                                Navigator.pop(context);
                                _showEnhancedPaymentDialog(loan);
                              },
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 20),
                    ],

                    // Due Soon Loans Section
                    if (dueSoonLoans.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Due Soon Loans',
                        Icons.schedule,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      ...dueSoonLoans
                          .map(
                            (loan) => _buildLoanSummaryCard(
                              loan: loan,
                              isOverdue: false,
                              onPayment: () {
                                Navigator.pop(context);
                                _showEnhancedPaymentDialog(loan);
                              },
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 20),
                    ],

                    // No Payments Due
                    if (totalDue == 0) ...[
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'All Caught Up!',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You have no overdue or upcoming payments',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    double amount,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '$count loan${count > 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLoanSummaryCard({
    required Loan loan,
    required bool isOverdue,
    required VoidCallback onPayment,
  }) {
    final nextPaymentDate = loan.payments.isEmpty
        ? loan.disbursementDate.add(const Duration(days: 30))
        : loan.payments.last.date.add(const Duration(days: 30));
    final daysUntilPayment = nextPaymentDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isOverdue ? Colors.red : Colors.orange).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isOverdue ? Colors.red : Colors.orange).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan ${loan.id.substring(0, 8)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
                Text(
                  _formatCurrency(loan.monthlyPayment),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red : Colors.orange,
                  ),
                ),
                Text(
                  isOverdue
                      ? 'Overdue by ${daysUntilPayment.abs()} days'
                      : 'Due in $daysUntilPayment days',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isOverdue ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isOverdue ? 'Pay Now' : 'Make Payment',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositHistory() {
    final deposits = _savingsHistory
        .where((item) => item.type.toLowerCase().contains('deposit'))
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.green),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Deposit History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (deposits.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Deposits:'),
                      Flexible(
                        child: Text(
                          _formatCurrency(
                            deposits.fold(
                              0.0,
                              (sum, item) => sum + item.amount,
                            ),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: deposits.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No deposits found'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: deposits.length,
                        itemBuilder: (context, index) {
                          final deposit = deposits[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.trending_up,
                                color: Colors.green,
                              ),
                              title: Flexible(
                                child: Text(
                                  _formatCurrency(deposit.amount),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat.yMMMd().add_jm().format(
                                  deposit.date,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Flexible(
                                child: Text(
                                  deposit.type,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawalHistory() {
    final withdrawals = _savingsHistory
        .where((item) => item.type.toLowerCase().contains('withdraw'))
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_down, color: Colors.red),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Withdrawal History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (withdrawals.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Withdrawals:'),
                      Flexible(
                        child: Text(
                          _formatCurrency(
                            withdrawals.fold(
                              0.0,
                              (sum, item) => sum + item.amount,
                            ),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: withdrawals.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No withdrawals found'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: withdrawals.length,
                        itemBuilder: (context, index) {
                          final withdrawal = withdrawals[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.trending_down,
                                color: Colors.red,
                              ),
                              title: Flexible(
                                child: Text(
                                  _formatCurrency(withdrawal.amount),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat.yMMMd().add_jm().format(
                                  withdrawal.date,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Flexible(
                                child: Text(
                                  withdrawal.type,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 20),
          _buildSavingsBalanceCard(),
          const SizedBox(height: 20),
          _buildEnhancedTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildSavingsBalanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[50]!, Colors.green[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.savings, size: 48, color: Colors.green[700]),
              ),
              const SizedBox(height: 16),
              Text(
                'Savings Account Balance',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatCurrency(_currentSavings),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _showEnhancedDepositDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Make Deposit',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildEnhancedTransactionHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textSecondary,
                  ),
                ),
                if (_transactions.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_transactions.isEmpty)
              _buildEmptyTransactionState()
            else
              _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: _transactions
          .take(5)
          .map((txn) => _buildEnhancedTransactionCard(txn))
          .toList(),
    );
  }

  Widget _buildEnhancedTransactionCard(Transaction txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor(txn.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTransactionIcon(txn.type),
              color: _getStatusColor(txn.status),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.type,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat('MMM d, y').format(txn.date),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.payment, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        txn.method,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatCurrency(txn.amount),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(txn.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getStatusColor(txn.status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  txn.status,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(txn.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEnhancedDepositDialog() async {
    final amountController = TextEditingController();
    String selectedMethod = 'Mobile Money';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              'Make Deposit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (UGX)',
                  prefixText: 'UGX ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green[600]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green[600]!),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Mobile Money',
                    child: Row(
                      children: [
                        Icon(Icons.phone_android, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Mobile Money'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Bank Transfer',
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Bank Transfer'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedMethod = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                _showDepositConfirmationDialog(amount, selectedMethod);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Keep the original deposit dialog for backward compatibility
  Future<void> _showDepositDialog() async {
    await _showEnhancedDepositDialog();
  }

  // Show deposit confirmation dialog for normal users
  Future<void> _showDepositConfirmationDialog(
    double amount,
    String method,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildEnhancedDialog(
        title: 'Confirm Deposit',
        icon: Icons.verified,
        iconColor: Colors.green[600]!,
        content: _buildTransactionSummaryCard(
          amount: amount,
          method: method,
          type: 'Deposit',
          color: Colors.green,
        ),
        message:
            'Please confirm this deposit transaction. This action cannot be undone.',
        primaryAction: 'Confirm Deposit',
        secondaryAction: 'Cancel',
        onPrimaryAction: () {
          Navigator.pop(context);
          _processDeposit(amount, method);
        },
        onSecondaryAction: () => Navigator.pop(context),
        primaryColor: Colors.green[600]!,
      ),
    );
  }

  Future<void> _processDeposit(double amount, String method) async {
    // Voice confirmation removed as per instructions
    // Proceed with normal deposit flow

    // Voice confirmation logic removed as per instructions

    // Voice confirmation state removed as per instructions

    // Generate unique transaction ID
    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      print('🔄 Processing deposit: $amount via $method');
      print('📝 Transaction ID: $transactionId');
      print('👤 User ID: $memberId');

      // Start transaction batch for atomic operations
      final batch = FirebaseFirestore.instance.batch();

      // Add to savings collection
      final savingsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('savings')
          .doc(transactionId);

      batch.set(savingsRef, {
        'amount': amount,
        'date': FieldValue.serverTimestamp(),
        'type': 'Deposit',
        'method': method,
        'transactionId': transactionId,
        'userId': memberId,
        'status': 'Completed',
      });

      // Add to transactions collection
      final transactionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .doc(transactionId);

      batch.set(transactionRef, {
        'amount': amount,
        'date': FieldValue.serverTimestamp(),
        'type': 'Deposit',
        'status': 'Completed',
        'method': method,
        'transactionId': transactionId,
        'userId': memberId,
        'description': 'Deposit via $method',
      });

      // Commit the batch
      await batch.commit();

      print('✅ Deposit transaction committed successfully');
      print('📊 Savings record created: ${savingsRef.id}');
      print('📊 Transaction record created: ${transactionRef.id}');

      // Update local state
      setState(() {
        _currentSavings += amount;
      });

      // Validate the transaction
      await _validateTransaction(transactionId, 'Deposit', amount, method);

      // Voice feedback removed as per instructions

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deposit of ${_formatCurrency(amount)} successful'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh data
      await _fetchSavingsData();
      await _fetchTransactionHistory();
    } catch (e) {
      print('❌ Error processing deposit: $e');
      // Voice error feedback removed as per instructions
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing deposit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Validate transaction after processing
  Future<void> _validateTransaction(
    String transactionId,
    String type,
    double amount,
    String method,
  ) async {
    try {
      print('🔍 Validating transaction: $transactionId');

      // Check if transaction exists
      final transactionDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        print('❌ Transaction validation failed: Transaction not found');
        return;
      }

      final transactionData = transactionDoc.data()!;

      // Validate transaction data
      if (transactionData['amount'] != amount) {
        print('❌ Transaction validation failed: Amount mismatch');
        print('Expected: $amount, Actual: ${transactionData['amount']}');
        return;
      }

      if (transactionData['type'] != type) {
        print('❌ Transaction validation failed: Type mismatch');
        print('Expected: $type, Actual: ${transactionData['type']}');
        return;
      }

      if (transactionData['method'] != method) {
        print('❌ Transaction validation failed: Method mismatch');
        print('Expected: $method, Actual: ${transactionData['method']}');
        return;
      }

      if (transactionData['status'] != 'Completed') {
        print('❌ Transaction validation failed: Status not completed');
        print('Actual status: ${transactionData['status']}');
        return;
      }

      // For deposits, check if savings record exists
      if (type == 'Deposit') {
        final savingsDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .collection('savings')
            .doc(transactionId)
            .get();

        if (!savingsDoc.exists) {
          print('❌ Transaction validation failed: Savings record not found');
          return;
        }

        final savingsData = savingsDoc.data()!;
        if (savingsData['amount'] != amount) {
          print('❌ Transaction validation failed: Savings amount mismatch');
          print('Expected: $amount, Actual: ${savingsData['amount']}');
          return;
        }
      }

      print('✅ Transaction validation successful: $transactionId');
    } catch (e) {
      print('❌ Error validating transaction: $e');
    }
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

  void _filterTransactions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    String selectedType = 'All';
    String selectedStatus = 'All';
    DateTime? startDate;
    DateTime? endDate;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: _primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Filter Transactions',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textSecondary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Transaction Type Filter
                        _buildFilterSection(
                          'Transaction Type',
                          Icons.category,
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items:
                                [
                                      'All',
                                      'Deposit',
                                      'Withdrawal',
                                      'Loan Payment',
                                      'Fee',
                                    ]
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type,
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Status Filter
                        _buildFilterSection(
                          'Status',
                          Icons.info_outline,
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: ['All', 'Completed', 'Pending', 'Failed']
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Date Range Filter
                        _buildFilterSection(
                          'Date Range',
                          Icons.calendar_today,
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDateButton(
                                      'Start Date',
                                      startDate,
                                      Icons.calendar_today,
                                      () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now().subtract(
                                            const Duration(days: 30),
                                          ),
                                          firstDate: DateTime.now().subtract(
                                            const Duration(days: 365),
                                          ),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          setState(() {
                                            startDate = date;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDateButton(
                                      'End Date',
                                      endDate,
                                      Icons.calendar_today,
                                      () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime.now().subtract(
                                            const Duration(days: 365),
                                          ),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          setState(() {
                                            endDate = date;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (startDate != null || endDate != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: _primaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          startDate != null && endDate != null
                                              ? '${DateFormat('MMM d, y').format(startDate!)} - ${DateFormat('MMM d, y').format(endDate!)}'
                                              : startDate != null
                                              ? 'From: ${DateFormat('MMM d, y').format(startDate!)}'
                                              : 'To: ${DateFormat('MMM d, y').format(endDate!)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: _primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedType = 'All';
                              selectedStatus = 'All';
                              startDate = null;
                              endDate = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters(
                              selectedType,
                              selectedStatus,
                              startDate,
                              endDate,
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDateButton(
    String label,
    DateTime? selectedDate,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selectedDate != null
                      ? _primaryColor
                      : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? DateFormat('MMM d, y').format(selectedDate)
                        : label,
                    style: GoogleFonts.poppins(
                      color: selectedDate != null
                          ? _primaryColor
                          : Colors.grey[600],
                      fontWeight: selectedDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyFilters(
    String type,
    String status,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    setState(() {
      _currentIndex = 2; // Switch to transactions tab
    });

    // Apply filters to transactions
    final filteredTransactions = _transactions.where((txn) {
      // Type filter
      if (type != 'All' && txn.type != type) return false;

      // Status filter
      if (status != 'All' && txn.status != status) return false;

      // Date range filter
      if (startDate != null && txn.date.isBefore(startDate)) return false;
      if (endDate != null && txn.date.isAfter(endDate)) return false;

      return true;
    }).toList();

    // Show filtered results
    _showFilteredResults(
      filteredTransactions,
      type,
      status,
      startDate,
      endDate,
    );
  }

  void _showFilteredResults(
    List<Transaction> filteredTransactions,
    String type,
    String status,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Filtered Transactions',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (type != 'All')
                          _buildFilterChip('Type: $type', Icons.category),
                        if (status != 'All')
                          _buildFilterChip(
                            'Status: $status',
                            Icons.info_outline,
                          ),
                        if (startDate != null)
                          _buildFilterChip(
                            'From: ${DateFormat('MMM d, y').format(startDate)}',
                            Icons.calendar_today,
                          ),
                        if (endDate != null)
                          _buildFilterChip(
                            'To: ${DateFormat('MMM d, y').format(endDate)}',
                            Icons.calendar_today,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${filteredTransactions.length} transaction${filteredTransactions.length == 1 ? '' : 's'} found',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction List
              Flexible(
                child: filteredTransactions.isEmpty
                    ? _buildTransactionEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildTransactionCard(
                            filteredTransactions[index],
                          ),
                        ),
                      ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportFilteredResults(filteredTransactions);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Export',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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

  Widget _buildFilterChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Transactions Found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters to see more results',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _exportFilteredResults(List<Transaction> transactions) {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${transactions.length} transactions...'),
        backgroundColor: _primaryColor,
      ),
    );
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

  // Add withdrawal functionality (disabled for blind users)
  void _initiateWithdrawal() {
    if (_isBlindUser) {
      // This functionality has been removed as per instructions
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _buildWithdrawalDialog(),
    );
  }

  Widget _buildWithdrawalDialog() {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedMethod = 'MTN MoMo';

    return AlertDialog(
      title: const Text('Withdraw Funds'),
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
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixText: '+256 ',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedMethod,
            decoration: const InputDecoration(labelText: 'Withdrawal Method'),
            items: ['MTN MoMo', 'Airtel Money', 'Bank Transfer']
                .map(
                  (method) =>
                      DropdownMenuItem(value: method, child: Text(method)),
                )
                .toList(),
            onChanged: (value) {
              selectedMethod = value!;
            },
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
            final amount = double.tryParse(amountController.text);
            final phone = phoneController.text;

            if (amount != null && amount > 0 && phone.isNotEmpty) {
              Navigator.pop(context);
              _confirmWithdrawal(amount, phone, selectedMethod);
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter valid amount and phone number'),
                ),
              );
            }
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }

  void _confirmWithdrawal(double amount, String phone, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${_formatCurrency(amount)}'),
            Text('Phone: +256 $phone'),
            Text('Method: $method'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to proceed with this withdrawal?',
              style: TextStyle(fontWeight: FontWeight.w500),
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
              Navigator.pop(context);
              _processWithdrawal(amount, phone, method);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWithdrawal(
    double amount,
    String phone,
    String method,
  ) async {
    String? transactionId;
    String? referenceId;

    try {
      // Validate withdrawal amount
      if (amount <= 0) {
        _showErrorDialog(
          'Invalid Amount',
          'Withdrawal amount must be greater than zero.',
        );
        return;
      }

      // Check if user has sufficient balance
      if (amount > _currentSavings) {
        _showErrorDialog(
          'Insufficient Balance',
          'You do not have sufficient balance for this withdrawal. Current balance: ${_formatCurrency(_currentSavings)}',
        );
        return;
      }

      // Generate transaction ID and reference
      transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      referenceId = 'WITHDRAWAL_$transactionId';

      // Show enhanced loading dialog
      _showWithdrawalProgressDialog(amount, phone, method);

      // Process withdrawal based on method
      Map<String, dynamic> result;
      if (method == 'MTN MoMo') {
        result = await _processMTNWithdrawal(amount, phone, referenceId);
      } else {
        result = {
          'success': false,
          'message': 'Withdrawal method not yet supported',
        };
      }

      // Close loading dialog
      Navigator.pop(context);

      if (result['success']) {
        // Add transaction record with enhanced data
        await _addWithdrawalTransaction(
          amount,
          method,
          result['reference'] ?? referenceId,
          phone,
          result['status'] ?? 'PENDING',
          result['statusDetails'],
        );

        // Show success feedback
        _showWithdrawalSuccessDialog(
          amount,
          method,
          result['reference'] ?? referenceId,
          phone,
          result['status'] ?? 'PENDING',
        );

        // Refresh data and verify balance
        await _refreshAllData();
        await _verifyBalanceCalculation();

        // Update withdrawal status if successful
        if (result['status'] == 'SUCCESSFUL' ||
            result['status'] == 'Completed') {
          await _updateWithdrawalStatus(transactionId, 'Completed');
        } else {
          // Monitor transaction status for updates
          _monitorTransactionStatus(transactionId);
        }
      } else {
        // Show detailed error feedback
        _showWithdrawalErrorDialog(
          result['message'] ?? 'Withdrawal failed',
          result['error'] ?? {},
          amount,
          method,
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Log error for debugging
      print('❌ Withdrawal processing error: $e');
      debugPrint('Withdrawal processing error: $e');

      // Show error feedback
      _showWithdrawalErrorDialog(
        'Network or system error occurred',
        {'error': e.toString()},
        amount,
        method,
      );
    }
  }

  Future<Map<String, dynamic>> _processMTNWithdrawal(
    double amount,
    String phone,
    String externalId,
  ) async {
    try {
      // Create MoMo service instance
      final momoService = MomoService();

      // Format phone number
      final formattedPhone = phone.startsWith('0') ? phone.substring(1) : phone;
      final fullPhone = '256$formattedPhone';

      // Process transfer
      final result = await momoService.transferMoney(
        phoneNumber: fullPhone,
        amount: amount,
        externalId: externalId,
        payeeMessage: 'SACCO Withdrawal',
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error processing MTN transfer: $e'};
    }
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => _buildEnhancedDialog(
        title: title,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Colors.red[600],
          ),
        ),
        message: message,
        primaryAction: 'OK',
        secondaryAction: '',
        onPrimaryAction: () => Navigator.pop(context),
        onSecondaryAction: () => Navigator.pop(context),
        primaryColor: Colors.red,
      ),
    );
  }

  // Show withdrawal progress dialog
  void _showWithdrawalProgressDialog(
    double amount,
    String phone,
    String method,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Processing Withdrawal',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Transaction details
              _buildTransactionSummaryCard(
                amount: amount,
                method: method,
                type: 'Withdrawal',
                color: Colors.blue,
                phone: phone,
              ),
              const SizedBox(height: 16),
              // Status message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'Please wait while we process your withdrawal...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show withdrawal success dialog
  void _showWithdrawalSuccessDialog(
    double amount,
    String method,
    String reference,
    String phone,
    String status,
  ) {
    showDialog(
      context: context,
      builder: (context) => _buildEnhancedDialog(
        title: 'Withdrawal Initiated',
        icon: Icons.check_circle,
        iconColor: Colors.green,
        content: _buildTransactionSummaryCard(
          amount: amount,
          method: method,
          type: 'Withdrawal',
          color: Colors.green,
          phone: phone,
          status: status,
          reference: reference,
        ),
        message:
            'Your withdrawal has been initiated successfully. You will receive a confirmation SMS shortly.',
        primaryAction: 'OK',
        secondaryAction: 'View Transactions',
        onPrimaryAction: () => Navigator.pop(context),
        onSecondaryAction: () {
          Navigator.pop(context);
          _showTransactionHistory();
        },
        primaryColor: Colors.green,
      ),
    );
  }

  // Show withdrawal error dialog
  void _showWithdrawalErrorDialog(
    String message,
    Map<String, dynamic> error,
    double amount,
    String method,
  ) {
    showDialog(
      context: context,
      builder: (context) => _buildEnhancedDialog(
        title: 'Withdrawal Failed',
        icon: Icons.error,
        iconColor: Colors.red,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTransactionSummaryCard(
              amount: amount,
              method: method,
              type: 'Withdrawal',
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error: $message',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Details: ${error.toString()}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        message: 'Please try again or contact support if the problem persists.',
        primaryAction: 'Retry',
        secondaryAction: 'OK',
        onPrimaryAction: () {
          Navigator.pop(context);
          _retryWithdrawal(amount, method);
        },
        onSecondaryAction: () => Navigator.pop(context),
        primaryColor: Colors.red,
      ),
    );
  }

  // Refresh all data
  Future<void> _refreshAllData() async {
    print('🔄 Refreshing all data...');
    await Future.wait([
      _fetchTransactions(),
      _fetchSavingsData(),
      _fetchLoansData(),
    ]);
    print('✅ All data refreshed successfully');

    // Verify data integrity
    await _verifyDataIntegrity();
  }

  // Verify data integrity after fetching
  Future<void> _verifyDataIntegrity() async {
    print('🔍 Verifying data integrity...');

    // Verify member data
    if (memberId.isEmpty) {
      print('❌ Member ID is empty');
      return;
    }

    // Verify savings data
    print('📊 Savings verification:');
    print('   - Current savings: ${_formatCurrency(_currentSavings)}');
    print('   - Savings history count: ${_savingsHistory.length}');

    // Verify loans data
    print('📊 Loans verification:');
    print('   - Total loans: ${_loans.length}');
    print(
      '   - Active loans: ${_loans.where((l) => l.status == 'Active' || l.status == 'Approved').length}',
    );
    print(
      '   - Pending loans: ${_loans.where((l) => l.status == 'Pending' || l.status == 'Pending Approval').length}',
    );
    print(
      '   - Overdue loans: ${_loans.where((l) => l.status == 'Overdue').length}',
    );

    // Verify transactions data
    print('📊 Transactions verification:');
    print('   - Total transactions: ${_transactions.length}');
    print(
      '   - Recent transactions: ${_transactions.take(3).map((t) => '${t.type}: ${_formatCurrency(t.amount)}').join(', ')}',
    );

    print('✅ Data integrity verification complete');
  }

  // Update withdrawal status
  Future<void> _updateWithdrawalStatus(
    String transactionId,
    String status,
  ) async {
    try {
      print('🔄 Updating withdrawal status: $transactionId -> $status');

      // Update transaction status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .doc(transactionId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update savings record status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('savings')
          .doc(transactionId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Withdrawal status updated successfully');

      // Refresh data to reflect changes
      await _refreshAllData();
    } catch (e) {
      print('❌ Error updating withdrawal status: $e');
      debugPrint('Error updating withdrawal status: $e');
    }
  }

  // Monitor transaction status for automatic updates
  Future<void> _monitorTransactionStatus(String transactionId) async {
    try {
      print('🔍 Monitoring transaction status: $transactionId');

      // Listen to transaction changes
      FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .doc(transactionId)
          .snapshots()
          .listen((snapshot) async {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              final status = data['status'] as String? ?? 'Pending';

              print('📊 Transaction status changed: $status');

              // If transaction is completed or failed, refresh data
              if (status == 'Completed' ||
                  status == 'Failed' ||
                  status == 'Rejected') {
                print('🔄 Transaction finalized, refreshing data...');
                await _refreshAllData();
              }
            }
          });
    } catch (e) {
      print('❌ Error monitoring transaction status: $e');
      debugPrint('Error monitoring transaction status: $e');
    }
  }

  // Verify withdrawal transaction in database
  Future<void> _verifyWithdrawalTransaction(String transactionId) async {
    try {
      print('🔍 Verifying withdrawal transaction: $transactionId');

      // Check transaction record
      final transactionDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        print('❌ Transaction record not found');
        return;
      }

      final transactionData = transactionDoc.data()!;
      print('📊 Transaction data:');
      print('   - Status: ${transactionData['status']}');
      print('   - Amount: ${transactionData['amount']}');
      print('   - Type: ${transactionData['type']}');
      print('   - Method: ${transactionData['method']}');

      // Check savings record
      final savingsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('savings')
          .doc(transactionId)
          .get();

      if (!savingsDoc.exists) {
        print('❌ Savings record not found');
        return;
      }

      final savingsData = savingsDoc.data()!;
      print('📊 Savings data:');
      print('   - Status: ${savingsData['status']}');
      print('   - Amount: ${savingsData['amount']}');
      print('   - Type: ${savingsData['type']}');

      print('✅ Withdrawal transaction verified successfully');
    } catch (e) {
      print('❌ Error verifying withdrawal transaction: $e');
      debugPrint('Error verifying withdrawal transaction: $e');
    }
  }

  // Show transaction history
  void _showTransactionHistory() {
    // Navigate to transaction history or show in a dialog
    _currentIndex = 2; // Assuming 2 is the transactions tab
    setState(() {});
  }

  // Retry withdrawal
  void _retryWithdrawal(double amount, String method) {
    // Show withdrawal dialog again
    _initiateWithdrawal();
  }

  // Build enhanced dialog with overflow protection
  Widget _buildEnhancedDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    required String message,
    required String primaryAction,
    required String secondaryAction,
    required VoidCallback onPrimaryAction,
    required VoidCallback onSecondaryAction,
    required Color primaryColor,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    content,
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onSecondaryAction,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        secondaryAction,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPrimaryAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        primaryAction,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
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

  // Build transaction summary card
  Widget _buildTransactionSummaryCard({
    required double amount,
    required String method,
    required String type,
    required Color color,
    String? phone,
    String? status,
    String? reference,
  }) {
    // Helper function to get color variants
    Color getColorVariant(int shade) {
      if (color == Colors.green) {
        switch (shade) {
          case 50:
            return Colors.green[50]!;
          case 100:
            return Colors.green[100]!;
          case 200:
            return Colors.green[200]!;
          case 500:
            return Colors.green[500]!;
          case 600:
            return Colors.green[600]!;
          case 700:
            return Colors.green[700]!;
          default:
            return Colors.green;
        }
      } else if (color == Colors.red) {
        switch (shade) {
          case 50:
            return Colors.red[50]!;
          case 100:
            return Colors.red[100]!;
          case 200:
            return Colors.red[200]!;
          case 500:
            return Colors.red[500]!;
          case 600:
            return Colors.red[600]!;
          case 700:
            return Colors.red[700]!;
          default:
            return Colors.red;
        }
      } else if (color == Colors.blue) {
        switch (shade) {
          case 50:
            return Colors.blue[50]!;
          case 100:
            return Colors.blue[100]!;
          case 200:
            return Colors.blue[200]!;
          case 500:
            return Colors.blue[500]!;
          case 600:
            return Colors.blue[600]!;
          case 700:
            return Colors.blue[700]!;
          default:
            return Colors.blue;
        }
      }
      return color;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getColorVariant(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: getColorVariant(200)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == 'Deposit'
                ? Icons.account_balance_wallet
                : Icons.account_balance,
            size: 40,
            color: getColorVariant(600),
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(amount),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: getColorVariant(700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'via $method',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: getColorVariant(600),
            ),
          ),
          if (phone != null) ...[
            const SizedBox(height: 8),
            Text(
              'Phone: $phone',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: getColorVariant(600),
              ),
            ),
          ],
          if (status != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getColorVariant(100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: getColorVariant(700),
                ),
              ),
            ),
          ],
          if (reference != null) ...[
            const SizedBox(height: 8),
            Text(
              'Ref: $reference',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: getColorVariant(500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Verify balance calculation
  Future<void> _verifyBalanceCalculation() async {
    try {
      print('🔍 Verifying balance calculation...');

      final savingsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('savings')
          .orderBy('date', descending: true)
          .get();

      double calculatedBalance = 0;
      int depositCount = 0;
      int withdrawalCount = 0;
      double totalDeposits = 0;
      double totalWithdrawals = 0;

      for (var doc in savingsSnapshot.docs) {
        final amount = doc['amount']?.toDouble() ?? 0;
        final type = doc['type'] ?? 'Unknown';

        calculatedBalance += amount;

        if (amount > 0) {
          depositCount++;
          totalDeposits += amount;
        } else if (amount < 0) {
          withdrawalCount++;
          totalWithdrawals += amount.abs();
        }
      }

      print('📊 Balance Verification Results:');
      print('   - Calculated balance: ${_formatCurrency(calculatedBalance)}');
      print('   - Current balance: ${_formatCurrency(_currentSavings)}');
      print(
        '   - Difference: ${_formatCurrency(calculatedBalance - _currentSavings)}',
      );
      print(
        '   - Total deposits: ${_formatCurrency(totalDeposits)} ($depositCount transactions)',
      );
      print(
        '   - Total withdrawals: ${_formatCurrency(totalWithdrawals)} ($withdrawalCount transactions)',
      );

      if ((calculatedBalance - _currentSavings).abs() > 0.01) {
        print('⚠️  Balance mismatch detected!');
        // Force refresh the balance
        _currentSavings = calculatedBalance;
        setState(() {});
        print('✅ Balance corrected to: ${_formatCurrency(_currentSavings)}');
      } else {
        print('✅ Balance calculation is correct');
      }
    } catch (e) {
      print('❌ Error verifying balance: $e');
    }
  }

  Future<void> _addWithdrawalTransaction(
    double amount,
    String method,
    String reference,
    String phone,
    String status,
    Map<String, dynamic>? statusDetails,
  ) async {
    try {
      print('🔄 Adding withdrawal transaction to database');
      print('📝 Amount: $amount, Method: $method, Reference: $reference');

      // Generate unique transaction ID
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Start transaction batch for atomic operations
      final batch = FirebaseFirestore.instance.batch();

      // Add to transactions collection
      final transactionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .doc(transactionId);

      batch.set(transactionRef, {
        'amount': amount,
        'type': 'Withdrawal',
        'method': method,
        'status': status,
        'date': FieldValue.serverTimestamp(),
        'reference': reference,
        'transactionId': transactionId,
        'userId': memberId,
        'description': 'Withdrawal via $method',
        'phoneNumber': phone,
        'statusDetails': statusDetails,
      });

      // Add to savings collection as negative amount
      final savingsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('savings')
          .doc(transactionId);

      batch.set(savingsRef, {
        'amount': -amount, // Negative amount for withdrawal
        'date': FieldValue.serverTimestamp(),
        'type': 'Withdrawal',
        'method': method,
        'transactionId': transactionId,
        'userId': memberId,
        'status': status,
        'reference': reference,
        'phoneNumber': phone,
      });

      // Commit the batch
      await batch.commit();

      print('✅ Withdrawal transaction committed successfully');
      print('📊 Transaction record created: ${transactionRef.id}');
      print('📊 Savings record created: ${savingsRef.id}');

      // Immediately update the current balance
      _currentSavings -= amount;
      print(
        '💰 Balance updated: ${_formatCurrency(_currentSavings)} (deducted ${_formatCurrency(amount)})',
      );

      // Validate the transaction
      await _validateTransaction(transactionId, 'Withdrawal', amount, method);
    } catch (e) {
      print('❌ Error adding withdrawal transaction: $e');
      debugPrint('Error adding withdrawal transaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate loan counts with proper status mapping
    final activeLoans = _loans
        .where((loan) => loan.status == 'Active' || loan.status == 'Approved')
        .length;
    final pendingLoans = _loans
        .where(
          (loan) =>
              loan.status == 'Pending' || loan.status == 'Pending Approval',
        )
        .length;
    final overdueLoans = _loans
        .where((loan) => loan.status == 'Overdue')
        .length;
    final rejectedLoans = _loans
        .where((loan) => loan.status == 'Rejected')
        .length;
    final totalDue = _calculateTotalDue();

    print('📊 Dashboard loan counts:');
    print('   - Active: $activeLoans');
    print('   - Pending: $pendingLoans');
    print('   - Overdue: $overdueLoans');
    print('   - Rejected: $rejectedLoans');
    print('   - Total due: ${_formatCurrency(totalDue)}');

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
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: _getCurrentScreen(activeLoans, overdueLoans, totalDue),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showLoanApplication,
              backgroundColor: _primaryColor,
              child: const Icon(Icons.add),
            )
          : _currentIndex == 3
          ? FloatingActionButton(
              onPressed: 
              
              _submitFeedback,
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Savings Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildEnhancedBalanceCard(context),
              const SizedBox(height: 20),
              Expanded(
                child: _buildEnhancedHistoryList(context, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedBalanceCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[50]!, Colors.green[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 32,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Current Savings Balance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  NumberFormat.currency(symbol: 'UGX ').format(currentSavings),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHistoryList(
    BuildContext context,
    ScrollController scrollController,
  ) {
    if (savingsHistory.isEmpty) {
      return _buildEmptyHistoryState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction History',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: savingsHistory.length,
            itemBuilder: (context, index) {
              final item = savingsHistory[index];
              return _buildEnhancedHistoryItem(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistoryState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No transaction history',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your savings transactions will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHistoryItem(BuildContext context, SavingsHistory item) {
    final isDeposit = item.type == 'Deposit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isDeposit ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat('MMM d, y').format(item.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat.jm().format(item.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              NumberFormat.currency(symbol: 'UGX ').format(item.amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDeposit ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
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
                            // const SizedBox(height: 10),
                            // _buildLoanDetailRow(
                            //   'Original Amount:',
                            //   NumberFormat.currency(
                            //     symbol: 'UGX ',
                            //   ).format(loan.amount),
                            // ),
                            // _buildLoanDetailRow(
                            //   'Remaining Balance:',
                            //   NumberFormat.currency(
                            //     symbol: 'UGX ',
                            //   ).format(loan.remainingBalance),
                            // ),
                            _buildLoanDetailRow(
                              'Next Payment:',
                              NumberFormat.currency(
                                symbol: 'UGX ',
                              ).format(nextPaymentAmount),
                            ),
                            // _buildLoanDetailRow(
                            //   'Due Date:',
                            //   '${DateFormat('MMM d, y').format(nextPaymentDate)} '
                            //       '(${isOverdue ? 'Overdue ${-daysRemaining} days' : 'Due in $daysRemaining days'})',
                            // ),
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
    required description,
  });
}
