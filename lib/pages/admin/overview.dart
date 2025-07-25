// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smartsacco/pages/admin/pending_loan_page.dart';
import 'package:smartsacco/services/notification_service.dart';
import 'package:smartsacco/models/notification.dart';
import 'active_loan_page.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  OverviewPageState createState() => OverviewPageState();
}

class OverviewPageState extends State<OverviewPage> {
  // Constants and Variables
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _memberTransactions = [];
  bool _isLoadingTransactions = true;
  bool _isLoadingMemberTransactions = false;
  String _searchQuery = '';
  bool _showAllTransactions = false;

  // Initialization and Cleanup
  @override
  void initState() {
    super.initState();
    _loadRecentTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Data Loading Methods
  Future<void> _loadRecentTransactions() async {
    setState(() => _isLoadingTransactions = true);

    try {
      final now = DateTime.now();
      final pastMonth = DateTime(now.year, now.month - 1, now.day);

      Query query = _firestore
          .collectionGroup('transactions')
          .orderBy('date', descending: true);

      if (!_showAllTransactions) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(pastMonth));
      }

      final snapshot = await query.limit(_showAllTransactions ? 100 : 50).get();
      List<Map<String, dynamic>> transactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = doc.reference.parent.parent?.id;
        String memberName = 'Unknown Member';

        if (userId != null) {
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              memberName = userDoc.data()?['fullName'] ?? 'Unknown Member';
            }
          } catch (e) {
            debugPrint('Error fetching user details: $e');
          }
        }

        transactions.add({
          'id': doc.id,
          'userId': userId,
          'memberName': memberName,
          'description': '${data['type'] ?? ''} via ${data['method'] ?? ''}',
          'date': data['date'],
          'amount': (data['amount'] ?? 0).toDouble(),
          'type': (data['type'] ?? '').toString().toLowerCase(),
          'status': data['status'] ?? '',
          'method': data['method'] ?? '',
          'fullName': memberName.toLowerCase(),
        });
      }

      setState(() {
        _transactions = transactions.where((tx) => tx['status'] == 'Completed').toList();
        _isLoadingTransactions = false;
      });
    } catch (e) {
      debugPrint('Error fetching recent transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
      setState(() => _isLoadingTransactions = false);
    }
  }

  Future<void> _loadMemberTransactions(String memberId, String memberName) async {
    setState(() => _isLoadingMemberTransactions = true);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(20)
          .get();

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'description': '${data['type']} via ${data['method']}',
          'date': data['date'],
          'amount': (data['amount'] ?? 0).toDouble(),
          'type': (data['type'] ?? '').toString().toLowerCase(),
          'status': data['status'] ?? '',
          'method': data['method'] ?? '',
        };
      }).where((tx) => tx['status'] == 'Completed').toList();

      setState(() {
        _memberTransactions = transactions;
        _isLoadingMemberTransactions = false;
      });
    } catch (e) {
      debugPrint('Error fetching member transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading member transactions: $e')),
        );
      }
      setState(() => _isLoadingMemberTransactions = false);
    }
  }

  // UI Helper Methods
  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Future<String> valueFuture,
    required ThemeData theme,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final cardColor = isDark ? Colors.grey[800] : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: Colors.black26,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: FutureBuilder<String>(
              future: valueFuture,
              builder: (context, snapshot) {
                String value = snapshot.hasData ? snapshot.data! : 
                    snapshot.hasError ? 'Error' : 'Loading...';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 36, color: iconColor),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoansChart(ThemeData theme, bool isDark, double height) {
    final cardColor = isDark ? Colors.grey[800] : Colors.white;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.black26,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loans Overview',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height - 50,
              child: FutureBuilder<Map<String, int>>(
                future: _getLoanStats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final stats = snapshot.data!;
                  final approved = stats['Approved'] ?? 0;
                  final pending = stats['Pending Approval'] ?? 0;
                  final rejected = stats['Rejected'] ?? 0;
                  final total = approved + pending + rejected;

                  if (total == 0) {
                    return Center(
                      child: Text(
                        'No loans data available',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  return PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: approved.toDouble(),
                          color: Colors.green,
                          title: '$approved',
                        ),
                        PieChartSectionData(
                          value: pending.toDouble(),
                          color: Colors.orange,
                          title: '$pending',
                        ),
                        PieChartSectionData(
                          value: rejected.toDouble(),
                          color: Colors.red,
                          title: '$rejected',
                        ),
                      ],
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Transactions',
              hintText: 'Search by description or type',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showAllTransactions 
                    ? 'Showing All Transactions' 
                    : 'Showing Recent Transactions (Past Month)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _toggleTransactionView,
                icon: Icon(_showAllTransactions ? Icons.schedule : Icons.all_inclusive),
                label: Text(_showAllTransactions ? 'Show Recent' : 'Show All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showAllTransactions ? Colors.orange : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme, bool isDark, double height) {
    final cardColor = isDark ? Colors.grey[800] : Colors.white;

    if (_isLoadingTransactions) {
      return SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            _searchQuery.isEmpty ? 'No transactions found' : 'No matching transactions',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.black26,
      color: cardColor,
      child: SizedBox(
        height: height,
        child: ListView.builder(
          itemCount: _filteredTransactions.length,
          itemBuilder: (context, index) {
            final tx = _filteredTransactions[index];
            final dynamic dateValue = tx['date'];
            DateTime date = dateValue is Timestamp ? dateValue.toDate() : DateTime.now();
            
            if (dateValue == null) {
              debugPrint('Warning: Transaction ${tx['description']} has a null date');
            }

            final amount = tx['amount'] as double;
            final type = (tx['type'] ?? '').toLowerCase();
            final memberName = tx['memberName'] ?? 'Unknown Member';

            final isDeposit = type == 'deposit';
            final transactionColor = isDeposit ? Colors.green : Colors.red;
            final transactionIcon = isDeposit ? Icons.arrow_downward : Icons.arrow_upward;
            final sign = isDeposit ? '+' : '-';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: transactionColor,
                child: Icon(transactionIcon, color: Colors.white),
              ),
              title: Text(tx['description'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat.yMMMd().add_jm().format(date)),
                  Text(
                    memberName,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: Text(
                '$sign UGX${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: transactionColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                final userId = tx['userId'];
                if (userId != null) {
                  _showMemberTransactions(userId, memberName);
                }
              },
            );
          },
        ),
      ),
    );
  }

  // Utility Methods
  List<Map<String, dynamic>> get _filteredTransactions {
    if (_searchQuery.isEmpty) return _transactions;
    return _transactions.where((tx) {
      final desc = (tx['description'] ?? '').toLowerCase();
      final type = (tx['type'] ?? '').toLowerCase();
      final fullName = (tx['fullName'] ?? '').toLowerCase();
      return desc.contains(_searchQuery) || 
             type.contains(_searchQuery) || 
             fullName.contains(_searchQuery);
    }).toList();
  }

  void _toggleTransactionView() {
    setState(() => _showAllTransactions = !_showAllTransactions);
    _loadRecentTransactions();
  }

  void _showMemberTransactions(String memberId, String memberName) {
    _loadMemberTransactions(memberId, memberName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$memberName\'s Transactions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _isLoadingMemberTransactions
              ? const Center(child: CircularProgressIndicator())
              : _memberTransactions.isEmpty
                  ? const Center(child: Text('No transactions found'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _memberTransactions.length,
                            itemBuilder: (context, index) {
                              final tx = _memberTransactions[index];
                              final dateValue = tx['date'];
                              DateTime date = dateValue is Timestamp 
                                  ? dateValue.toDate() 
                                  : DateTime.now();

                              final amount = tx['amount'] as double;
                              final type = tx['type'] as String;
                              final isDeposit = type == 'deposit';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDeposit ? Colors.green : Colors.red,
                                  child: Icon(
                                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(tx['description']),
                                subtitle: Text(DateFormat.yMMMd().add_jm().format(date)),
                                trailing: Text(
                                  '${isDeposit ? '+' : '-'} UGX${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isDeposit ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Data Export Methods
  Future<void> _exportTransactionsCsv() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    List<List<dynamic>> rows = [
      ['Description', 'Date', 'Amount', 'Type'],
      ..._filteredTransactions.map((tx) {
        final date = tx['date'];
        String formattedDate = date is Timestamp 
            ? date.toDate().toIso8601String() 
            : 'N/A';

        return [
          tx['description'],
          formattedDate,
          tx['amount'].toStringAsFixed(2),
          tx['type'],
        ];
      }),
    ];

    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Exported Transactions CSV',
      );
    } catch (e) {
      if (kDebugMode) print('Error exporting CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
  }

  // Navigation Methods
  void _navigateToPage(String page) {
    switch (page) {
      case 'members':
        Navigator.pushNamed(context, '/members');
        break;
      case 'active_loans':
        Navigator.pushNamed(context, '/loans', arguments: {'status': 'approved'});
        break;
      case 'loan_approval':
        Navigator.pushNamed(context, '/loan_approval');
        break;
    }
  }

  // Notification Methods
  void _showNotificationDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    NotificationType selectedType = NotificationType.general;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification to All Members'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter notification title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Enter notification message',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<NotificationType>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Notification Type'),
              items: NotificationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) => selectedType = value ?? selectedType,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                Navigator.pop(context);
                await _sendNotificationToAll(
                  titleController.text,
                  messageController.text,
                  selectedType,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotificationToAll(
    String title,
    String message,
    NotificationType type,
  ) async {
    try {
      final notificationService = NotificationService();
      await notificationService.sendNotificationToAllUsers(
        title: title,
        message: message,
        type: type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully to all members'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: $e')),
        );
      }
    }
  }

  // Firestore Query Methods
  Future<String> _getCurrentBalance() async {
    try {
      final snapshot = await _firestore
          .collectionGroup('transactions')
          .where('status', isEqualTo: 'Completed')
          .get();

      double totalDeposits = 0;
      double totalWithdrawals = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final type = (data['type'] ?? '').toString().toLowerCase();

        if (type == 'deposit') {
          totalDeposits += amount;
        } else if (type == 'withdraw') {
          totalWithdrawals += amount;
        }
      }

      final currentBalance = totalDeposits - totalWithdrawals;
      return NumberFormat.currency(
        locale: 'en_UG',
        symbol: 'UGX',
        decimalDigits: 2,
      ).format(currentBalance);
    } catch (e) {
      debugPrint('Error calculating current balance: $e');
      return 'Error';
    }
  }

  Future<String> _getTotalMembersCount() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.size.toString();
    } catch (e) {
      debugPrint('Error fetching total members count: $e');
      return '0';
    }
  }

  Future<String> _getActiveLoansCount() async {
    try {
      final snapshot = await _firestore
          .collectionGroup('loans')
          .where('status', isEqualTo: 'Approved')
          .get();
      return snapshot.size.toString();
    } catch (e) {
      debugPrint('Error fetching active loans count: $e');
      return '0';
    }
  }

  Future<String> _getPendingLoansCount() async {
    try {
      final snapshot = await _firestore
          .collectionGroup('loans')
          .where('status', isEqualTo: 'Pending Approval')
          .get();
      return snapshot.size.toString();
    } catch (e) {
      debugPrint('Error fetching pending loans count: $e');
      return '0';
    }
  }

  Future<Map<String, int>> _getLoanStats() async {
    try {
      final approvedSnapshot = await _firestore
          .collectionGroup('loans')
          .where('status', isEqualTo: 'Approved')
          .get();
      final pendingSnapshot = await _firestore
          .collectionGroup('loans')
          .where('status', isEqualTo: 'Pending Approval')
          .get();
      final rejectedSnapshot = await _firestore
          .collectionGroup('loans')
          .where('status', isEqualTo: 'Rejected')
          .get();

      return {
        'Approved': approvedSnapshot.size,
        'Pending Approval': pendingSnapshot.size,
        'Rejected': rejectedSnapshot.size,
      };
    } catch (e) {
      debugPrint('Error fetching loan stats: $e');
      return {'Approved': 0, 'Pending Approval': 0, 'Rejected': 0};
    }
  }

  // Main Build Method
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    int gridCount;
    if (screenWidth > 1200) {
      gridCount = 4;
    } else if (screenWidth > 800) {
      gridCount = isPortrait ? 2 : 4;
    } else if (screenWidth > 600) {
      gridCount = 2;
    } else {
      gridCount = 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            tooltip: 'Send Notification',
            icon: const Icon(Icons.notifications),
            onPressed: _showNotificationDialog,
          ),
          IconButton(
            tooltip: 'Export Transactions CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportTransactionsCsv,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecentTransactions,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth > 800 ? 280.0 : 220.0;
                final transactionsHeight = constraints.maxWidth > 800 ? 320.0 : 260.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GridView.count(
                      crossAxisCount: gridCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isPortrait ? 1.6 : 1.2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildSummaryCard(
                          title: 'Total Members',
                          icon: Icons.people,
                          iconColor: theme.colorScheme.primary,
                          valueFuture: _getTotalMembersCount(),
                          theme: theme,
                          isDark: isDark,
                          onTap: () => _navigateToPage('members'),
                        ),
                        _buildSummaryCard(
                          title: 'Active Loans',
                          icon: Icons.credit_card,
                          iconColor: Colors.green.shade700,
                          valueFuture: _getActiveLoansCount(),
                          theme: theme,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ActiveLoansPage()),
                          ),
                        ),
                        _buildSummaryCard(
                          title: 'Pending Loans',
                          icon: Icons.pending_actions,
                          iconColor: Colors.orange.shade700,
                          valueFuture: _getPendingLoansCount(),
                          theme: theme,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PendingLoansPage()),
                          ),
                        ),
                        _buildSummaryCard(
                          title: 'Total Savings',
                          icon: Icons.account_balance_wallet,
                          iconColor: Colors.teal.shade700,
                          valueFuture: _getCurrentBalance(),
                          theme: theme,
                          isDark: isDark,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildLoansChart(theme, isDark, chartHeight),
                    const SizedBox(height: 24),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildRecentTransactions(theme, isDark, transactionsHeight),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}