// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:smartsacco/models/notification_model.dart';
// import 'package:smartsacco/pages/loan.dart';

// import 'package:smartsacco/services/loan_service.dart';
// import 'package:smartsacco/models/member_header_section.dart';
// import 'package:smartsacco/models/stat_card.dart';
// import 'package:smartsacco/models/loan_due_card.dart';
// import 'package:smartsacco/models/loan_list_item.dart';
// import 'package:smartsacco/models/activity_item.dart';
// import 'package:smartsacco/models/momopayment.dart';


// class HomeScreen extends StatefulWidget {
//   final String memberId;
//   final String memberName;
//   final String memberEmail;
//   final String memberPhone;
//   final VoidCallback onLoanApplication; // Changed from Function to VoidCallback
//   final ValueChanged<int> onNotificationsUpdate; // Changed from Function to ValueChanged<int>

//   const HomeScreen({
//     required this.memberId,
//     required this.memberName,
//     required this.memberEmail,
//     required this.memberPhone,
//     required this.onLoanApplication,
//     required this.onNotificationsUpdate,
//     super.key, // Changed to use super parameter
//   });

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final LoanService _loanService = LoanService();
//   int _activeLoansCount = 0;
//   int _overdueLoanCount = 0;
//   double _totalLoanAmount = 0.0;
//   List<Loan> _approvedLoans = [];
//   double _currentSavings = 0;
//   List<Loan> _loans = [];
//   List<AppNotification> _notifications = [];
//   List<Transaction> _transactions = [];

//   // Colors
//   final Color _primaryColor = const Color(0xFF3366CC);
//   final Color _secondaryColor = const Color(0xFF6699FF);
//   final Color _accentColor = const Color(0xFFFFA726);
//   final Color _successColor = const Color(0xFF4CAF50);
//   final Color _warningColor = const Color(0xFFFF9800);
//   final Color _dangerColor = const Color(0xFFF44336);
//   final Color _bgColor = const Color(0xFFF5F7FA);
//   final Color _cardColor = Colors.white;
//   final Color _textPrimary = const Color(0xFF333333);
//   final Color _textSecondary = const Color(0xFF666666);

//   @override
//   void initState() {
//     super.initState();
//     _fetchAllData();
//   }

//   Future<void> _fetchAllData() async {
//     await Future.wait([
//       _fetchSavingsData(),
//       _fetchLoansData(),
//       _fetchNotifications(),
//       _fetchTransactions(),
//     ]);
//   }

//   Future<void> _fetchSavingsData() async {
//     final savingsSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.memberId)
//         .collection('savings')
//         .orderBy('date', descending: true)
//         .get();

//     double totalSavings = 0;
//     List<SavingsHistory> history = [];

//     for (var doc in savingsSnapshot.docs) {
//       final amount = doc['amount']?.toDouble() ?? 0;
//       totalSavings += amount;
//       history.add(
//         SavingsHistory(
//           amount: amount,
//           date: doc['date'].toDate(),
//           type: doc['type'] ?? 'Deposit',
//           transactionId: doc.id,
//         ),
//       );
//     }

//     if (mounted) {
//       setState(() {
//         _currentSavings = totalSavings;
//       });
//     }
//   }

//   Future<void> _fetchLoansData() async {
//     final loansSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.memberId)
//         .collection('loans')
//         .orderBy('applicationDate', descending: true)
//         .get();
  
//     List<Loan> loans = [];
//     final now = DateTime.now();
  
//     for (var doc in loansSnapshot.docs) {
//       final loan = Loan.fromFirestore(doc);
//       loans.add(loan);
//     }
  
//     final activeLoans = loans.where((loan) => loan.status == 'Active').length;
//     final overdueLoans = loans
//         .where((loan) => loan.dueDate != null && loan.dueDate!.isBefore(now))
//         .length;
//     final totalAmount = loans.fold<double>(0.0, (sum, loan) => sum + loan.amount);
  
