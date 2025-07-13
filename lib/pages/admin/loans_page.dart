import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'loan_approval_page.dart';

class LoanPage extends StatefulWidget {
  const LoanPage({Key? key}) : super(key: key);

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  String selectedFilter = 'All';
  int activeLoanCount = 0;

  @override
  void initState() {
    super.initState();
    _getActiveLoanCount();
  }

  Future<void> _getActiveLoanCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('loans')
          .where('status', isEqualTo: 'Approved')
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
              isExpanded: true,
              items: ['All', 'Pending Approval', 'Approved', 'Rejected']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFilter = value;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('loans')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading loans."));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No loan applications found.'));
                }

                var loans = snapshot.data!.docs;

                // Apply filtering by status
                if (selectedFilter != 'All') {
                  loans = loans.where((doc) {
                    final status = (doc['status'] ?? '').toString();
                    return status == selectedFilter;
                  }).toList();
                }

                // Group by status for UI
                Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (var loan in loans) {
                  final status = (loan['status'] ?? 'Unknown').toString();
                  grouped.putIfAbsent(status, () => []).add(loan);
                }

                return ListView(
                  children: grouped.entries.map((entry) {
                    return ExpansionTile(
                      title: Text(
                        '${entry.key} (${entry.value.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                                  loanId: loan.id,
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
