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

class EnhancedAdminDashboard extends StatefulWidget {
  const EnhancedAdminDashboard({super.key});

  @override
  EnhancedAdminDashboardState createState() => EnhancedAdminDashboardState();
}

class EnhancedAdminDashboardState extends State<EnhancedAdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _memberTransactions = [];
  bool _isLoadingTransactions = true;
  bool _isLoadingMemberTransactions = false;
  String _searchQuery = '';
  bool _showAllTransactions = false;
  String _selectedTimeFilter = 'month'; // 'day', 'week', 'month', 'all'
  final TextEditingController _searchController = TextEditingController();

  // Enhanced transaction loading with better performance and caching
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      // Calculate date based on selected filter
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedTimeFilter) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'all':
        default:
          startDate = DateTime(now.year - 1, now.month, now.day); // Last year
          break;
      }

      // Build optimized query
      Query query = _firestore
          .collectionGroup('transactions')
          .orderBy('date', descending: true);

      // Apply date filter only if not showing all
      if (_selectedTimeFilter != 'all') {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      // Limit results for better performance
      final limit = _selectedTimeFilter == 'all' ? 100 : 50;
      query = query.limit(limit);

      final snapshot = await query.get();

      List<Map<String, dynamic>> transactions = [];
      Map<String, String> userCache = {}; // Cache user names

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final userId = doc.reference.parent.parent?.id;

        // Enhanced data extraction with better error handling
        final type = data?['type']?.toString().toLowerCase() ?? 'unknown';
        final method = data?['method']?.toString() ?? 'unknown';
        final amount = (data?['amount'] ?? 0).toDouble();
        final status = data?['status']?.toString() ?? '';
        final date = data?['date'];
        final reference = data?['reference']?.toString() ?? '';
        final phoneNumber = data?['phoneNumber']?.toString() ?? '';

        // Get member name from cache or fetch
        String memberName = 'Unknown Member';
        if (userId != null) {
          if (userCache.containsKey(userId)) {
            memberName = userCache[userId]!;
          } else {
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(userId)
                  .get();
              if (userDoc.exists) {
                memberName = userDoc.data()?['fullName'] ?? 'Unknown Member';
                userCache[userId] = memberName; // Cache the result
              }
            } catch (e) {
              debugPrint('Error fetching user details: $e');
            }
          }
        }

        // Enhanced transaction description
        String description = _generateTransactionDescription(
          type,
          method,
          amount,
          reference,
        );

        transactions.add({
          'id': doc.id,
          'userId': userId,
          'memberName': memberName,
          'description': description,
          'date': date,
          'amount': amount,
          'type': type,
          'status': status,
          'method': method,
          'reference': reference,
          'phoneNumber': phoneNumber,
          'fullName': memberName.toLowerCase(),
          'searchableText': '$description $memberName $type $method $reference'
              .toLowerCase(),
        });
      }

      setState(() {
        _transactions = transactions
            .where((tx) => tx['status'] == 'Completed')
            .toList();
        _isLoadingTransactions = false;
      });
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  // Generate enhanced transaction descriptions
  String _generateTransactionDescription(
    String type,
    String method,
    double amount,
    String reference,
  ) {
    final formattedAmount = NumberFormat.currency(
      symbol: 'UGX ',
    ).format(amount);

    switch (type) {
      case 'deposit':
        return 'Deposit of $formattedAmount via $method';
      case 'withdrawal':
        return 'Withdrawal of $formattedAmount via $method';
      case 'loan repayment':
        return 'Loan repayment of $formattedAmount via $method';
      case 'loan disbursement':
        return 'Loan disbursement of $formattedAmount';
      default:
        return '${type.toUpperCase()} of $formattedAmount via $method';
    }
  }

  // Load individual member transactions with enhanced details
  Future<void> _loadMemberTransactions(
    String memberId,
    String memberName,
  ) async {
    setState(() {
      _isLoadingMemberTransactions = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(20) // Increased limit for better overview
          .get();

      final transactions = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final type = data['type']?.toString().toLowerCase() ?? 'unknown';
            final method = data['method']?.toString() ?? 'unknown';
            final amount = (data['amount'] ?? 0).toDouble();
            final status = data['status']?.toString() ?? '';
            final date = data['date'];
            final reference = data['reference']?.toString() ?? '';
            final phoneNumber = data['phoneNumber']?.toString() ?? '';

            return {
              'id': doc.id,
              'description': _generateTransactionDescription(
                type,
                method,
                amount,
                reference,
              ),
              'date': date,
              'amount': amount,
              'type': type,
              'status': status,
              'method': method,
              'reference': reference,
              'phoneNumber': phoneNumber,
            };
          })
          .where((tx) => tx['status'] == 'Completed')
          .toList();

      setState(() {
        _memberTransactions = transactions;
        _isLoadingMemberTransactions = false;
      });
    } catch (e) {
      debugPrint('Error fetching member transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading member transactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingMemberTransactions = false;
      });
    }
  }

  // Enhanced member transaction details dialog
  void _showMemberTransactions(String memberId, String memberName) {
    _loadMemberTransactions(memberId, memberName);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.person, color: Colors.blue[700]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Transaction History',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoadingMemberTransactions
                    ? const Center(child: CircularProgressIndicator())
                    : _memberTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No transactions found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _memberTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = _memberTransactions[index];
                          final dateValue = tx['date'];
                          DateTime date = dateValue is Timestamp
                              ? dateValue.toDate()
                              : DateTime.now();

                          final amount = tx['amount'] as double;
                          final type = (tx['type'] ?? '').toLowerCase();
                          final method = tx['method'] ?? '';
                          final reference = tx['reference'] ?? '';

                          Color transactionColor;
                          IconData transactionIcon;
                          String sign;

                          if (type == 'deposit') {
                            transactionColor = Colors.green;
                            transactionIcon = Icons.arrow_downward;
                            sign = '+';
                          } else if (type == 'withdrawal') {
                            transactionColor = Colors.red;
                            transactionIcon = Icons.arrow_upward;
                            sign = '-';
                          } else {
                            transactionColor = Colors.blue;
                            transactionIcon = Icons.info_outline;
                            sign = '';
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: transactionColor,
                                child: Icon(
                                  transactionIcon,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                tx['description'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat.yMMMd().add_jm().format(date),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (reference.isNotEmpty)
                                    Text(
                                      'Ref: $reference',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  Text(
                                    'via $method',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '$sign UGX${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: transactionColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle between different time filters
  void _toggleTransactionView() {
    setState(() {
      _showAllTransactions = !_showAllTransactions;
      _selectedTimeFilter = _showAllTransactions ? 'all' : 'month';
    });
    _loadTransactions();
  }

  // Change time filter
  void _changeTimeFilter(String filter) {
    setState(() {
      _selectedTimeFilter = filter;
      _showAllTransactions = filter == 'all';
    });
    _loadTransactions();
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Enhanced filtering with better search capabilities
  List<Map<String, dynamic>> get _filteredTransactions {
    if (_searchQuery.isEmpty) return _transactions;
    return _transactions.where((tx) {
      final searchableText = tx['searchableText'] ?? '';
      return searchableText.contains(_searchQuery);
    }).toList();
  }

  // Get transaction statistics
  Map<String, dynamic> get _transactionStats {
    if (_transactions.isEmpty) {
      return {
        'totalDeposits': 0.0,
        'totalWithdrawals': 0.0,
        'totalTransactions': 0,
        'averageAmount': 0.0,
      };
    }

    double totalDeposits = 0.0;
    double totalWithdrawals = 0.0;
    double totalAmount = 0.0;

    for (var tx in _transactions) {
      final amount = tx['amount'] as double;
      final type = tx['type'] as String;

      totalAmount += amount;

      if (type == 'deposit') {
        totalDeposits += amount;
      } else if (type == 'withdrawal') {
        totalWithdrawals += amount;
      }
    }

    return {
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'totalTransactions': _transactions.length,
      'averageAmount': totalAmount / _transactions.length,
    };
  }

  Future<void> _exportTransactionsCsv() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    List<List<dynamic>> rows = [
      ['Description', 'Date', 'Amount', 'Type', 'Member'],
      ..._filteredTransactions.map((tx) {
        final date = tx['date'];
        String formattedDate = '';
        if (date is Timestamp) {
          formattedDate = date.toDate().toIso8601String();
        } else {
          formattedDate = 'N/A';
        }

        return [
          tx['description'],
          formattedDate,
          tx['amount'].toStringAsFixed(2),
          tx['type'],
          tx['memberName'],
        ];
      }),
    ];

    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'Exported Transactions CSV');
    } catch (e) {
      if (kDebugMode) print('Error exporting CSV: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting CSV: $e')));
    }
  }

  void _navigateToPage(String page) {
    switch (page) {
      case 'members':
        Navigator.pushNamed(context, '/members');
        break;
      case 'active_loans':
        Navigator.pushNamed(
          context,
          '/loans',
          arguments: {'status': 'approved'},
        );
        break;
      case 'loan_approval':
        Navigator.pushNamed(context, '/loan_approval');
        break;
    }
  }

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
              onChanged: (value) {
                if (value != null) {
                  selectedType = value;
                }
              },
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
              if (titleController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
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
            content: Text('Notification sent to all members'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

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
        title: const Text('Enhanced Admin Dashboard'),
        backgroundColor: const Color(0xFF007C91),
        foregroundColor: Colors.white,
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
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = constraints.maxWidth > 800 ? 280.0 : 220.0;
              final transactionsHeight = constraints.maxWidth > 800
                  ? 320.0
                  : 260.0;

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
                          MaterialPageRoute(
                            builder: (_) => const ActiveLoansPage(),
                          ),
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
                          MaterialPageRoute(
                            builder: (_) => const PendingLoansPage(),
                          ),
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
                  _buildSearchAndFilterBar(),
                  const SizedBox(height: 16),
                  _buildTransactionsList(theme, isDark, transactionsHeight),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final stats = _transactionStats;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          // Enhanced Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Transactions',
              hintText:
                  'Search by description, type, member name, or reference',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),

          // Transaction Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Transactions',
                  '${stats['totalTransactions']}',
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Deposits',
                  'UGX ${NumberFormat('#,##0').format(stats['totalDeposits'])}',
                  Icons.arrow_downward,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Withdrawals',
                  'UGX ${NumberFormat('#,##0').format(stats['totalWithdrawals'])}',
                  Icons.arrow_upward,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Enhanced Filter Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFilterTitle(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getFilterDescription(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Filter by time period',
                      onSelected: _changeTimeFilter,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'day',
                          child: Row(
                            children: [
                              Icon(Icons.today, size: 16),
                              SizedBox(width: 8),
                              Text('Today'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'week',
                          child: Row(
                            children: [
                              Icon(Icons.view_week, size: 16),
                              SizedBox(width: 8),
                              Text('This Week'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'month',
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, size: 16),
                              SizedBox(width: 8),
                              Text('This Month'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.all_inclusive, size: 16),
                              SizedBox(width: 8),
                              Text('All Time'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleTransactionView,
                        icon: Icon(
                          _showAllTransactions
                              ? Icons.schedule
                              : Icons.all_inclusive,
                        ),
                        label: Text(
                          _showAllTransactions ? 'Show Recent' : 'Show All',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showAllTransactions
                              ? Colors.orange
                              : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _exportTransactionsCsv,
                      icon: const Icon(Icons.file_download),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getFilterTitle() {
    switch (_selectedTimeFilter) {
      case 'day':
        return 'Today\'s Transactions';
      case 'week':
        return 'This Week\'s Transactions';
      case 'month':
        return 'This Month\'s Transactions';
      case 'all':
        return 'All Transactions';
      default:
        return 'Recent Transactions';
    }
  }

  String _getFilterDescription() {
    switch (_selectedTimeFilter) {
      case 'day':
        return 'Showing transactions from today';
      case 'week':
        return 'Showing transactions from the past 7 days';
      case 'month':
        return 'Showing transactions from the past month';
      case 'all':
        return 'Showing all completed transactions';
      default:
        return 'Showing transactions from the past month';
    }
  }

  Widget _buildTransactionsList(ThemeData theme, bool isDark, double height) {
    final cardColor = isDark ? Colors.grey[800] : Colors.white;

    if (_isLoadingTransactions) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading transactions...'),
            ],
          ),
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No transactions found'
                    : 'No matching transactions',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search terms',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTransactions,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.black26,
      color: cardColor,
      child: Column(
        children: [
          // Enhanced Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transactions (${_filteredTransactions.length})',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getFilterDescription(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _loadTransactions,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh transactions',
                    ),
                    IconButton(
                      onPressed: _exportTransactionsCsv,
                      icon: const Icon(Icons.file_download),
                      tooltip: 'Export to CSV',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Enhanced Transaction List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredTransactions.length,
              itemBuilder: (context, index) {
                final tx = _filteredTransactions[index];
                final dynamic dateValue = tx['date'];
                DateTime date;

                if (dateValue is Timestamp) {
                  date = dateValue.toDate();
                } else {
                  date = DateTime.now();
                }

                final amount = tx['amount'] as double;
                final type = (tx['type'] ?? '').toLowerCase();
                final memberName = tx['memberName'] ?? 'Unknown Member';
                final method = tx['method'] ?? '';
                final reference = tx['reference'] ?? '';
                final phoneNumber = tx['phoneNumber'] ?? '';

                Color transactionColor;
                IconData transactionIcon;
                String sign;

                if (type == 'deposit') {
                  transactionColor = Colors.green;
                  transactionIcon = Icons.arrow_downward;
                  sign = '+';
                } else if (type == 'withdrawal') {
                  transactionColor = Colors.red;
                  transactionIcon = Icons.arrow_upward;
                  sign = '-';
                } else if (type == 'loan repayment') {
                  transactionColor = Colors.blue;
                  transactionIcon = Icons.account_balance;
                  sign = '+';
                } else if (type == 'loan disbursement') {
                  transactionColor = Colors.orange;
                  transactionIcon = Icons.credit_card;
                  sign = '-';
                } else {
                  transactionColor = Colors.grey;
                  transactionIcon = Icons.info_outline;
                  sign = '';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transactionColor,
                      child: Icon(
                        transactionIcon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx['description'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: transactionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: transactionColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                memberName,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat.yMMMd().add_jm().format(date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (method.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.payment,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'via $method',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (reference.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.receipt,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Ref: $reference',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$sign UGX${NumberFormat('#,##0').format(amount)}',
                          style: TextStyle(
                            color: transactionColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (phoneNumber.isNotEmpty)
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      final userId = tx['userId'];
                      if (userId != null) {
                        _showMemberTransactions(userId, memberName);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          shadowColor: Colors.black26,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: FutureBuilder<String>(
              future: valueFuture,
              builder: (context, snapshot) {
                String value = 'Loading...';
                if (snapshot.hasData) {
                  value = snapshot.data!;
                } else if (snapshot.hasError) {
                  value = 'Error';
                }

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

  Future<String> _getCurrentBalance() async {
    try {
      final snapshot = await _firestore
          .collectionGroup('transactions')
          .where('status', isEqualTo: 'Completed')
          .get();

      double totalDeposits = 0;
      double totalWithdrawals = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final amount = (data?['amount'] ?? 0).toDouble();
        final type = (data?['type'] ?? '').toString().toLowerCase();

        if (type == 'deposit') {
          totalDeposits += amount;
        } else if (type == 'withdrawal') {
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
}
