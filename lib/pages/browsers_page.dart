// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

class BrowsersPage extends StatelessWidget {
  final List<Map<String, String>> borrowers = [
    {
      'name': 'John Doe',
      'phone': '+256 712 345678',
      'email': 'john@example.com',
      'status': 'Active',
    },
    {
      'name': 'Jane Smith',
      'phone': '+256 773 112233',
      'email': 'jane@example.com',
      'status': 'Inactive',
    },
    {
      'name': 'David Okello',
      'phone': '+256 701 445566',
      'email': 'okello@example.com',
      'status': 'Active',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Borrowers"),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              // Navigate to "Add Borrower" page if needed
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Registered Borrowers",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: borrowers.length,
                itemBuilder: (context, index) {
                  final borrower = borrowers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(borrower['name']![0]),
                      ),
                      title: Text(borrower['name']!),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phone: ${borrower['phone']}"),
                          Text("Email: ${borrower['email']}"),
                        ],
                      ),
                      trailing: Text(
                        borrower['status']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: borrower['status'] == 'Active'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      onTap: () {
                        // Navigate to Borrower Detail Page (optional)
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
