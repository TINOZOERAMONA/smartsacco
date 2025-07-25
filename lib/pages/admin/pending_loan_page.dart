import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// Ensure this import is correct in your project

class PendingLoansPage extends StatelessWidget {
  const PendingLoansPage({super.key});

  /// Fetches user data from Firestore given a userId
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      debugPrint('Fetching user data for userId: $userId');
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userSnapshot.exists) {
        return userSnapshot.data()!;
      } else {
        debugPrint('User with ID $userId does not exist.');
        return {};
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return {};
    }
  }

  /// Extracts the userId from the Firestore document reference path
  String extractUserId(DocumentReference loanRef) {
    final pathSegments = loanRef.path.split('/');
    debugPrint('LoanRef path: ${loanRef.path}');
    if (pathSegments.contains('users')) {
      final index = pathSegments.indexOf('users');
      if (index + 1 < pathSegments.length) {
        final userId = pathSegments[index + 1];
        debugPrint('Extracted userId: $userId');
        return userId;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Loans')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('loans')
            .where('status', isEqualTo: 'Pending Approval') // Correct case here
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending loans.'));
          }

          final loans = snapshot.data!.docs;

          return ListView.builder(
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              final userId = extractUserId(loan.reference);

              if (userId.isEmpty) {
                // Skip loan if userId cannot be determined
                return const SizedBox();
              }

              return FutureBuilder<Map<String, dynamic>>(
                future: getUserData(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 72,
                      child: ListTile(title: Text('Loading user...')),
                      );

                    //return const ListTile(title: Text('Loading user...'));
                  }

                  if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                    return const SizedBox(); // Skip if no user data
                  }

                  final userData = userSnapshot.data!;
                  final userName = userData['fullName'] ?? 'No Name';
                  final amount = loan['amount'] ?? 0;
                  final status = loan['status'] ?? 'Unknown';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(userName),
                      subtitle: Text('Amount: UGX ${amount.toString()} | Status: $status'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/member_details',
                          arguments: {'userId': userId},
                        );
                      },
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
