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

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  OverviewPageState createState() => OverviewPageState();
}

class OverviewPageState extends State<OverviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  Future<void> _loadRecentTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      _transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'description': data['description'] ?? '',
          'date': data['date'],
          'amount': (data['amount'] ?? 0).toDouble(),
          'type': data['type'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_searchQuery.isEmpty) return _transactions;
    return _transactions.where((tx) {
      final desc = (tx['description'] ?? '').toLowerCase();
      final type = (tx['type'] ?? '').toLowerCase();
      return desc.contains(_searchQuery) || type.contains(_searchQuery);
    }).toList();
  }

  Future<void> _exportTransactionsCsv() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    List<List<dynamic>> rows = [
      ['Description', 'Date', 'Amount', 'Type'],
      ..._filteredTransactions.map(
        (tx) => [
          tx['description'],
          (tx['date'] as Timestamp).toDate().toIso8601String(),
          tx['amount'].toStringAsFixed(2),
          tx['type'],
        ],
      ),
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
        title: const Text('Overview'),
        actions: [
          IconButton(
            tooltip: 'Export Transactions CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportTransactionsCsv,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentTransactions,
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
                        onTap: () => _navigateToPage('active_loans'),
                      ),
                      _buildSummaryCard(
                        title: 'Pending Loans',
                        icon: Icons.pending_actions,
                        iconColor: Colors.orange.shade700,
                        valueFuture: _getPendingLoansCount(),
                        theme: theme,
                        isDark: isDark,
                        onTap: () => _navigateToPage('loan_approval'),
                      ),
                      _buildSummaryCard(
                        title: 'Total Savings',
                        icon: Icons.account_balance_wallet,
                        iconColor: Colors.teal.shade700,
                        valueFuture: _getTotalSavings(),
                        theme: theme,
                        isDark: isDark,
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
                  final approved = stats['approved'] ?? 0;
                  final pending = stats['pending'] ?? 0;
                  final rejected = stats['rejected'] ?? 0;

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
      child: TextField(
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
            _searchQuery.isEmpty
                ? 'No transactions found'
                : 'No matching transactions',
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
            final date = (tx['date'] as Timestamp).toDate();
            final amount = tx['amount'] as double;
            final isCredit = (tx['type'] ?? '').toLowerCase() == 'credit';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isCredit ? Colors.green : Colors.red,
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.white,
                ),
              ),
              title: Text(tx['description'] ?? ''),
              subtitle: Text(DateFormat.yMMMd().add_jm().format(date)),
              trailing: Text(
                '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isCredit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<String> _getTotalMembersCount() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.size.toString();
  }

  Future<String> _getActiveLoansCount() async {
    final snapshot = await _firestore
        .collection('loans')
        .where('status', isEqualTo: 'approved')
        .get();
    return snapshot.size.toString();
  }

  Future<String> _getPendingLoansCount() async {
    final snapshot = await _firestore
        .collection('loans')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.size.toString();
  }

  Future<String> _getTotalSavings() async {
    final snapshot = await _firestore.collection('savings').get();
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] ?? 0).toDouble();
    }
    return '\$${total.toStringAsFixed(2)}';
  }

  Future<Map<String, int>> _getLoanStats() async {
    final snapshot = await _firestore.collection('loans').get();
    int approved = 0, pending = 0, rejected = 0;
    for (var doc in snapshot.docs) {
      final status = (doc.data()['status'] ?? '').toString().toLowerCase();
      if (status == 'approved') {
        approved++;
      } else if (status == 'pending') {
        pending++;
      } else if (status == 'rejected') {
        rejected++;
      }
    }
    return {'approved': approved, 'pending': pending, 'rejected': rejected};
  }
}
