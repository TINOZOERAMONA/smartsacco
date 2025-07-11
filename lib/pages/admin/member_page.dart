import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    final loansSnapshot =
        await FirebaseFirestore.instance.collection('loans').get();

    // Map of userId to total approved (and unpaid) loan amount
    final Map<String, double> totalApprovedLoans = {};

    for (var loanDoc in loansSnapshot.docs) {
      final data = loanDoc.data();
      final userId = data['userId'];
      final status = data['status']?.toString().toLowerCase() ?? '';
      final remaining = (data['remainingBalance'] ?? 0).toDouble();

      if (status == 'approved' && remaining > 0) {
        totalApprovedLoans[userId] = (totalApprovedLoans[userId] ?? 0) + remaining;
      }
    }

    return usersSnapshot.docs.map((doc) {
      final data = doc.data();
      final id = doc.id;

      return {
        'id': id,
        'fullName': data['fullName'] ?? 'No Name',
        'email': data['email'] ?? 'No Email',
        'totalLoan': totalApprovedLoans[id] ?? 0.0,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registered Members')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMembers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final members = snapshot.data!;
          if (members.isEmpty) {
            return const Center(child: Text('No members registered.'));
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final loanAmount = member['totalLoan'] as double;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(member['fullName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${member['email']}'),
                      Text('Total Approved Loans: UGX ${loanAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/member_details',
                      arguments: member['id'],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