//     if (mounted) {
//       setState(() {
//         _loans = loans;
//         _activeLoansCount = activeLoans;
//         _overdueLoanCount = overdueLoans;
//         _totalLoanAmount = totalAmount;
//         _approvedLoans = loans.where((loan) => loan.status == 'Approved').toList();
//       });
//     }
//   }

//   Future<void> _fetchNotifications() async {
//     final notificationsSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.memberId)
//         .collection('notifications')
//         .orderBy('date', descending: true)
//         .limit(10)
//         .get();

//     int unread = 0;
//     List<AppNotification> notifications = [];

//     for (var doc in notificationsSnapshot.docs) {
//       final isRead = doc['isRead'] ?? false;
//       if (!isRead) unread++;

//       notifications.add(
//         AppNotification.fromFirestore(doc), // Use factory constructor
//       );
//     }

//     if (mounted) {
//       setState(() {
//         _notifications = notifications;
//       });
//       widget.onNotificationsUpdate(unread);
//     }
//   }

//   Future<void> _fetchTransactions() async {
//     final transactionsSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.memberId)
//         .collection('transactions')
//         .orderBy('date', descending: true)
//         .limit(5)
//         .get();

//     List<Transaction> transactions = [];

//     for (var doc in transactionsSnapshot.docs) {
//       transactions.add(
//         Transaction(
//           id: doc.id,
//           amount: doc['amount']?.toDouble() ?? 0,
//           date: doc['date']?.toDate() ?? DateTime.now(),
//           type: doc['type'] ?? 'Transaction',
//           status: doc['status'] ?? 'Completed',
//           method: doc['method'] ?? 'Mobile Money',
//           loanId: doc['loanId'],
//           paymentId: doc['paymentId'],
//         ),
//       );
//     }

//     if (mounted) {
//       setState(() {
//         _transactions = transactions;
//       });
//     }
//   }

//   String _formatCurrency(double amount) {
//     return NumberFormat.currency(
//       symbol: 'UGX ',
//       decimalDigits: 0,
//     ).format(amount);
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'completed':
//       case 'approved':
//       case 'active':
//         return _successColor;
//       case 'pending':
//         return _warningColor;
//       case 'failed':
//       case 'rejected':
//       case 'overdue':
//         return _dangerColor;
//       default:
//         return _textSecondary;
//     }
//   }

//   void _makePayment(Loan loan) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MomoPaymentPage(
//           amount: loan.nextPaymentAmount,
//           onPaymentComplete: (success) async {
//             if (success) {
//               try {
//                 final paymentAmount = loan.nextPaymentAmount;
//                 final paymentRef = await FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(widget.memberId)
//                     .collection('loans')
//                     .doc(loan.id)
//                     .collection('payments')
//                     .add({
//                       'amount': paymentAmount,
//                       'date': DateTime.now(),
//                       'reference': 'MOMO-${DateTime.now().millisecondsSinceEpoch}',
//                     });

//                 await FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(widget.memberId)
//                     .collection('loans')
//                     .doc(loan.id)
//                     .update({
//                       'remainingBalance': loan.remainingBalance - paymentAmount,
//                       'nextPaymentDate': DateTime.now().add(const Duration(days: 30)),
//                     });

//                 await FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(widget.memberId)
//                     .collection('transactions')
//                     .add({
//                       'amount': paymentAmount,
//                       'date': DateTime.now(),
//                       'type': 'Loan Repayment',
//                       'status': 'Completed',
//                       'method': 'Mobile Money',
//                       'loanId': loan.id,
//                       'paymentId': paymentRef.id,
//                     });

//                 await FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(widget.memberId)
//                     .collection('notifications')
//                     .add({
//                       'title': 'Payment Received',
//                       'message': 'Your payment of ${_formatCurrency(paymentAmount)} for loan ${loan.id.substring(0, 8)} has been received',
//                       'date': DateTime.now(),
//                       'type': NotificationType.payment.index,
//                       'isRead': false,
//                     });

