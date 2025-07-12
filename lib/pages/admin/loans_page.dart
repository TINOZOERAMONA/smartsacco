import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoansPage extends StatefulWidget {
  @override
  _LoansPageState createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  String selectedStatus = 'All';

  Stream<QuerySnapshot<Map<String, dynamic>>> getLoanStream() {
    final loans = FirebaseFirestore.instance.collection('loans');
    if (selectedStatus == 'All') {
      return loans.orderBy('timestamp', descending: true).snapshots();
    } else {
      return loans
          .where('status', isEqualTo: selectedStatus)
          .orderBy('timestamp', descending: true)
          .snapshots();

import 'package:intl/intl.dart';
import 'loan_approval_page.dart';

class LoanPage extends StatefulWidget {
  const LoanPage({Key? key}) : super(key: key);

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  String selectedFilter = 'All'; // All, Pending Approval, Approved, Rejected
  int activeLoanCount = 0;

  @override
  void initState() {
    super.initState();
    _getActiveLoanCount(); // fetch on load
  }

  Future<void> _getActiveLoanCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('loans')
          .where('status', isEqualTo: 'Approved') // Assuming 'Approved' is active
          .get();

      setState(() {
        activeLoanCount = snapshot.size;
      });
    } catch (e) {
      print('Error fetching active loans: $e');

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Loan Applications'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'Filter by Status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ['All', 'Approved', 'Pending', 'Rejected']
                  .map((status) => DropdownMenuItem(
                        child: Text(status),
                        value: status,

      appBar: AppBar(title: const Text('Loan Applications')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            'Total Active Loans: $activeLoanCount',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedFilter,
              items: ['All', 'Pending Approval', 'Approved', 'Rejected']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),

                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {

                    selectedStatus = value;

                    selectedFilter = value;

                  });
                }
              },
            ),
          ),
          Expanded(

            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: getLoanStream(),

            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('loans')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }


                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading loans."));
                }

                final loans = snapshot.data?.docs ?? [];

                if (loans.isEmpty) {
                  return const Center(child: Text('No loan applications found.'));
                }

                return ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index].data();
                    final memberName = loan['memberName'] ?? 'Unknown';
                    final amount = loan['amount'] ?? 'N/A';
                    final status = loan['status'] ?? 'Pending';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          'Loan for $memberName',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Amount: UGX $amount'),
                            const SizedBox(height: 4),
                            Text('Status: $status'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          // TODO: Navigate to loan details page (pass document ID or data)
                          // Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailsPage(loanId: loans[index].id)));
                        },
                      ),
                    );
                  },
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No loan applications found.'));
                }

                var loans = snapshot.data!.docs;

                if (selectedFilter != 'All') {
                  loans = loans
                      .where((doc) =>
                          (doc['status'] ?? '').toString() == selectedFilter)
                      .toList();
                }

                Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (var loan in loans) {
                  final status = (loan['status'] ?? 'Unknown').toString();
                  grouped.putIfAbsent(status, () => []).add(loan);
                }

                return ListView(
                  children: grouped.entries.map((entry) {
                    return ExpansionTile(
                      title: Text('${entry.key} (${entry.value.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: entry.value.map((loan) {
                        final data = loan.data() as Map<String, dynamic>;
                        final amount = data['amount'];
                        final purpose = data['purpose'];
                        final status = data['status'];
                        final userId = loan.reference.parent.parent?.id ?? 'Unknown';
                        final applicationDate =
                            (data['applicationDate'] as Timestamp?)?.toDate();

                        return ListTile(
                          title: Text('UGX $amount - $purpose'),
                          subtitle: Text(
                            'Status: $status\nUser: $userId\nDate: ${DateFormat.yMMMd().format(applicationDate ?? DateTime.now())}',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoanApprovalPage(
                                  loanRef: loan.reference,
                                  loanData: data,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),

                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
