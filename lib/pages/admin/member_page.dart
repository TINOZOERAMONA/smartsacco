import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  late Future<List<Map<String, dynamic>>> _membersFuture;
  double _totalActiveLoans = 0.0;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    _membersFuture = _fetchMembers();
    final members = await _membersFuture;
    double total = 0.0;
    for (var member in members) {
      total += (member['totalLoan'] ?? 0);
    }
    setState(() {
      _totalActiveLoans = total;
    });
  }

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
      final remainingRaw = data['remainingBalance'];

      final remaining = (remainingRaw is num) ? remainingRaw.toDouble() : 0.0;

      if (status == 'approved' && remaining > 0) {
        totalApprovedLoans[userId] =
            (totalApprovedLoans[userId] ?? 0) + remaining;
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

  void _showActiveLoanDetails(BuildContext context, List<Map<String, dynamic>> members) {
    final activeMembers = members.where((m) => (m['totalLoan'] ?? 0) > 0).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Active Team Members',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: activeMembers.length,
                itemBuilder: (context, index) {
                  final member = activeMembers[index];
                  return ListTile(
                    title: Text(member['fullName']),
                    subtitle: Text(member['email']),
                    trailing: Text(
                      NumberFormat.currency(locale: 'en_UG', symbol: 'UGX')
                          .format(member['totalLoan']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/member_details',
                        arguments: {'userId': member['id']},
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registered Members')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _membersFuture,
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  onTap: () => _showActiveLoanDetails(context, members),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bar_chart, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Active Team: ${NumberFormat.currency(locale: 'en_UG',).format(_totalActiveLoans)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(member['fullName']),
                        subtitle: Text('Email: ${member['email']}'),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/member_details',
                            arguments: {'userId': member['id']},
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
