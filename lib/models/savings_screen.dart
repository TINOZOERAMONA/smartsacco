import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartsacco/models/member_header_section.dart';
import 'package:smartsacco/models/savings_item.dart';
import 'package:smartsacco/models/momopayment.dart';


class SavingsScreen extends StatefulWidget {
  final String memberId;

  const SavingsScreen({required this.memberId, super.key});

  @override
  _SavingsScreenState createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  double _currentSavings = 0;
  List<SavingsHistory> _savingsHistory = [];

  // Colors
  final Color _primaryColor = const Color(0xFF3366CC);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _dangerColor = const Color(0xFFF44336);
  final Color _textPrimary = const Color(0xFF333333);
  final Color _textSecondary = const Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _fetchSavingsData();
  }

  Future<void> _fetchSavingsData() async {
    final savingsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.memberId)
        .collection('savings')
        .orderBy('date', descending: true)
        .get();

    double totalSavings = 0;
    List<SavingsHistory> history = [];

    for (var doc in savingsSnapshot.docs) {
      final amount = doc['amount']?.toDouble() ?? 0;
      totalSavings += amount;
      history.add(
        SavingsHistory(
          amount: amount,
          date: doc['date'].toDate(),
          type: doc['type'] ?? 'Deposit',
          transactionId: doc.id,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _currentSavings = totalSavings;
        _savingsHistory = history;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<void> _showDepositDialog() async {
    final amountController = TextEditingController();
    final methodController = TextEditingController(text: 'Mobile Money');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Make Deposit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (UGX)',
                prefixText: 'UGX ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: methodController.text,
              items: const [
                DropdownMenuItem(
                  value: 'Mobile Money',
                  child: Text('Mobile Money'),
                ),
                DropdownMenuItem(
                  value: 'Bank Transfer',
                  child: Text('Bank Transfer'),
                ),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              ],
              onChanged: (value) => methodController.text = value!,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                if (methodController.text == 'Mobile Money') {
                  Navigator.pop(context);
                  _initiateMobileMoneyPayment(amount);
                } else {
                  _processDeposit(amount, methodController.text);
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Deposit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _initiateMobileMoneyPayment(double amount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomoPaymentPage(
          amount: amount,
          onPaymentComplete: (success) {
            if (success) {
              _processDeposit(amount, 'Mobile Money');
            }
          },
        ),
      ),
    );
  }

  Future<void> _processDeposit(double amount, String method) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('savings')
          .add({
            'amount': amount,
            'date': DateTime.now(),
            'type': 'Deposit',
            'method': method,
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('transactions')
          .add({
            'amount': amount,
            'date': DateTime.now(),
            'type': 'Deposit',
            'status': 'Completed',
            'method': method,
          });

      setState(() {
        _currentSavings += amount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deposit of ${_formatCurrency(amount)} successful'),
          backgroundColor: _successColor,
        ),
      );

      _fetchSavingsData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing deposit: $e'),
          backgroundColor: _dangerColor,
        ),
      );
    }
  }

  Widget _buildSavingsHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savings History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_savingsHistory.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 50,
                      color: _textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No savings history yet',
                      style: GoogleFonts.poppins(color: _textSecondary),
                    ),
                  ],
                ),
              )
            else
              ..._savingsHistory
                  .take(5)
                  .map((saving) => SavingsItem(
                        saving: saving,
                        formatCurrency: _formatCurrency,
                        textSecondary: _textSecondary,
                        successColor: _successColor,
                      )),
            if (_savingsHistory.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {
                    // Show full savings history
                  },
                  child: Text(
                    'View All Savings',
                    style: GoogleFonts.poppins(color: _primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HeaderSection(
            memberName: '',
            memberEmail: '',
            memberPhone: '',
            primaryColor: _primaryColor,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _successColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.savings, size: 40, color: _successColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Savings Account Balance',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(_currentSavings),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _successColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showDepositDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _successColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Make Deposit',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSavingsHistory(),
        ],
      ),
    );
  }
}

class SavingsHistory {
  final double amount;
  final DateTime date;
  final String type;
  final String transactionId;

  SavingsHistory({
    required this.amount,
    required this.date,
    required this.type,
    required this.transactionId,
  });
}