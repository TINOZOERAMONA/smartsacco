import 'package:flutter/material.dart';

class LoansPage extends StatelessWidget {
  final List<Map<String, String>> loans = [
    {
      'refNo': 'LN001',
      'borrower': 'John Doe',
      'amount': '\$1,200.00',
      'status': 'Active',
    },
    {
      'refNo': 'LN002',
      'borrower': 'Jane Smith',
      'amount': '\$2,500.00',
      'status': 'Pending',
    },
    {
      'refNo': 'LN003',
      'borrower': 'Michael Lee',
      'amount': '\$900.00',
      'status': 'Closed',
    },
  ];

  LoansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Loans"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to "Add Loan" screen if needed
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Loan Records",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: loans.length,
                itemBuilder: (context, index) {
                  final loan = loans[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(loan['borrower'] ?? ''),
                      subtitle: Text("Ref: ${loan['refNo']} - Amount: ${loan['amount']}"),
                      trailing: Text(
                        loan['status'] ?? '',
                        style: TextStyle(
                          color: loan['status'] == 'Active'
                              ? Colors.green
                              : loan['status'] == 'Pending'
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                      ),
                      onTap: () {
                        // You can open loan details here
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
