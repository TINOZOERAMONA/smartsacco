// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:smartsacco/pages/responsive_helper.dart';

// class RecentActivities extends StatelessWidget {
//   const RecentActivities({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return const SizedBox();

//     return Card(
//       margin: EdgeInsets.all(ResponsiveHelper.responsiveValue(
//         context: context,
//         mobile: 8,
//         desktop: 16,
//       )),
//       child: Padding(
//         padding: EdgeInsets.all(ResponsiveHelper.responsiveValue(
//           context: context,
//           mobile: 12,
//           desktop: 20,
//         )),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Recent Transactions',
//               style: TextStyle(
//                 fontSize: ResponsiveHelper.responsiveValue(
//                   context: context,
//                   mobile: 16,
//                   desktop: 20,
//                 ),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('transactions')
//                   .where('userId', isEqualTo: user.uid)
//                   .orderBy('timestamp', descending: true)
//                   .limit(10)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(child: Text('No transactions yet'));
//                 }

//                 final transactions = snapshot.data!.docs.map((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   return {
//                     'type': data['type']?.toString() ?? 'transaction',
//                     'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
//                     'description': data['description']?.toString() ?? '',
//                     'method': data['method']?.toString() ?? '',
//                     'timestamp': data['timestamp'] as Timestamp,
//                     'status': data['status']?.toString() ?? 'completed',
//                   };
//                 }).toList();

//                 return LayoutBuilder(
//                   builder: (context, constraints) {
//                     return constraints.maxWidth > 400
//                         ? _buildWideLayout(transactions)
//                         : _buildCompactLayout(transactions);
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   IconData _getActivityIcon(String type) {
//     switch (type.toLowerCase()) {
//       case 'deposit': return Icons.arrow_downward;
//       case 'withdrawal': return Icons.arrow_upward;
//       case 'loan payment': return Icons.money;
//       case 'loan approval': return Icons.check_circle;
//       case 'loan application': return Icons.description;
//       default: return Icons.receipt;
//     }
//   }

//   Color _getActivityColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'deposit': return Colors.green;
//       case 'withdrawal': return Colors.red;
//       case 'loan payment': return Colors.blue;
//       default: return Colors.grey;
//     }
//   }

//   String _formatDescription(Map<String, dynamic> transaction) {
//     final amount = transaction['amount'];
//     final method = transaction['method'];
//     final type = transaction['type'];
    
//     final amountStr = NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
//         .format(amount);
        
//     switch (type.toLowerCase()) {
//       case 'deposit':
//         return 'Deposited $amountStr via $method';
//       case 'withdrawal':
//         return 'Withdrew $amountStr via $method';
//       case 'loan payment':
//         return 'Loan payment of $amountStr';
//       case 'loan approval':
//         return 'Loan approved: $amountStr';
//       default:
//         return transaction['description'] ?? 'Transaction: $amountStr';
//     }
//   }

//   Widget _buildWideLayout(List<Map<String, dynamic>> transactions) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: DataTable(
//         columns: const [
//           DataColumn(label: Text('Type')),
//           DataColumn(label: Text('Amount')),
//           DataColumn(label: Text('Details')),
//           DataColumn(label: Text('Date')),
//           DataColumn(label: Text('Status')),
//         ],
//         rows: transactions.map((t) => DataRow(
//           cells: [
//             DataCell(
//               Row(
//                 children: [
//                   Icon(
//                     _getActivityIcon(t['type']),
//                     color: _getActivityColor(t['type']),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(t['type'].toString().toTitleCase()),
//                 ],
//               ),
//             ),
//             DataCell(Text(
//               NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
//                   .format(t['amount']),
//               style: TextStyle(
//                 color: _getActivityColor(t['type']),
//                 fontWeight: FontWeight.bold,
//               ),
//             )),
//             DataCell(Text(_formatDescription(t))),
//             DataCell(Text(DateFormat('MMM dd, yyyy').format(
//               (t['timestamp'] as Timestamp).toDate()
//             ))),
//             DataCell(
//               Chip(
//                 label: Text(
//                   t['status'].toString().toTitleCase(),
//                   style: const TextStyle(fontSize: 12),
//                 ),
//                 backgroundColor: t['status'] == 'completed'
//                     ? Colors.green[100]
//                     : Colors.orange[100],
//               ),
//             ),
//           ],
//         )).toList(),
//       ),
//     );
//   }

//   Widget _buildCompactLayout(List<Map<String, dynamic>> transactions) {
//     return ListView.separated(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: transactions.length,
//       separatorBuilder: (context, index) => const Divider(height: 1),
//       itemBuilder: (context, index) {
//         final t = transactions[index];
//         return ListTile(
//           leading: Icon(
//             _getActivityIcon(t['type']),
//             color: _getActivityColor(t['type']),
//           ),
//           title: Text(_formatDescription(t)),
//           subtitle: Text(
//             DateFormat('MMM dd, hh:mm a').format(
//               (t['timestamp'] as Timestamp).toDate()
//             ),
//           ),
//           trailing: Text(
//             NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
//                 .format(t['amount']),
//             style: TextStyle(
//               color: _getActivityColor(t['type']),
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           dense: true,
//         );
//       },
//     );
//   }
// }

// extension StringCasingExtension on String {
//   String toTitleCase() => replaceAll(RegExp(' +'), ' ')
//       .split(' ')
//       .map((str) => str.isNotEmpty
//           ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
//           : '')
//       .join(' ');
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ActivityItem extends StatelessWidget {
  final dynamic item;
  final bool isTransaction;
  final String Function(double) formatCurrency;
  final Color Function(String) getStatusColor;
  final Color textSecondary;
  final Color primaryColor;
  final Color dangerColor;
  final Color successColor;

  const ActivityItem({
    required this.item,
    required this.isTransaction,
    required this.formatCurrency,
    required this.getStatusColor,
    required this.textSecondary,
    required this.primaryColor,
    required this.dangerColor,
    required this.successColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTransaction
                  ? (item.type == 'Deposit'
                      ? successColor.withOpacity(0.2)
                      : primaryColor.withOpacity(0.2))
                  : primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTransaction
                  ? (item.type == 'Deposit'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward)
                  : Icons.notifications,
              color: isTransaction
                  ? (item.type == 'Deposit' ? successColor : primaryColor)
                  : primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTransaction ? item.type : item.title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                Text(
                  isTransaction
                      ? '${formatCurrency(item.amount)} • ${DateFormat('MMM d').format(item.date)}'
                      : DateFormat('MMM d, h:mm a').format(item.date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isTransaction)
            Chip(
              label: Text(item.status),
              backgroundColor: getStatusColor(item.status),
              labelStyle: GoogleFonts.poppins(fontSize: 12),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}