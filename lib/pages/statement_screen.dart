import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class StatementScreen extends StatefulWidget {
  final String userName;
  final String memberId;

  const StatementScreen({
    super.key,
    required this.userName,
    required this.memberId,
  });

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  // Date range variables
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _dateRangeText = 'Last 30 Days';

  // Filter variables
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Deposits', 'Withdrawals', 'Loan Payments', 'Fees'];
  final TextEditingController _searchController = TextEditingController();

  // Sample transaction data
  final List<Transaction> _transactions = [
    Transaction(
      id: 'TX001',
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: 'Deposit',
      amount: 50000,
      description: 'Monthly savings deposit',
      balance: 250000,
    ),
    Transaction(
      id: 'TX002',
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: 'Withdrawal',
      amount: -20000,
      description: 'Emergency withdrawal',
      balance: 200000,
    ),
    Transaction(
      id: 'TX003',
      date: DateTime.now().subtract(const Duration(days: 7)),
      type: 'Loan Payment',
      amount: -15000,
      description: 'Loan installment payment',
      balance: 220000,
    ),
    Transaction(
      id: 'TX004',
      date: DateTime.now().subtract(const Duration(days: 10)),
      type: 'Deposit',
      amount: 30000,
      description: 'Additional savings',
      balance: 235000,
    ),
    Transaction(
      id: 'TX005',
      date: DateTime.now().subtract(const Duration(days: 15)),
      type: 'Fee',
      amount: -5000,
      description: 'Monthly service fee',
      balance: 205000,
    ),
    Transaction(
      id: 'TX006',
      date: DateTime.now().subtract(const Duration(days: 20)),
      type: 'Deposit',
      amount: 100000,
      description: 'Bonus savings',
      balance: 210000,
    ),
    Transaction(
      id: 'TX007',
      date: DateTime.now().subtract(const Duration(days: 25)),
      type: 'Withdrawal',
      amount: -50000,
      description: 'School fees payment',
      balance: 110000,
    ),
  ];

  // Summary statistics
  double get _totalDeposits => _filteredTransactions
      .where((t) => t.amount > 0)
      .fold(0, (sum, t) => sum + t.amount);

  double get _totalWithdrawals => _filteredTransactions
      .where((t) => t.amount < 0)
      .fold(0, (sum, t) => sum + t.amount);

  List<Transaction> get _filteredTransactions {
    return _transactions.where((transaction) {
      // Date range filter
      if (transaction.date.isBefore(_startDate) || 
          transaction.date.isAfter(_endDate)) {
        return false;
      }
      
      // Type filter
      if (_selectedFilter != 'All' && transaction.type != _selectedFilter) {
        return false;
      }
      
      // Search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return transaction.id.toLowerCase().contains(searchTerm) ||
               transaction.description.toLowerCase().contains(searchTerm) ||
               transaction.amount.toString().contains(searchTerm);
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Statement', 
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          )),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Export Statement',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter controls
          _buildFilterControls(),
          
          // Summary cards
          _buildSummaryCards(),
          
          // Transaction list
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Date range selector
            ListTile(
              leading: const Icon(Icons.calendar_today, size: 20),
              title: Text('Date Range', 
                style: GoogleFonts.poppins(fontSize: 14)),
              subtitle: Text(_dateRangeText,
                style: GoogleFonts.poppins(fontSize: 12)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _showDateRangePicker,
            ),
            
            // Search and filter row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 12),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list, size: 20),
                  onSelected: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                  itemBuilder: (context) => _filterOptions.map((option) {
                    return PopupMenuItem<String>(
                      value: option,
                      child: Text(option, 
                        style: GoogleFonts.poppins(fontSize: 12)),
                    );
                  }).toList(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedFilter, 
                          style: GoogleFonts.poppins(fontSize: 12)),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildSummaryCard(
            title: 'Total Deposits',
            amount: _totalDeposits,
            color: Colors.green,
            icon: Icons.arrow_downward,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: 'Total Withdrawals',
            amount: _totalWithdrawals.abs(),
            color: Colors.red,
            icon: Icons.arrow_upward,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: 'Transactions',
            amount: _filteredTransactions.length.toDouble(),
            color: Colors.blue,
            icon: Icons.list,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: 'Ending Balance',
            amount: _filteredTransactions.isEmpty 
                ? 0 
                : _filteredTransactions.last.balance,
            color: Colors.purple,
            icon: Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withGreen(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  )),
                Text(
                  title == 'Transactions' 
                      ? amount.toInt().toString()
                      : _formatCurrency(amount),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/no_data.svg',
              height: 100,
              colorFilter: ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn),
            ),
            const SizedBox(height: 16),
            Text('No transactions found',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              )),
            if (_selectedFilter != 'All' || _searchController.text.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'All';
                    _searchController.clear();
                  });
                },
                child: Text('Clear filters',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue,
                  )),
              ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _filteredTransactions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getTransactionColor(transaction.type).withBlue(50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTransactionIcon(transaction.type),
              size: 18,
              color: _getTransactionColor(transaction.type),
            ),
          ),
          title: Text(transaction.type,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            )),
          subtitle: Text(
            DateFormat('MMM d, y').format(transaction.date),
            style: GoogleFonts.poppins(fontSize: 10)),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatCurrency(transaction.amount),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: transaction.amount > 0 
                      ? Colors.green 
                      : Colors.red,
                )),
              Text(
                'Balance: ${_formatCurrency(transaction.balance)}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                )),
            ],
          ),
          onTap: () => _showTransactionDetails(transaction),
        );
      },
    );
  }

  void _showDateRangePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Date Range',
          style: GoogleFonts.poppins()),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SfDateRangePicker(
            initialSelectedRange: PickerDateRange(_startDate, _endDate),
            selectionMode: DateRangePickerSelectionMode.range,
            maxDate: DateTime.now(),
            onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
              if (args.value is PickerDateRange) {
                final range = args.value as PickerDateRange;
                if (range.startDate != null && range.endDate != null) {
                  setState(() {
                    _startDate = range.startDate!;
                    _endDate = range.endDate!;
                    _dateRangeText = '${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}';
                  });
                }
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = DateTime.now().subtract(const Duration(days: 30));
                _endDate = DateTime.now();
                _dateRangeText = 'Last 30 Days';
              });
              Navigator.pop(context);
            },
            child: Text('Reset',
              style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Apply',
              style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTransactionColor(transaction.type).withBlue(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTransactionIcon(transaction.type),
                    size: 20,
                    color: _getTransactionColor(transaction.type),
                  ),
                ),
                const SizedBox(width: 12),
                Text(transaction.type,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Transaction ID', transaction.id),
            _buildDetailRow('Date', DateFormat('MMM d, y - h:mm a').format(transaction.date)),
            _buildDetailRow('Amount', _formatCurrency(transaction.amount)),
            _buildDetailRow('Balance', _formatCurrency(transaction.balance)),
            const SizedBox(height: 8),
            Text('Description',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              )),
            Text(transaction.description,
              style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Close',
                  style: GoogleFonts.poppins()),
              ),
            ),
          ],
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
            child: Text('$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              )),
          ),
          Expanded(
            child: Text(value,
              style: GoogleFonts.poppins(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Export Statement',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
            const SizedBox(height: 16),
            Text('Select export format',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              )),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildExportOption(Icons.picture_as_pdf, 'PDF', Colors.red),
                _buildExportOption(Icons.grid_on, 'Excel', Colors.green),
                _buildExportOption(Icons.insert_drive_file, 'CSV', Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Cancel',
                  style: GoogleFonts.poppins()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 30, color: color),
          onPressed: () {
            Navigator.pop(context);
            _exportStatement(label.toLowerCase());
          },
        ),
        Text(label,
          style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  void _exportStatement(String format) {
    // In a real app, this would generate and save the file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting statement as $format...',
          style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'Deposit':
        return Colors.green;
      case 'Withdrawal':
        return Colors.red;
      case 'Loan Payment':
        return Colors.orange;
      case 'Fee':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'Deposit':
        return Icons.arrow_downward;
      case 'Withdrawal':
        return Icons.arrow_upward;
      case 'Loan Payment':
        return Icons.money_off;
      case 'Fee':
        return Icons.money;
      default:
        return Icons.receipt;
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }
}

class Transaction {
  final String id;
  final DateTime date;
  final String type;
  final double amount;
  final String description;
  final double balance;

  Transaction({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.description,
    required this.balance,
  });
}