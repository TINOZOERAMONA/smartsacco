// 📦 Required imports
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // for formatting timestamp

class MemberDetailsPage extends StatelessWidget {
  const MemberDetailsPage({super.key});

  Future<Map<String, dynamic>> _fetchUserDetails(String userId) async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return userSnapshot.data() ?? {};
  }

  Map<String, int> _countLoanStatuses(List<Map<String, dynamic>> loans) {
    final Map<String, int> counts = {
      'approved': 0,
      'pending': 0,
      'rejected': 0,
    };

    for (var loan in loans) {
      final status = (loan['status'] ?? '').toString().toLowerCase().trim();
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }

    return counts;
  }


  Future<List<Map<String, dynamic>>> _fetchUserLoans(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('loans')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDetails(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          }

          final userData = userSnapshot.data ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${userData['fullName'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Email: ${userData['email'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Phone: ${userData['phone'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                const Divider(height: 30),
                const Text('Loan History',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchUserLoans(userId),
                  builder: (context, loanSnapshot) {
                    if (loanSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (loanSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${loanSnapshot.error}'));
                    }

                    final loans = loanSnapshot.data ?? [];
                    final statusCounts = _countLoanStatuses(loans);
                    final totalLoans = loans.length;
                    if (loans.isEmpty) {
                      return const Text('No loans found for this user.');
                    }
                    Text(
                      'Loan Statuses: '
                      '${statusCounts['approved']} Approved, '
                      '${statusCounts['pending']} Pending, '
                      '${statusCounts['rejected']} Rejected '
                      '($totalLoans Total)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                    const SizedBox(height: 12);


                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: loans.length,
                      itemBuilder: (context, index) {
                        final loan = loans[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(
                                'Amount: UGX ${loan['amount']?.toString() ?? 'N/A'}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Builder(
                                builder: (context) {
                                  final rawStatus = loan['status'];
                                  final status = (rawStatus != null && rawStatus.toString().trim().isNotEmpty)
                                      ? rawStatus.toString().toLowerCase().trim()
                                      : 'not set';

                                  Color statusColor;
                                  switch (status) {
                                    case 'approved':
                                      statusColor = Colors.green;
                                      break;
                                    case 'pending':
                                      statusColor = Colors.orange;
                                      break;
                                    case 'rejected':
                                      statusColor = Colors.red;
                                      break;
                                    default:
                                      statusColor = Colors.grey;
                                  }

                                  return Row(
                                    children: [
                                      const Text('Status: '),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                                Text(
                                  'Applied on: ${loan['applicationDate'] != null ? DateFormat('yyyy-MM-dd').format(loan['applicationDate'].toDate()) : 'N/A'}',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
