import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingLoansPage extends StatefulWidget {
  const PendingLoansPage({Key? key}) : super(key: key);

  @override
  State<PendingLoansPage> createState() => _PendingLoansPageState();
}

class _PendingLoansPageState extends State<PendingLoansPage> {
  late Future<List<QueryDocumentSnapshot>> _pendingLoansFuture;

  @override
  void initState() {
    super.initState();
    _pendingLoansFuture = _fetchPendingLoans();
  }

  Future<List<QueryDocumentSnapshot>> _fetchPendingLoans() async {
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('loans')
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Loans')),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _pendingLoansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final loans = snapshot.data!;
          if (loans.isEmpty) {
            return const Center(child: Text('No Pending Loans'));
          }

          return ListView.builder(
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loanDoc = loans[index];
              final loanData = loanDoc.data() as Map<String, dynamic>;
              final amount = loanData['amount'];
              final userId = loanDoc.reference.path.split('/')[1]; // extract userId from path

              return ListTile(
                title: Text('Amount: UGX $amount'),
                subtitle: Text('Purpose: ${loanData['purpose']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MemberDetailsPage(userId: userId),
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

// Dummy MemberDetailsPage
class MemberDetailsPage extends StatelessWidget {
  final String userId;
  const MemberDetailsPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
      body: Center(child: Text('User ID: $userId')),
    );
  }
}
