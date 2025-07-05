import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoanListStatusPage extends StatelessWidget {
  const LoanListStatusPage({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchMemberLoans() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final loansSnapshot = await FirebaseFirestore.instance
        .collection('loans')
        .where('memberId', isEqualTo: currentUser.uid)
        .get();

    return loansSnapshot.docs.map((doc) => doc.data()).toList();
  }

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loan Status'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchMemberLoans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading loans"));
          }

          final loans = snapshot.data!;
          if (loans.isEmpty) {
            return const Center(child: Text("No loan applications found."));
          }

          return ListView.builder(
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: Text("Amount: UGX ${loan['amount'] ?? 'N/A'}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${loan['status'] ?? 'Pending'}"),
                      if (loan['dateApplied'] != null)
                        Text("Date: ${formatDate(loan['dateApplied'])}"),
                    ],
                  ),
                  trailing: Text(
                    loan['status'] ?? 'Pending',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: loan['status'] == 'Approved'
                          ? Colors.green
                          : loan['status'] == 'Rejected'
                              ? Colors.red
                              : Colors.orange,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
