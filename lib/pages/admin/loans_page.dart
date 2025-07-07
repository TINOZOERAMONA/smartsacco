import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  LoansPageState createState() => LoansPageState();
}

class LoansPageState extends State<LoansPage> {
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
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: getLoanStream(),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
