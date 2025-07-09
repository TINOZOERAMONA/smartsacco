import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    final loansSnapshot =
        await FirebaseFirestore.instance.collection('loans').get();

    // Map userId to latest loan status (or 'none')
    final Map<String, String> loanStatuses = {};

    for (var loan in loansSnapshot.docs) {
      final data = loan.data();
      final userId = data['userId'];
      final status = data['status'];
      loanStatuses[userId] = status; // Last loan status will overwrite previous
    }

    return usersSnapshot.docs.map((doc) {
      final data = doc.data();
      final id = doc.id;
      return {
        'id': id,
        'name': data['name'] ?? 'N/A',
        'email': data['email'] ?? 'N/A',
        'phone': data['phone'] ?? 'N/A',
        'loanStatus': loanStatuses[id] ?? 'none',
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
              final loanStatus = member['loanStatus'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(member['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${member['email']}'),
                      Text('Phone: ${member['phone']}'),
                      Text('Loan Status: ${loanStatus.toUpperCase()}'),
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
