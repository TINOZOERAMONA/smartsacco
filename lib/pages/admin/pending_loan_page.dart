import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingLoansPage extends StatefulWidget {
  const PendingLoansPage({Key? key}) : super(key: key);

  @override
  _PendingLoansPageState createState() => _PendingLoansPageState();
}

class _PendingLoansPageState extends State<PendingLoansPage> {
  int _pendingLoanCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingLoanCount();
  }

  Future<void> _loadPendingLoanCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('loans')
          .where('status', isEqualTo: 'pending') // Make sure this matches your Firestore exactly
          .get();
      setState(() {
        _pendingLoanCount = snapshot.size;
      });
    } catch (e) {
      debugPrint('Error loading pending loan count: $e');
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return null;
  }

  void _sendWhatsAppReminder(String phone, String name) async {
    final message = Uri.encodeComponent(
        "Hello $name, your loan request is pending. Please wait for approval or contact support.");
    final url = Uri.parse("https://wa.me/$phone?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Loans'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Total Pending Loans: $_pendingLoanCount',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('loans')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No pending loans found.'));
                }

                final pendingLoans = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: pendingLoans.length,
                  itemBuilder: (context, index) {
                    final loan = pendingLoans[index];
                    final loanData = loan.data() as Map<String, dynamic>;

                    final pathSegments = loan.reference.path.split('/');
                    String userId = '';
                    if (pathSegments.length >= 2 && pathSegments[0] == 'users') {
                      userId = pathSegments[1];
                    }

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getUserData(userId),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading user info...'),
                          );
                        }
                        if (!userSnapshot.hasData) {
                          return ListTile(
                            title: Text('User not found'),
                            subtitle: Text('Loan ID: ${loan.id}'),
                          );
                        }

                        final userData = userSnapshot.data!;

                        double parseAmount(dynamic value) {
                          if (value == null) return 0.0;
                          if (value is num) return value.toDouble();
                          return double.tryParse(value.toString()) ?? 0.0;
                        }

                        final amount = parseAmount(loanData['amount']);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                                '${userData['name'] ?? 'Unknown'} (${userData['email'] ?? 'No Email'})',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Phone: ${userData['phone'] ?? 'N/A'}'),
                                Text('Loan Amount: UGX ${amount.toStringAsFixed(2)}'),
                                const Text('Status: Pending Approval'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.message, color: Colors.orange),
                              tooltip: 'Send WhatsApp Reminder',
                              onPressed: () {
                                final phone = userData['phone']?.toString() ?? '';
                                final name = userData['name']?.toString() ?? 'Member';
                                if (phone.isNotEmpty) {
                                  _sendWhatsAppReminder(phone, name);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('User phone number not available')),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
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
