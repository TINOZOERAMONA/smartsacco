import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartsacco/pages/responsive_helper.dart';

class LoanStatsCard extends StatelessWidget {
  const LoanStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Card(
      margin: EdgeInsets.all(ResponsiveHelper.responsiveValue(
        context: context,
        mobile: 8,
        desktop: 16,
      )),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.responsiveValue(
          context: context,
          mobile: 12,
          desktop: 20,
        )),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('loans')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            int activeCount = 0;
            int overdueCount = 0;
            double totalDue = 0;
            final now = DateTime.now();

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status']?.toString() ?? '';
              final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
              final remainingBalance = (data['remainingBalance'] as num?)?.toDouble() ?? 0;

              if (status == 'Approved') {
                activeCount++;
                totalDue += remainingBalance;

                if (dueDate != null && dueDate.isBefore(now)) {
                  overdueCount++;
                }
              }
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 300) {
                  return _buildVerticalStats(activeCount, overdueCount, totalDue);
                } else {
                  return _buildHorizontalStats(activeCount, overdueCount, totalDue);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        )),
      ],
    );
  }

  Widget _buildHorizontalStats(int active, int overdue, double total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Active Loans', active.toString(), Colors.blue),
        _buildStatItem('Overdue', overdue.toString(), Colors.orange),
        _buildStatItem('Total Due', 'UGX ${total.toStringAsFixed(2)}', Colors.red),
      ],
    );
  }

  Widget _buildVerticalStats(int active, int overdue, double total) {
    return Column(
      children: [
        _buildStatItem('Active Loans', active.toString(), Colors.blue),
        const Divider(),
        _buildStatItem('Overdue', overdue.toString(), Colors.orange),
        const Divider(),
        _buildStatItem('Total Due', 'UGX ${total.toStringAsFixed(2)}', Colors.red),
      ],
    );
  }
}