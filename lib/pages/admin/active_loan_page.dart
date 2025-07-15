import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class ActiveLoansPage extends StatefulWidget {
  const ActiveLoansPage({super.key});

  @override
  State<ActiveLoansPage> createState() => _ActiveLoansPageState();
}

class _ActiveLoansPageState extends State<ActiveLoansPage> {
  late Future<List<Map<String, dynamic>>> _membersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _membersFuture = _fetchMembersWithLoans();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchMembersWithLoans() async {
  final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
  final List<Map<String, dynamic>> membersWithLoans = [];

  for (var userDoc in usersSnapshot.docs) {
    final userId = userDoc.id;
    final userData = userDoc.data();
    final fullName = userData['fullName'] ?? 'No Name';
    final email = userData['email'] ?? 'No Email';
    final phone = userData['phone'] ?? 'N/A';
    final joinDate = userData['joinDate']?.toDate();

    // ✅ Query loans under the user's subcollection
    final userLoansSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('loans')
        .where('status', isEqualTo: 'Approved')
        .get();

    final userLoans = userLoansSnapshot.docs.where((loanDoc) {
      final loan = loanDoc.data();
      return (loan['remainingBalance'] ?? 0) > 0;
    }).toList();

    if (userLoans.isNotEmpty) {
      final loanAmounts = userLoans.map((loan) => (loan['amount'] ?? 0).toDouble()).toList();
      final totalLoanAmount = loanAmounts.fold(0.0, (a, b) => a + b);
      final dueDates = userLoans
          .map((loan) => (loan['dueDate'] as Timestamp?)?.toDate())
          .whereType<DateTime>()
          .toList();

      if (dueDates.isNotEmpty) {
        final earliestDueDate = dueDates.reduce((a, b) => a.isBefore(b) ? a : b);
        final daysLeft = earliestDueDate.difference(DateTime.now()).inDays;

        membersWithLoans.add({
          'id': userId,
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'joinDate': joinDate,
          'dueDate': earliestDueDate,
          'daysLeft': daysLeft,
          'totalLoanAmount': totalLoanAmount,
          'loanCount': userLoans.length,
        });
      }
    }
  }

  // Sort by days remaining (ascending)
  membersWithLoans.sort((a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));
  return membersWithLoans;
}


  Widget _buildMemberCard(Map<String, dynamic> member) {
    final dueDateFormatted = DateFormat('MMM dd, yyyy').format(member['dueDate']);
    final daysLeft = member['daysLeft'];
    final isOverdue = daysLeft < 0;
    final statusColor = isOverdue ? Colors.red : (daysLeft <= 7 ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToMemberDetails(member['id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    member['fullName'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      isOverdue 
                          ? 'OVERDUE ${-daysLeft}d' 
                          : '$daysLeft days left',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Email', member['email']),
              _buildDetailRow('Phone', member['phone']),
              _buildDetailRow('Due Date', dueDateFormatted),
              _buildDetailRow('Total Loans', '${member['loanCount']}'),
              _buildDetailRow(
                'Total Amount', 
                NumberFormat.currency(locale: 'en_UG', symbol: 'UGX').format(member['totalLoanAmount']),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.email),
                    color: Colors.blue,
                    onPressed: () => _sendReminderEmail(member),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call),
                    color: Colors.green,
                    onPressed: () => _callMember(member),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMemberDetails(String userId) {
    Navigator.pushNamed(
      context,
      '/member_details',
      arguments: {'userId': userId},
    );
  }

  Future<void> _sendReminderEmail(Map<String, dynamic> member) async {
    // TODO: Implement email sending logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder email sent to ${member['email']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _callMember(Map<String, dynamic> member) async {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${member['phone']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _membersFuture = _fetchMembersWithLoans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Loan Members'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('loans') // collection group query across all users
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active loans found.'));
          }

          // Filter only approved loans
          final allApprovedLoans = snapshot.data!.docs.where((doc) {
            final loanData = doc.data() as Map<String, dynamic>;
            final status = loanData['status'] as String?;
            return _isApproved(status);
          }).toList();

          // Apply the due date filters
          final filteredLoans = allApprovedLoans.where((doc) {
            final loanData = doc.data() as Map<String, dynamic>;
            final Timestamp? dueTimestamp = loanData['dueDate'];
            if (dueTimestamp == null) return false;
            final dueDate = dueTimestamp.toDate();

            switch (_selectedFilter) {
              case LoanFilter.all:
                return true;
              case LoanFilter.dueSoon:
                return dueDate.isAfter(today) && dueDate.isBefore(next7Days);
              case LoanFilter.overdue:
                return dueDate.isBefore(today);
            }
          }).toList();

          if (filteredLoans.isEmpty) {
            return const Center(child: Text('No loans found for selected filter.'));
          }
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total Active Loans: ${filteredLoans.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );

          return ListView.builder(
            itemCount: filteredLoans.length,
            itemBuilder: (context, index) {
              final loan = filteredLoans[index];
              final loanData = loan.data() as Map<String, dynamic>;

              // Extract userId from document path: users/{userId}/loans/{loanId}
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
                  final dueDate = loanData['dueDate']?.toDate();

                  // Safely parse numeric fields, fallback to 0.0
                  double parseAmount(dynamic value) {
                    if (value == null) return 0.0;
                    if (value is num) return value.toDouble();
                    return double.tryParse(value.toString()) ?? 0.0;
                  }

                  final amount = parseAmount(loanData['amount']);
                  final monthlyPayment = parseAmount(loanData['monthlyPayment']);
                  final remainingBalance = parseAmount(loanData['remainingBalance']);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                          'Name:${userData['fullName'] ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email:${userData['email'] ?? 'No Email'}'),
                          Text('Phone: ${userData['phone'] ?? 'N/A'}'),
                          Text('Loan Amount: UGX ${amount.toStringAsFixed(2)}'),
                          Text('Monthly Payment: UGX ${monthlyPayment.toStringAsFixed(2)}'),
                          Text('Remaining Balance: UGX ${remainingBalance.toStringAsFixed(2)}'),
                          Text(
                              'Due Date: ${dueDate != null ? dueDate.toLocal().toString().split(' ')[0] : "N/A"}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.message, color: Colors.green),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search members',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load members',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }
                
                final members = snapshot.data!;
                final filteredMembers = members.where((member) {
                  return member['fullName'].toString().toLowerCase().contains(_searchQuery) ||
                      member['email'].toString().toLowerCase().contains(_searchQuery) ||
                      member['phone'].toString().toLowerCase().contains(_searchQuery);
                }).toList();
                
                if (filteredMembers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No members with active loans'
                              : 'No matching members found',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],

                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) => 
                        _buildMemberCard(filteredMembers[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}