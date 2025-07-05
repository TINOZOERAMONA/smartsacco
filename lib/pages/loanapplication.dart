import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class LoanApplicationScreen extends StatefulWidget {
  final String memberId;
  final double memberSavings;
  final Function(Map<String, dynamic>) onSubmit;

  const LoanApplicationScreen({
    super.key,
    required this.memberId,
    required this.memberSavings,
    required this.onSubmit,
  });

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  
  String _loanType = 'Personal';
  int _repaymentPeriod = 6;
  List<PlatformFile> _documents = [];
  bool _isSubmitting = false;
  final double _interestRate = 12.0;

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }