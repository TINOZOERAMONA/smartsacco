import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MemberLoanDetailsPage extends StatefulWidget {
  final String userId;
  const MemberLoanDetailsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MemberLoanDetailsPage> createState() => _MemberLoanDetailsPageState();
}

class _MemberLoanDetailsPageState extends State<MemberLoanDetailsPage> {
  // Constants and Formatters
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX');
  
  // State variables
  late Stream<List<Map<String, dynamic>>> _loanStream;
  String _statusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  double? _totalSavings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }


  Map<String, int> _countLoanStatuses(List<Map<String, dynamic>> loans) {
    final Map<String, int> counts = {
      'approved': 0,
      'pending': 0,
      'rejected': 0,
    };

    for (var loan in loans) {
      final status = (loan['status'] ?? '').toString().toLowerCase().trim();
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }

    return counts;
  }


  Future<List<Map<String, dynamic>>> _fetchUserLoans(String userId) async {
    final snapshot = await FirebaseFirestore.instance

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Data initialization
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    _loanStream = _fetchUserLoans();
    await _fetchTotalSavings();
    setState(() => _isLoading = false);
  }

  // Data fetching methods
  Future<void> _fetchTotalSavings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('savings')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final type = (data['type'] ?? 'Deposit').toLowerCase();

        total += type == 'withdrawal' ? -amount : amount;
      }

      setState(() => _totalSavings = total);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching savings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchUserLoans() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('loans')
        .orderBy('applicationDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                ...data,
                'loanId': doc.id,
                'applicationDateFormatted': data['applicationDate']?.toDate(),
                'dueDateFormatted': data['dueDate']?.toDate(),
              };
            }).toList());
  }

  // Loan status methods
  Future<void> _updateLoanStatus(String loanId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('loans')
          .doc(loanId)
          .update({
        'status': status,
        'decisionDate': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan $status successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: status == 'Approved' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating loan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending approval':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // UI Components
  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: highlight ? Theme.of(context).primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final amount = (loan['amount'] ?? 0).toDouble();
    final repaid = (loan['repaidAmount'] ?? 0).toDouble();
    final progress = amount > 0 ? repaid / amount : 0;
    final status = (loan['status'] ?? 'pending approval').toString();
    final loanId = loan['loanId']?.toString();
    final appDate = loan['applicationDateFormatted'];
    final dueDate = loan['dueDateFormatted'];
    final purpose = loan['purpose']?.toString() ?? 'Not specified';
    final interestRate = (loan['interestRate'] ?? 0).toDouble();
    final totalRepayment = (loan['totalRepayment'] ?? amount).toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showLoanDetails(loan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOAN APPLICATION',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${loanId?.substring(0, 6) ?? '------'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24, thickness: 1),
              
              // Loan details
              _buildDetailRow('Amount', _currencyFormat.format(amount), highlight: true),
              _buildDetailRow('Purpose', purpose),
              if (appDate != null)
                _buildDetailRow('Applied', _dateFormat.format(appDate)),
              if (dueDate != null)
                _buildDetailRow('Due Date', _dateFormat.format(dueDate)),
              _buildDetailRow('Interest Rate', '$interestRate%'),
              _buildDetailRow('Total Repayment', _currencyFormat.format(totalRepayment)),
              
              // Progress bar
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REPAYMENT PROGRESS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: progress >= 1 ? Colors.green : Theme.of(context).primaryColor,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      if (progress < 1)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Repaid: ${_currencyFormat.format(repaid)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Total: ${_currencyFormat.format(amount)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Action buttons for pending loans
              if (status.toLowerCase() == 'pending approval' && loanId != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _updateLoanStatus(loanId, 'Rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('REJECT'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _updateLoanStatus(loanId, 'Approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('APPROVE'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLoanDetails(Map<String, dynamic> loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),),
          
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Draggable handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title
            Row(
              children: [
                const Text(
                  'Loan Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailRow('Loan ID', loan['loanId']?.toString() ?? 'N/A'),
                    _buildDetailRow('Status', loan['status']?.toString() ?? 'N/A'),
                    _buildDetailRow('Amount', _currencyFormat.format(loan['amount'] ?? 0), highlight: true),
                    _buildDetailRow('Purpose', loan['purpose']?.toString() ?? 'N/A'),
                    if (loan['applicationDateFormatted'] != null)
                      _buildDetailRow('Applied', _dateFormat.format(loan['applicationDateFormatted'])),
                    if (loan['dueDateFormatted'] != null)
                      _buildDetailRow('Due Date', _dateFormat.format(loan['dueDateFormatted'])),
                    _buildDetailRow('Interest Rate', '${(loan['interestRate'] ?? 0).toStringAsFixed(2)}%'),
                    _buildDetailRow('Repaid Amount', _currencyFormat.format(loan['repaidAmount'] ?? 0)),
                    if (loan['notes'] != null && loan['notes'].toString().isNotEmpty)
                      _buildDetailRow('Notes', loan['notes'].toString()),
                  ],
                ),
              ),
            ),
            
            // Close button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (selected) {
        setState(() => _statusFilter = selected ? value : 'All');
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _statusFilter == value ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: _statusFilter == value 
              ? Theme.of(context).primaryColor 
              : Colors.grey[300]!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Text('Name: ${userData['fullName'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Email: ${userData['email'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Phone: ${userData['phone'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                const Divider(height: 30),
                const Text('Loan History',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchUserLoans(userId),
                  builder: (context, loanSnapshot) {
                    if (loanSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (loanSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${loanSnapshot.error}'));
                    }

                    final loans = loanSnapshot.data ?? [];
                    final statusCounts = _countLoanStatuses(loans);
                    final totalLoans = loans.length;
                    if (loans.isEmpty) {
                      return const Text('No loans found for this user.');
                    }
                    Text(
                      'Loan Statuses: '
                      '${statusCounts['approved']} Approved, '
                      '${statusCounts['pending']} Pending, '
                      '${statusCounts['rejected']} Rejected '
                      '($totalLoans Total)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                    const SizedBox(height: 12);


                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: loans.length,
                      itemBuilder: (context, index) {
                        final loan = loans[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(
                                'Amount: UGX ${loan['amount']?.toString() ?? 'N/A'}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Builder(
                                builder: (context) {
                                  final rawStatus = loan['status'];
                                  final status = (rawStatus != null && rawStatus.toString().trim().isNotEmpty)
                                      ? rawStatus.toString().toLowerCase().trim()
                                      : 'not set';

                                  Color statusColor;
                                  switch (status) {
                                    case 'approved':
                                      statusColor = Colors.green;
                                      break;
                                    case 'pending':
                                      statusColor = Colors.orange;
                                      break;
                                    case 'rejected':
                                      statusColor = Colors.red;
                                      break;
                                    default:
                                      statusColor = Colors.grey;
                                  }

                                  return Row(
                                    children: [
                                      const Text('Status: '),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                // Savings summary
                if (_totalSavings != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.savings, color: Colors.green),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available Savings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),

                                Text(
                                  _currencyFormat.format(_totalSavings),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search loans...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                
                // Filter chips
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip('All', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'Approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'Pending Approval'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'Rejected'),
                    ],
                  ),
                ),
                
                // Loan list
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _loanStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading loans',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _initializeData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<Map<String, dynamic>> loans = snapshot.data!;

                      // Apply filters
                      if (_statusFilter != 'All') {
                        loans = loans.where((loan) {
                          final loanStatus = (loan['status'] ?? '').toString();
                          return loanStatus.toLowerCase() == _statusFilter.toLowerCase();
                        }).toList();
                      }

                      // Apply search
                      if (_searchController.text.isNotEmpty) {
                        final searchTerm = _searchController.text.toLowerCase();
                        loans = loans.where((loan) {
                          return loan['purpose']?.toString().toLowerCase().contains(searchTerm) == true ||
                              loan['loanId']?.toString().toLowerCase().contains(searchTerm) == true ||
                              _currencyFormat.format(loan['amount'] ?? 0).contains(searchTerm);
                        }).toList();
                      }

                      if (loans.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _statusFilter == 'All' && _searchController.text.isEmpty
                                    ? 'No loans found'
                                    : 'No matching loans',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_statusFilter != 'All' || _searchController.text.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _statusFilter = 'All';
                                      _searchController.clear();
                                    });
                                  },
                                  child: const Text('Clear filters'),
                                ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => _initializeData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: loans.length,
                          itemBuilder: (context, index) => _buildLoanCard(loans[index]),
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