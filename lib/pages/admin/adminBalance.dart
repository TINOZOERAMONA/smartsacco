import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminBalancePage extends StatefulWidget {
  const AdminBalancePage({super.key});

  @override
  State<AdminBalancePage> createState() => _AdminBalancePageState();
}

class _AdminBalancePageState extends State<AdminBalancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double? _currentBalance;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentBalance();
  }

  Future<void> _loadCurrentBalance() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snapshot = await _firestore.collection('totals').doc('balance').get();
      final balance = (snapshot.data()?['currentBalance'] ?? 0).toDouble();

      setState(() {
        _currentBalance = balance;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load balance: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedBalance = _currentBalance != null
        ? NumberFormat.currency(locale: 'en_UG', symbol: 'UGX', decimalDigits: 2)
            .format(_currentBalance)
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Total Current Balance'),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : Text(
                    formattedBalance,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
      ),
    );
  }
}
