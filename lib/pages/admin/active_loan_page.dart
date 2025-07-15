import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum LoanFilter { all, dueSoon, overdue }

class ActiveLoansPage extends StatefulWidget {
  const ActiveLoansPage({Key? key}) : super(key: key);

  @override
  _ActiveLoansPageState createState() => _ActiveLoansPageState();
}

class _ActiveLoansPageState extends State<ActiveLoansPage> {
  LoanFilter _selectedFilter = LoanFilter.all;

  // Fetch user data by userId
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return null;
  }

  // Send WhatsApp reminder message
  void _sendWhatsAppReminder(String phone, String name) async {
    final message = Uri.encodeComponent(
        "Hello $name, this is a reminder to pay your monthly loan installment. Thank you.");
    final url = Uri.parse("https://wa.me/$phone?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  bool _isApproved(String? status) {
    return status != null && status.toLowerCase() == 'approved';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final next7Days = today.add(const Duration(days: 7));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Loans'),
        actions: [
          PopupMenuButton<LoanFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: LoanFilter.all, child: Text('All')),
              PopupMenuItem(value: LoanFilter.dueSoon, child: Text('Due Soon')),
              PopupMenuItem(value: LoanFilter.overdue, child: Text('Overdue')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('loans') // collection group query across all users
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active loans found.'));
          }

          // Filter only approved loans
          final allApprovedLoans = snapshot.data!.docs.where((doc) {
            final loanData = doc.data() as Map<String, dynamic>;
            final status = loanData['status'] as String?;
            return _isApproved(status);
          }).toList();

          // Apply the due date filters
          final filteredLoans = allApprovedLoans.where((doc) {
            final loanData = doc.data() as Map<String, dynamic>;
            final Timestamp? dueTimestamp = loanData['dueDate'];
            if (dueTimestamp == null) return false;
            final dueDate = dueTimestamp.toDate();

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
            return const Center(child: Text('No loans found for selected filter.'));
          }
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total Active Loans: ${filteredLoans.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );

          return ListView.builder(
            itemCount: filteredLoans.length,
            itemBuilder: (context, index) {
              final loan = filteredLoans[index];
              final loanData = loan.data() as Map<String, dynamic>;

              // Extract userId from document path: users/{userId}/loans/{loanId}
              final pathSegments = loan.reference.path.split('/');
              String userId = '';
              if (pathSegments.length >= 2 && pathSegments[0] == 'users') {
                userId = pathSegments[1];
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading user info...'),
                    );
                  }
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      title: Text('User not found'),
                      subtitle: Text('Loan ID: ${loan.id}'),
                    );
                  }

                  final userData = userSnapshot.data!;
                  final dueDate = loanData['dueDate']?.toDate();

                  // Safely parse numeric fields, fallback to 0.0
                  double parseAmount(dynamic value) {
                    if (value == null) return 0.0;
                    if (value is num) return value.toDouble();
                    return double.tryParse(value.toString()) ?? 0.0;
                  }

                  final amount = parseAmount(loanData['amount']);
                  final monthlyPayment = parseAmount(loanData['monthlyPayment']);
                  final remainingBalance = parseAmount(loanData['remainingBalance']);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                          'Name:${userData['fullName'] ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email:${userData['email'] ?? 'No Email'}'),
                          Text('Phone: ${userData['phone'] ?? 'N/A'}'),
                          Text('Loan Amount: UGX ${amount.toStringAsFixed(2)}'),
                          Text('Monthly Payment: UGX ${monthlyPayment.toStringAsFixed(2)}'),
                          Text('Remaining Balance: UGX ${remainingBalance.toStringAsFixed(2)}'),
                          Text(
                              'Due Date: ${dueDate != null ? dueDate.toLocal().toString().split(' ')[0] : "N/A"}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.message, color: Colors.green),
                        tooltip: 'Send WhatsApp Reminder',
                        onPressed: () {
                          final phone = userData['phone']?.toString() ?? '';
                          final name = userData['name']?.toString() ?? 'Member';
                          if (phone.isNotEmpty) {
                            _sendWhatsAppReminder(phone, name);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('User phone number not available')),
                            );
                          }
                        },
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
}
