import 'package:flutter/material.dart';
import 'package:smartloan_sacco/models/deposit_model.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Deposit> _deposits = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _deposits = [
          Deposit(
            id: 'DEP-${DateTime.now().millisecondsSinceEpoch}',
            amount: 100000,
            date: DateTime.now().subtract(const Duration(days: 1)),
            method: 'Mobile Money',
            status: 'Completed',
            reference: 'MM-REF-12345',
            phoneNumber: '256775123456',
          ),
          Deposit(
            id: 'DEP-${DateTime.now().millisecondsSinceEpoch + 1}',
            amount: 50000,
            date: DateTime.now().subtract(const Duration(days: 3)),
            method: 'Bank Transfer',
            status: 'Pending',
            reference: 'BANK-REF-67890',
          ),
          Deposit(
            id: 'DEP-${DateTime.now().millisecondsSinceEpoch + 2}',
            amount: 200000,
            date: DateTime.now().subtract(const Duration(days: 5)),
            method: 'Mobile Money',
            status: 'Failed',
            reference: 'MM-REF-54321',
            phoneNumber: '256772987654',
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load deposits: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


