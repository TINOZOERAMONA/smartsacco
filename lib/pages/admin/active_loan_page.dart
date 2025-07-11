import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

enum LoanFilter { all, dueSoon, overdue }

class ActiveLoansPage extends StatefulWidget {
  const ActiveLoansPage({Key? key}) : super(key: key);

  @override
  _ActiveLoansPageState createState() => _ActiveLoansPageState();
}

class _ActiveLoansPageState extends State<ActiveLoansPage> {
  LoanFilter _selectedFilter = LoanFilter.all;
  final _currencyFormat = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX');

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> _sendWhatsAppReminder(String phone, String name) async {
    final message = Uri.encodeComponent(
        "Hello $name, this is a reminder to pay your monthly loan installment. Thank you.");
    final url = Uri.parse("https://wa.me/$phone?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  bool _isApproved(String? status) {
    return status != null && status.toLowerCase() == 'approved';
  }

  Color _getDueDateColor(DateTime? dueDate) {
    if (dueDate == null) return Colors.grey;
    final today = DateTime.now();
    if (dueDate.isBefore(today)) return Colors.red.shade600;
    if (dueDate.isBefore(today.add(const Duration(days: 7)))) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  String _getDueDateStatus(DateTime? dueDate) {
    if (dueDate == null) return 'No Due Date';
    final today = DateTime.now();
    if (dueDate.isBefore(today)) return 'Overdue';
    if (dueDate.isBefore(today.add(const Duration(days: 7)))) return 'Due Soon';
    return 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final next7Days = today.add(const Duration(days: 7));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Loans', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade800,
        actions: [
          PopupMenuButton<LoanFilter>(
            icon: Icon(Icons.filter_alt, color: Colors.blue.shade800),
            onSelected: (filter) => setState(() => _selectedFilter = filter),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: LoanFilter.all,
                child: Row(
                  children: [
                    Icon(Icons.list, color: Colors.blue.shade800),
                    const SizedBox(width: 8),
                    const Text('All Loans'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: LoanFilter.dueSoon,
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    const Text('Due Soon'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: LoanFilter.overdue,
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade800),
                    const SizedBox(width: 8),
                    const Text('Overdue'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('loans').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState('No active loans found');
          }

          final filteredLoans = snapshot.data!.docs.where((doc) {
            final loanData = doc.data() as Map<String, dynamic>;
            if (!_isApproved(loanData['status'])) return false;

            final dueDate = loanData['dueDate']?.toDate();
            if (dueDate == null) return false;

            switch (_selectedFilter) {
              case LoanFilter.all:
                return true;
              case LoanFilter.dueSoon:
                return dueDate.isAfter(today) && dueDate.isBefore(next7Days);
              case LoanFilter.overdue:
                return dueDate.isBefore(today);
            }
          }).toList();

          if (filteredLoans.isEmpty) {
            return _buildEmptyState('No loans match the selected filter');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: filteredLoans.length,
            itemBuilder: (context, index) {
              final loan = filteredLoans[index];
              final loanData = loan.data() as Map<String, dynamic>;
              final pathSegments = loan.reference.path.split('/');
              final userId = pathSegments.length >= 2 && pathSegments[0] == 'users' 
                  ? pathSegments[1] 
                  : '';

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoanShimmer();
                  }
                  if (!userSnapshot.hasData) {
                    return _buildErrorLoanCard(loan.id);
                  }

                  final userData = userSnapshot.data!;
                  final dueDate = loanData['dueDate']?.toDate();
                  final dueStatus = _getDueDateStatus(dueDate);
                  final dueColor = _getDueDateColor(dueDate);
                  final phone = userData['phone']?.toString() ?? '';
                  final name = userData['name']?.toString() ?? 'Member';

                  final amount = (loanData['amount'] ?? 0).toDouble();
                  final monthlyPayment = (loanData['monthlyPayment'] ?? 0).toDouble();
                  final remainingBalance = (loanData['remainingBalance'] ?? 0).toDouble();

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // TODO: Navigate to loan details
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(color: Colors.blue.shade800),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (userData['email'] != null)
                                        Text(
                                          userData['email'],
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.message, color: Colors.green),
                                  onPressed: phone.isNotEmpty
                                      ? () => _sendWhatsAppReminder(phone, name)
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Loan Amount', _currencyFormat.format(amount)),
                            const SizedBox(height: 8),
                            _buildInfoRow('Monthly Payment', _currencyFormat.format(monthlyPayment)),
                            const SizedBox(height: 8),
                            _buildInfoRow('Remaining Balance', _currencyFormat.format(remainingBalance)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoRow(
                                    'Due Date',
                                    dueDate != null
                                        ? DateFormat('MMM dd, yyyy').format(dueDate)
                                        : 'N/A'),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: dueColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    dueStatus,
                                    style: TextStyle(
                                      color: dueColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
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
            'Loading active loans...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanShimmer() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.grey),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  LinearProgressIndicator(),
                  SizedBox(height: 8),
                  LinearProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorLoanCard(String loanId) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error loading loan details',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Loan ID: $loanId', 
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}