//                 _fetchNotifications();
//                 _fetchTransactions();

//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Payment successful!')),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Error recording payment: $e')),
//                 );
//               }
//             }
//           },
//         ),
//       ),
//     );
//   }

//   void _showLoansByStatus(String status) {
//     final filteredLoans = _loans
//         .where((loan) => loan.status.toLowerCase() == status)
//         .toList();

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.8,
//         decoration: BoxDecoration(
//           color: _bgColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: _textSecondary.withOpacity(0.3),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             Text(
//               '${status[0].toUpperCase()}${status.substring(1)} Loans',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: filteredLoans.isEmpty
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.credit_card_off,
//                             size: 50,
//                             color: _textSecondary.withOpacity(0.5),
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             'No $status loans',
//                             style: GoogleFonts.poppins(
//                               fontSize: 16,
//                               color: _textSecondary,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: filteredLoans.length,
//                       itemBuilder: (context, index) => LoanListItem(
//                         loan: filteredLoans[index],
//                         formatCurrency: _formatCurrency,
//                         getStatusColor: _getStatusColor,
//                         onPaymentPressed: _makePayment,
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatsGrid(
//     double savings,
//     int activeLoans,
//     int overdueLoans,
//     double totalDue,
//   ) {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       childAspectRatio: 1.2,
//       mainAxisSpacing: 12,
//       crossAxisSpacing: 12,
//       children: [
//         StatCard(
//           title: 'Savings',
//           value: _formatCurrency(savings),
//           icon: Icons.account_balance_wallet,
//           color: _successColor,
//           textPrimary: _textPrimary,
//           textSecondary: _textSecondary,
//         ),
//         StatCard(
//           title: 'Active Loans',
//           value: activeLoans.toString(),
//           icon: Icons.credit_card,
//           color: _primaryColor,
//           textPrimary: _textPrimary,
//           textSecondary: _textSecondary,
//         ),
//         StatCard(
//           title: 'Overdue',
//           value: overdueLoans.toString(),
//           icon: Icons.warning,
//           color: _warningColor,
//           textPrimary: _textPrimary,
//           textSecondary: _textSecondary,
//         ),
//         StatCard(
//           title: 'Total Due',
//           value: _formatCurrency(totalDue),
//           icon: Icons.payments,
//           color: _dangerColor,
//           textPrimary: _textPrimary,
//           textSecondary: _textSecondary,
//         ),
//       ],
//     );
//   }

//   Widget _buildNextPaymentSection() {
//     final duePayments = _loans
//         .where((loan) => loan.status == 'Active' || loan.status == 'Overdue')
//         .toList();

//     if (duePayments.isEmpty) {
//       return Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Icon(Icons.check_circle, size: 50, color: _successColor),
//               const SizedBox(height: 16),
//               Text(
//                 'No Due Payments',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'You have no active or overdue loans at this time',
//                 style: GoogleFonts.poppins(color: _textSecondary),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Next Payment Due',
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: _dangerColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '${duePayments.length} ${duePayments.length == 1 ? 'Loan' : 'Loans'}',
//                     style: GoogleFonts.poppins(
//                       color: _dangerColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             ...duePayments.map((loan) => LoanDueCard(
//               loan: loan,
//               formatCurrency: _formatCurrency,
//               getStatusColor: _getStatusColor,
//               onPaymentPressed: _makePayment,
//               textPrimary: _textPrimary,
//               textSecondary: _textSecondary,
//               primaryColor: _primaryColor,
//               dangerColor: _dangerColor,
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoanStatusSection() {
//     final pendingLoans = _loans.where((loan) => loan.status == 'Pending').toList();
//     final approvedLoans = _loans.where((loan) => loan.status == 'Approved').toList();
//     final rejectedLoans = _loans.where((loan) => loan.status == 'Rejected').toList();

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Loan Applications',
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             if (pendingLoans.isNotEmpty) ...[
//               InkWell(
//                 onTap: () => _showLoansByStatus('pending'),
//                 borderRadius: BorderRadius.circular(8),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: _warningColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.pending, color: _warningColor),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Pending Review',
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                       ),
//                       const Spacer(),
//                       Text(
//                         '${pendingLoans.length} ${pendingLoans.length == 1 ? 'Loan' : 'Loans'}',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.bold,
//                           color: _warningColor,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Icon(Icons.chevron_right, color: _textSecondary),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//             if (approvedLoans.isNotEmpty) ...[
//               InkWell(
//                 onTap: () => _showLoansByStatus('approved'),
//                 borderRadius: BorderRadius.circular(8),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: _successColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.check_circle, color: _successColor),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Approved',
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                       ),
//                       const Spacer(),
//                       Text(
//                         '${approvedLoans.length} ${approvedLoans.length == 1 ? 'Loan' : 'Loans'}',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.bold,
//                           color: _successColor,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Icon(Icons.chevron_right, color: _textSecondary),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//             if (rejectedLoans.isNotEmpty) ...[
//               InkWell(
//                 onTap: () => _showLoansByStatus('rejected'),
//                 borderRadius: BorderRadius.circular(8),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: _dangerColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.cancel, color: _dangerColor),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Rejected',
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                       ),
//                       const Spacer(),
//                       Text(
//                         '${rejectedLoans.length} ${rejectedLoans.length == 1 ? 'Loan' : 'Loans'}',
//                         style: GoogleFonts.poppins(
//                           fontWeight: FontWeight.bold,
//                           color: _dangerColor,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Icon(Icons.chevron_right, color: _textSecondary),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//             const SizedBox(height: 8),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton(
//                 onPressed: widget.onLoanApplication,
//                 style: OutlinedButton.styleFrom(
//                   side: BorderSide(color: _primaryColor),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//                 child: Text(
//                   'Apply for Loan',
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.bold,
//                     color: _primaryColor,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivities() {
//     if (_transactions.isEmpty && _notifications.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Recent Activities',
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ..._transactions.take(3).map((txn) => ActivityItem(
//               item: txn,
//               isTransaction: true,
//               formatCurrency: _formatCurrency,
//               getStatusColor: _getStatusColor,
//               textSecondary: _textSecondary,
//               primaryColor: _primaryColor,
//               dangerColor: _dangerColor,
//               successColor: _successColor,
//             )),
//             ..._notifications.take(3).map((notif) => ActivityItem(
//               item: notif,
//               isTransaction: false,
//               formatCurrency: _formatCurrency,
//               getStatusColor: _getStatusColor,
//               textSecondary: _textSecondary,
//               primaryColor: _primaryColor,
//               dangerColor: _dangerColor,
//               successColor: _successColor,
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final activeLoans = _loans.where((loan) => loan.status == 'Active').length;
//     final overdueLoans = _loans.where((loan) => loan.status == 'Overdue').length;
//     final totalDue = _loans.fold<double>(0, (sum, loan) => sum + loan.nextPaymentAmount);

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           HeaderSection(
//             memberName: widget.memberName,
//             memberEmail: widget.memberEmail,
//             memberPhone: widget.memberPhone,
//             primaryColor: _primaryColor,
//             textPrimary: _textPrimary,
//             textSecondary: _textSecondary,
//           ),
//           const SizedBox(height: 20),
//           _buildStatsGrid(_currentSavings, activeLoans, overdueLoans, totalDue),
//           const SizedBox(height: 20),
//           _buildNextPaymentSection(),
//           const SizedBox(height: 20),
//           _buildLoanStatusSection(),
//           const SizedBox(height: 20),
//           _buildRecentActivities(),
//         ],
//       ),
//     );
//   }
// }

// class SavingsHistory {
//   final double amount;
//   final DateTime date;
//   final String type;
//   final String transactionId;

//   SavingsHistory({
//     required this.amount,
//     required this.date,
//     required this.type,
//     required this.transactionId,
//   });
// }

// class Transaction {
//   final String id;
//   final double amount;
//   final DateTime date;
//   final String type;
//   final String status;
//   final String method;
//   final String? loanId;
//   final String? paymentId;

//   Transaction({
//     required this.id,
//     required this.amount,
//     required this.date,
//     required this.type,
//     required this.status,
//     required this.method,
//     this.loanId,
//     this.paymentId,
//   });
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartsacco/models/notification_model.dart';
import 'package:smartsacco/pages/loan.dart';
import 'package:smartsacco/services/loan_service.dart';
import 'package:smartsacco/models/member_header_section.dart';
import 'package:smartsacco/models/stat_card.dart';
import 'package:smartsacco/models/loan_due_card.dart';
import 'package:smartsacco/models/loan_list_item.dart';
import 'package:smartsacco/models/activity_item.dart';
import 'package:smartsacco/models/momopayment.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  final String memberId;
  final String memberName;
  final String memberEmail;
  final String memberPhone;
  final VoidCallback onLoanApplication;
  final ValueChanged<int> onNotificationsUpdate;

  const HomeScreen({
    required this.memberId,
    required this.memberName,
    required this.memberEmail,
    required this.memberPhone,
    required this.onLoanApplication,
    required this.onNotificationsUpdate,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LoanService _loanService = LoanService();
  int _activeLoansCount = 0;
  int _overdueLoanCount = 0;
  double _totalLoanAmount = 0.0;
  List<Loan> _approvedLoans = [];
  double _currentSavings = 0;
  List<Loan> _loans = [];
  List<AppNotification> _notifications = [];
  List<Transaction> _transactions = [];

  // Colors
  final Color _primaryColor = const Color(0xFF3366CC);
  final Color _secondaryColor = const Color(0xFF6699FF);
  final Color _accentColor = const Color(0xFFFFA726);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _warningColor = const Color(0xFFFF9800);
  final Color _dangerColor = const Color(0xFFF44336);
  final Color _bgColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF333333);
  final Color _textSecondary = const Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      await Future.wait([
        _fetchSavingsData(),
        _fetchLoansData(),
        _fetchNotifications(),
        _fetchTransactions(),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _fetchSavingsData() async {
    try {
      final savingsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('savings')
          .orderBy('date', descending: true)
          .get();

      double totalSavings = 0;
      List<SavingsHistory> history = [];

      for (var doc in savingsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalSavings += amount;
        
        history.add(
          SavingsHistory(
            amount: amount,
            date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            type: data['type'] as String? ?? 'Deposit',
            transactionId: doc.id,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _currentSavings = totalSavings;
        });
      }
    } catch (e) {
      print('Error fetching savings: $e');
    }
  }

  Future _fetchLoansData() async {
    try {
      final loansSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('loans')
          .orderBy('applicationDate', descending: true)
          .get();
    
      List<Loan> loans = [];
      final now = DateTime.now();
    
      for (var doc in loansSnapshot.docs) {
        final loan = Loan.fromFirestore(doc);
        // loans.add(loan);
      }
    
      final activeLoans = loans.where((loan) => loan.status == 'Active').length;
      final overdueLoans = loans
          .where((loan) => loan.dueDate != null && loan.dueDate!.isBefore(now))
          .length;
      final totalAmount = loans.fold<double>(0.0, (sum, loan) => sum + loan.amount);
    
      if (mounted) {
        setState(() {
          _loans = loans;
          _activeLoansCount = activeLoans;
          _overdueLoanCount = overdueLoans;
          _totalLoanAmount = totalAmount;
          _approvedLoans = loans.where((loan) => loan.status == 'Approved').toList();
        });
      }
    } catch (e) {
      print('Error fetching loans: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('notifications')
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      int unread = 0;
      List<AppNotification> notifications = [];

      for (var doc in notificationsSnapshot.docs) {
        final data = doc.data();
        final isRead = data['isRead'] as bool? ?? false;
        if (!isRead) unread++;

        notifications.add(
          AppNotification.fromFirestore(doc),
        );
      }

      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
        widget.onNotificationsUpdate(unread);
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      List<Transaction> transactions = [];

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        transactions.add(
          Transaction(
            id: doc.id,
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
            date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            type: data['type'] as String? ?? 'Transaction',
            status: data['status'] as String? ?? 'Completed',
            method: data['method'] as String? ?? 'Mobile Money',
            loanId: data['loanId'] as String?,
            paymentId: data['paymentId'] as String?,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
        });
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    }
  }

  // Enhanced method to create/update user profile with all details
  Future<void> _updateUserProfile() async {
    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId);

      // First check if document exists
      final docSnapshot = await userDoc.get();
      
      final userData = {
        'memberId': widget.memberId,
        'name': widget.memberName,
        'email': widget.memberEmail,
        'phone': widget.memberPhone,
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'membershipStatus': 'Active',
      };

      if (docSnapshot.exists) {
        // Update existing document
        await userDoc.update(userData);
      } else {
        // Create new document with additional fields
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['joinDate'] = FieldValue.serverTimestamp();
        userData['totalSavings'] = 0.0;
        userData['totalLoans'] = 0;
        userData['creditScore'] = 0;
        
        await userDoc.set(userData);
      }

      print('User profile updated successfully');
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  // Enhanced loan application method that saves all applicant details
  Future<void> _createLoanApplication({
    required double amount,
    required String purpose,
    required int termMonths,
    required String guarantor1Name,
    required String guarantor1Phone,
    required String guarantor2Name,
    required String guarantor2Phone,
    String? collateralType,
    String? collateralValue,
  }) async {
    try {
      // First ensure user profile is up to date
      await _updateUserProfile();

      // Create loan application with all details
      final loanData = {
        // Applicant Details
        'applicantId': widget.memberId,
        'applicantName': widget.memberName,
        'applicantEmail': widget.memberEmail,
        'applicantPhone': widget.memberPhone,
        
        // Loan Details
        'amount': amount,
        'purpose': purpose,
        'termMonths': termMonths,
        'interestRate': 15.0, // Default rate, adjust as needed
        'status': 'Pending',
        'applicationDate': FieldValue.serverTimestamp(),
        
        // Guarantor Details
        'guarantor1': {
          'name': guarantor1Name,
          'phone': guarantor1Phone,
        },
        'guarantor2': {
          'name': guarantor2Name,
          'phone': guarantor2Phone,
        },
        
        // Collateral (if any)
        if (collateralType != null) 'collateralType': collateralType,
        if (collateralValue != null) 'collateralValue': collateralValue,
        
        // Calculated fields
        'monthlyPayment': _calculateMonthlyPayment(amount, 15.0, termMonths),
        'totalRepayment': _calculateTotalRepayment(amount, 15.0, termMonths),
        
        // Application metadata
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'applicationSource': 'mobile_app',
        'deviceInfo': 'Flutter App',
      };

      // Save to user's loans subcollection
      final loanRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('loans')
          .add(loanData);

      // Also save to main loans collection for admin access
      await FirebaseFirestore.instance
          .collection('loan_applications')
          .doc(loanRef.id)
          .set({
            ...loanData,
            'loanId': loanRef.id,
            'userDocRef': '/users/${widget.memberId}',
          });

      // Create notification for the application
      await _createNotification(
        title: 'Loan Application Submitted',
        message: 'Your loan application for ${_formatCurrency(amount)} has been submitted for review.',
        type: NotificationType.loanApplication,
      );

      // Refresh data
      await _fetchAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating loan application: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting loan application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to create notifications
  Future<void> _createNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'date': FieldValue.serverTimestamp(),
            'type': type.index,
            'isRead': false,
            'userId': widget.memberId,
            'userName': widget.memberName,
            'userPhone': widget.memberPhone,
          });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Helper methods for loan calculations
  double _calculateMonthlyPayment(double principal, double annualRate, int months) {
    final monthlyRate = annualRate / 100 / 12;
    return principal * (monthlyRate * pow(1 + monthlyRate, months)) / 
           (pow(1 + monthlyRate, months) - 1);
  }

  double _calculateTotalRepayment(double principal, double annualRate, int months) {
    return _calculateMonthlyPayment(principal, annualRate, months) * months;
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
      case 'active':
        return _successColor;
      case 'pending':
        return _warningColor;
      case 'failed':
      case 'rejected':
      case 'overdue':
        return _dangerColor;
      default:
        return _textSecondary;
    }
  }

  void _makePayment(Loan loan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomoPaymentPage(
          amount: loan.nextPaymentAmount,
          onPaymentComplete: (success) async {
            if (success) {
              await _processPayment(loan);
            }
          },
        ),
      ),
    );
  }

  Future<void> _processPayment(Loan loan) async {
    try {
      final paymentAmount = loan.nextPaymentAmount;
      final paymentRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('loans')
          .doc(loan.id)
          .collection('payments')
          .add({
            'amount': paymentAmount,
            'date': FieldValue.serverTimestamp(),
            'reference': 'MOMO-${DateTime.now().millisecondsSinceEpoch}',
            'payerName': widget.memberName,
            'payerPhone': widget.memberPhone,
            'paymentMethod': 'Mobile Money',
            'status': 'Completed',
          });

      // Update loan details
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('loans')
          .doc(loan.id)
          .update({
            'remainingBalance': loan.remainingBalance - paymentAmount,
            'nextPaymentDate': DateTime.now().add(const Duration(days: 30)),
            'lastPaymentDate': FieldValue.serverTimestamp(),
            'lastPaymentAmount': paymentAmount,
          });

      // Record transaction
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('transactions')
          .add({
            'amount': paymentAmount,
            'date': FieldValue.serverTimestamp(),
            'type': 'Loan Repayment',
            'status': 'Completed',
            'method': 'Mobile Money',
            'loanId': loan.id,
            'paymentId': paymentRef.id,
            'memberName': widget.memberName,
            'memberPhone': widget.memberPhone,
            'description': 'Loan repayment for ${loan.id.substring(0, 8)}',
          });

      // Create notification
      await _createNotification(
        title: 'Payment Received',
        message: 'Your payment of ${_formatCurrency(paymentAmount)} for loan ${loan.id.substring(0, 8)} has been received',
        type: NotificationType.payment,
      );

      // Refresh data
      await _fetchNotifications();
      await _fetchTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );
      }
    } catch (e) {
      print('Error processing payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording payment: $e')),
        );
      }
    }
  }

  void _showLoansByStatus(String status) {
    final filteredLoans = _loans
        .where((loan) => loan.status.toLowerCase() == status.toLowerCase())
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '${status[0].toUpperCase()}${status.substring(1)} Loans',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredLoans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card_off,
                            size: 50,
                            color: _textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No $status loans',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLoans.length,
                      itemBuilder: (context, index) => LoanListItem(
                        loan: filteredLoans[index],
                        formatCurrency: _formatCurrency,
                        getStatusColor: _getStatusColor,
                        onPaymentPressed: _makePayment,
                      ),
                    ),
            ),
          ],
        ),
      ),
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
      childAspectRatio: 1.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        StatCard(
          title: 'Savings',
          value: _formatCurrency(savings),
          icon: Icons.account_balance_wallet,
          color: _successColor,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
        ),
        StatCard(
          title: 'Active Loans',
          value: activeLoans.toString(),
          icon: Icons.credit_card,
          color: _primaryColor,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
        ),
        StatCard(
          title: 'Overdue',
          value: overdueLoans.toString(),
          icon: Icons.warning,
          color: _warningColor,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
        ),
        StatCard(
          title: 'Total Due',
          value: _formatCurrency(totalDue),
          icon: Icons.payments,
          color: _dangerColor,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
        ),
      ],
    );
  }

  Widget _buildNextPaymentSection() {
    final duePayments = _loans
        .where((loan) => loan.status == 'Active' || loan.status == 'Overdue')
        .toList();

    if (duePayments.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 50, color: _successColor),
              const SizedBox(height: 16),
              Text(
                'No Due Payments',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have no active or overdue loans at this time',
                style: GoogleFonts.poppins(color: _textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
                  'Next Payment Due',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${duePayments.length} ${duePayments.length == 1 ? 'Loan' : 'Loans'}',
                    style: GoogleFonts.poppins(
                      color: _dangerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...duePayments.map((loan) => LoanDueCard(
              loan: loan,
              formatCurrency: _formatCurrency,
              getStatusColor: _getStatusColor,
              onPaymentPressed: _makePayment,
              textPrimary: _textPrimary,
              textSecondary: _textSecondary,
              primaryColor: _primaryColor,
              dangerColor: _dangerColor,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanStatusSection() {
    final pendingLoans = _loans.where((loan) => loan.status == 'Pending').toList();
    final approvedLoans = _loans.where((loan) => loan.status == 'Approved').toList();
    final rejectedLoans = _loans.where((loan) => loan.status == 'Rejected').toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Applications',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (pendingLoans.isNotEmpty) ...[
              InkWell(
                onTap: () => _showLoansByStatus('pending'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending, color: _warningColor),
                      const SizedBox(width: 12),
                      Text(
                        'Pending Review',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        '${pendingLoans.length} ${pendingLoans.length == 1 ? 'Loan' : 'Loans'}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: _warningColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: _textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (approvedLoans.isNotEmpty) ...[
              InkWell(
                onTap: () => _showLoansByStatus('approved'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: _successColor),
                      const SizedBox(width: 12),
                      Text(
                        'Approved',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        '${approvedLoans.length} ${approvedLoans.length == 1 ? 'Loan' : 'Loans'}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: _successColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: _textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (rejectedLoans.isNotEmpty) ...[
              InkWell(
                onTap: () => _showLoansByStatus('rejected'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: _dangerColor),
                      const SizedBox(width: 12),
                      Text(
                        'Rejected',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        '${rejectedLoans.length} ${rejectedLoans.length == 1 ? 'Loan' : 'Loans'}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: _dangerColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: _textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onLoanApplication,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Apply for Loan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    if (_transactions.isEmpty && _notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._transactions.take(3).map((txn) => ActivityItem(
              item: txn,
              isTransaction: true,
              formatCurrency: _formatCurrency,
              getStatusColor: _getStatusColor,
              textSecondary: _textSecondary,
              primaryColor: _primaryColor,
              dangerColor: _dangerColor,
              successColor: _successColor,
            )),
            ..._notifications.take(3).map((notif) => ActivityItem(
              item: notif,
              isTransaction: false,
              formatCurrency: _formatCurrency,
              getStatusColor: _getStatusColor,
              textSecondary: _textSecondary,
              primaryColor: _primaryColor,
              dangerColor: _dangerColor,
              successColor: _successColor,
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLoans = _loans.where((loan) => loan.status == 'Active').length;
    final overdueLoans = _loans.where((loan) => loan.status == 'Overdue').length;
    final totalDue = _loans.fold<double>(0, (sum, loan) => sum + loan.nextPaymentAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeaderSection(
            memberName: widget.memberName,
            memberEmail: widget.memberEmail,
            memberPhone: widget.memberPhone,
            primaryColor: _primaryColor,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
          ),
          const SizedBox(height: 20),
          _buildStatsGrid(_currentSavings, activeLoans, overdueLoans, totalDue),
          const SizedBox(height: 20),
          _buildNextPaymentSection(),
          const SizedBox(height: 20),
          _buildLoanStatusSection(),
          const SizedBox(height: 20),
          _buildRecentActivities(),
        ],
      ),
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