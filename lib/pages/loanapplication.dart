// // // loanapplication.dart (updated)
// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// // import 'package:file_picker/file_picker.dart';

// // class LoanApplicationScreen extends StatefulWidget {
// //   final String memberId;
// //   final double memberSavings;
// //   final Function(Map<String, dynamic>) onSubmit;

// //   const LoanApplicationScreen({
// //     super.key,
// //     required this.memberId,
// //     required this.memberSavings,
// //     required this.onSubmit,
// //   });

// //   @override
// //   State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
// // }

// // class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _amountController = TextEditingController();
// //   final _purposeController = TextEditingController();

// //   String _loanType = 'Personal';
// //   int _repaymentPeriod = 6;
// //   List<PlatformFile> _documents = [];
// //   bool _isSubmitting = false;
// //   final double _interestRate = 12.0;

// //   @override
// //   void dispose() {
// //     _amountController.dispose();
// //     _purposeController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final maxLoanAmount = widget.memberSavings * 3;
// //     final theme = Theme.of(context);

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Loan Application'),
// //         backgroundColor: Colors.blue,
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(20),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 'New Loan Application',
// //                 style: theme.textTheme.headlineSmall?.copyWith(
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 20),

// //               // Eligibility Card
// //               _buildEligibilityCard(maxLoanAmount, theme),
// //               const SizedBox(height: 30),

// //               // Loan Amount Field
// //               TextFormField(
// //                 controller: _amountController,
// //                 decoration: InputDecoration(
// //                   labelText: 'Loan Amount (UGX)',
// //                   prefixText: 'UGX ',
// //                   hintText: 'Enter amount between 50,000 and ${_formatCurrency(maxLoanAmount)}',
// //                   suffixIcon: IconButton(
// //                     icon: const Icon(Icons.info),
// //                     onPressed: () => _showMaxLoanInfo(maxLoanAmount),
// //                   ),
// //                 ),
// //                 keyboardType: TextInputType.number,
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) return 'Please enter amount';
// //                   final amount = double.tryParse(value) ?? 0;
// //                   if (amount < 50000) return 'Minimum loan is UGX 50,000';
// //                   if (amount > maxLoanAmount) return 'Amount exceeds your limit';
// //                   return null;
// //                 },
// //               ),
// //               const SizedBox(height: 20),

// //               // Loan Type Dropdown
// //               DropdownButtonFormField<String>(
// //                 value: _loanType,
// //                 items: const [
// //                   DropdownMenuItem(value: 'Personal', child: Text('Personal Loan')),
// //                   DropdownMenuItem(value: 'Business', child: Text('Business Loan')),
// //                   DropdownMenuItem(value: 'Emergency', child: Text('Emergency Loan')),
// //                   DropdownMenuItem(value: 'Education', child: Text('Education Loan')),
// //                 ],
// //                 onChanged: (value) => setState(() => _loanType = value!),
// //                 decoration: const InputDecoration(
// //                   labelText: 'Loan Type',
// //                 ),
// //               ),
// //               const SizedBox(height: 20),

// //               // Purpose Field
// //               TextFormField(
// //                 controller: _purposeController,
// //                 decoration: const InputDecoration(
// //                   labelText: 'Purpose of Loan',
// //                   hintText: 'Briefly describe what you need the loan for',
// //                 ),
// //                 maxLines: 3,
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) return 'Please enter purpose';
// //                   if (value.length < 10) return 'Please provide more details';
// //                   return null;
// //                 },
// //               ),
// //               const SizedBox(height: 20),

// //               // Repayment Period
// //               DropdownButtonFormField<int>(
// //                 value: _repaymentPeriod,
// //                 items: [3, 6, 9, 12, 18, 24].map((months) {
// //                   return DropdownMenuItem(
// //                     value: months,
// //                     child: Text('$months months'),
// //                   );
// //                 }).toList(),
// //                 onChanged: (value) => setState(() => _repaymentPeriod = value!),
// //                 decoration: const InputDecoration(
// //                   labelText: 'Repayment Period',
// //                 ),
// //               ),
// //               const SizedBox(height: 30),

// //               // Repayment Preview
// //               _buildRepaymentPreview(),
// //               const SizedBox(height: 30),

// //               // Documents Section
// //               _buildDocumentsSection(theme),
// //               const SizedBox(height: 30),

// //               // Submit Button
// //               _buildSubmitButton(),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildEligibilityCard(double maxLoanAmount, ThemeData theme) {
// //     return Card(
// //       color: Colors.blue[50],
// //       child: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(
// //               children: [
// //                 Icon(Icons.verified_user, color: Colors.blue[700]),
// //                 const SizedBox(width: 10),
// //                 Text(
// //                   'Loan Eligibility',
// //                   style: theme.textTheme.titleMedium?.copyWith(
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 10),
// //             Text(
// //               'Based on your savings of ${_formatCurrency(widget.memberSavings)}, '
// //               'you qualify for a maximum loan of ${_formatCurrency(maxLoanAmount)}',
// //               style: theme.textTheme.bodyMedium,
// //             ),
// //             const SizedBox(height: 10),
// //             Text(
// //               'Interest Rate: $_interestRate% per annum',
// //               style: theme.textTheme.bodyMedium?.copyWith(
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildRepaymentPreview() {
// //     final amount = double.tryParse(_amountController.text) ?? 0;
// //     final interest = (amount * _interestRate / 100) * (_repaymentPeriod / 12);
// //     final totalRepayment = amount + interest;
// //     final monthlyPayment = _repaymentPeriod > 0
// //         ? totalRepayment / _repaymentPeriod
// //         : 0.0;

// //     return Card(
// //       elevation: 2,
// //       child: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               'REPAYMENT ESTIMATE',
// //               style: Theme.of(context).textTheme.titleSmall?.copyWith(
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.grey[600],
// //                   ),
// //             ),
// //             const SizedBox(height: 15),
// //             _buildRepaymentRow('Loan Amount:', _formatCurrency(amount)),
// //             _buildRepaymentRow('Interest Rate:', '$_interestRate% p.a.'),
// //             _buildRepaymentRow('Interest Amount:', _formatCurrency(interest)),
// //             const Divider(height: 20),
// //             _buildRepaymentRow('Total Repayable:', _formatCurrency(totalRepayment)),
// //             const SizedBox(height: 10),
// //             _buildRepaymentRow(
// //               'Monthly Installment:',
// //               _formatCurrency(monthlyPayment),
// //               bold: true,
// //               color: Colors.green[700],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildDocumentsSection(ThemeData theme) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Supporting Documents',
// //           style: theme.textTheme.titleMedium?.copyWith(
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         const SizedBox(height: 10),
// //         Text(
// //           'Upload any supporting documents (ID, payslips, business docs)',
// //           style: theme.textTheme.bodySmall,
// //         ),
// //         const SizedBox(height: 10),
// //         OutlinedButton(
// //           onPressed: _pickDocuments,
// //           child: const Text('Select Files'),
// //         ),
// //         if (_documents.isNotEmpty) ...[
// //           const SizedBox(height: 10),
// //           Wrap(
// //             spacing: 8,
// //             children: _documents.map((file) => Chip(
// //               label: Text(file.name),
// //               deleteIcon: const Icon(Icons.close, size: 18),
// //               onDeleted: () => setState(() => _documents.remove(file)),
// //             )).toList(),
// //           ),
// //         ],
// //       ],
// //     );
// //   }

// //   Widget _buildSubmitButton() {
// //     return SizedBox(
// //       width: double.infinity,
// //       height: 50,
// //       child: ElevatedButton(
// //         onPressed: _isSubmitting ? null : _submitApplication,
// //         style: ElevatedButton.styleFrom(
// //           backgroundColor: Colors.blue,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(8),
// //           ),
// //         ),
// //         child: _isSubmitting
// //             ? const CircularProgressIndicator()
// //             : Text(
// //                 'SUBMIT APPLICATION',
// //                 style: Theme.of(context).textTheme.labelLarge?.copyWith(
// //                       color: Colors.white,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //               ),
// //       ),
// //     );
// //   }

// //   Future<void> _pickDocuments() async {
// //     try {
// //       final result = await FilePicker.platform.pickFiles(
// //         allowMultiple: true,
// //         type: FileType.custom,
// //         allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
// //       );

// //       if (result != null && mounted) {
// //         setState(() => _documents = result.files);
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Error selecting files: $e')),
// //         );
// //       }
// //     }
// //   }

// //   void _showMaxLoanInfo(double maxAmount) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text('Loan Limit Information'),
// //         content: Text(
// //           'Your maximum loan amount is calculated as 3 times your current savings balance.\n\n'
// //           'Current Savings: ${_formatCurrency(widget.memberSavings)}\n'
// //           'Maximum Loan: ${_formatCurrency(maxAmount)}',
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text('OK'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Future<void> _submitApplication() async {
// //     if (!_formKey.currentState!.validate()) return;

// //     setState(() => _isSubmitting = true);

// //     try {
// //       final amount = double.parse(_amountController.text);
// //       final interest = (amount * _interestRate / 100) * (_repaymentPeriod / 12);
// //       final totalRepayment = amount + interest;
// //       final monthlyPayment = _repaymentPeriod > 0 ? totalRepayment / _repaymentPeriod : 0;

// //       final application = {
// //         'memberId': widget.memberId,
// //         'amount': amount,
// //         'type': _loanType,
// //         'purpose': _purposeController.text,
// //         'repaymentPeriod': _repaymentPeriod,
// //         'interestRate': _interestRate,
// //         'totalRepayment': totalRepayment,
// //         'monthlyPayment': monthlyPayment,
// //         'status': 'Pending',
// //         'applicationDate': DateTime.now(),
// //         'documents': _documents.map((f) => f.name).toList(),
// //       };

// //       // Call the onSubmit callback with the application data
// //       widget.onSubmit(application);

// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Application submitted successfully!')),
// //         );
// //         Navigator.pop(context);
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Error: $e')),
// //         );
// //       }
// //     } finally {
// //       if (mounted) {
// //         setState(() => _isSubmitting = false);
// //       }
// //     }
// //   }

// //   Widget _buildRepaymentRow(String label, String value, {bool bold = false, Color? color}) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 6),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           Text(
// //             label,
// //             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
// //                   fontWeight: bold ? FontWeight.bold : FontWeight.normal,
// //                 ),
// //           ),
// //           Text(
// //             value,
// //             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
// //                   fontWeight: bold ? FontWeight.bold : FontWeight.normal,
// //                   color: color,
// //                 ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   String _formatCurrency(double amount) {
// //     return NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0).format(amount);
// //   }
// // }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _ninController = TextEditingController();
  final _employerController = TextEditingController();
  final _occupationController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _nextOfKinNameController = TextEditingController();
  final _nextOfKinPhoneController = TextEditingController();
  final _nextOfKinRelationshipController = TextEditingController();

  DateTime? _ninExpiryDate;
  bool _agreeToTerms = false;
  List<PlatformFile> _documents = [];
  bool _isSubmitting = false;

  String _loanType = 'Personal';
  int _repaymentPeriod = 3; // Default to minimum period
  final double _interestRate = 12.0;

  final String _termsAndConditions = """
TERMS AND CONDITIONS FOR LOAN APPLICATION

1. ELIGIBILITY CRITERIA
   - Must be an active member of the SACCO
   - Loan amount cannot exceed your current savings balance
   - Must have valid National ID (NIN) with unexpired status
   - Must provide complete and accurate information

2. LOAN TERMS
   - Interest rate: 12% per annum (1% per month)
   - Minimum repayment period: 3 months
   - Maximum repayment period: 24 months
   - Minimum loan amount: UGX 50,000
   - Maximum loan amount: Equal to your savings balance

3. REPAYMENT CONDITIONS
   - Monthly repayments will be automatically deducted from your savings
   - Late payment penalty: 5% of monthly installment
   - Failure to pay for 3 consecutive months may result in loan recovery action
   - Early repayment is allowed without penalty

4. DOCUMENTATION REQUIREMENTS
   - Valid National ID (NIN) with expiry date
   - Proof of income (salary slip, business license, etc.)
   - Next of kin details for contact purposes
   - Supporting documents as required

5. LOAN SECURITY
   - Your savings account serves as primary security
   - Additional guarantors may be required for larger amounts
   - The SACCO reserves the right to request additional security

6. MEMBER OBLIGATIONS
   - Provide accurate and complete information
   - Notify the SACCO of any changes in personal details
   - Maintain active membership throughout loan period
   - Use loan funds for stated purpose only

7. SACCO RIGHTS
   - The SACCO reserves the right to approve or reject any application
   - Verification of all information provided
   - Request additional documentation if needed
   - Modify terms and conditions with prior notice

8. DATA PROTECTION
   - Your personal information will be kept confidential
   - Information may be shared with credit reference bureaus
   - Data will be used for loan processing and member services

9. DISPUTE RESOLUTION
   - Any disputes will be resolved through SACCO internal mechanisms
   - Escalation to relevant authorities if internal resolution fails

10. AGREEMENT
    - By submitting this application, you agree to all terms and conditions
    - You authorize automatic deductions from your savings account
    - You confirm that all information provided is true and accurate
    - You understand the consequences of default

I have read, understood, and agree to abide by all the above terms and conditions.
""";

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    _ninController.dispose();
    _employerController.dispose();
    _occupationController.dispose();
    _monthlyIncomeController.dispose();
    _nextOfKinNameController.dispose();
    _nextOfKinPhoneController.dispose();
    _nextOfKinRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _fetchMemberDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.memberId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          // Pre-fill with existing data but allow editing
          _fullNameController.text = doc.get('fullName') ?? '';
          _phoneNumberController.text = doc.get('phoneNumber') ?? '';
          _ninController.text = doc.get('ninNumber') ?? '';
          _employerController.text = doc.get('employer') ?? '';
          _occupationController.text = doc.get('occupation') ?? '';
          _monthlyIncomeController.text = doc.get('monthlyIncome')?.toString() ?? '';

          // Handle NIN expiry date
          final ninExpiry = doc.get('ninExpiryDate');
          if (ninExpiry != null) {
            _ninExpiryDate = (ninExpiry as Timestamp).toDate();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading member details: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectNinExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _ninExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: 'Select NIN Expiry Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    if (date != null && mounted) {
      setState(() => _ninExpiryDate = date);
    }
  }

  Future<void> _pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && mounted) {
        setState(() => _documents = result.files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting files: ${e.toString()}')),
        );
      }
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Remove any spaces or special characters
    final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check for valid Uganda phone number format
    if (!RegExp(r'^(\+256|0)?[7][0-9]{8}$').hasMatch(cleanPhone)) {
      return 'Enter valid Uganda phone number (e.g., 0701234567)';
    }
    return null;
  }

  String? _validateNIN(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIN number is required';
    }
    // Basic NIN validation - should be 14 characters
    if (value.length != 14) {
      return 'NIN must be 14 characters long';
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.toUpperCase())) {
      return 'NIN contains invalid characters';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Loan amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Enter valid amount';
    }
    if (amount < 50000) {
      return 'Minimum loan amount is UGX 50,000';
    }
    if (amount > widget.memberSavings) {
      return 'Cannot exceed your savings balance';
    }
    return null;
  }

  void _submitApplication() async {
    if (!_formKey.currentState!.validate()||
    _ninExpiryDate == null ||
    !_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_ninExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select NIN expiry date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_ninExpiryDate!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIN has expired. Please renew your National ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the terms and conditions to proceed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);
      final monthlyIncome = double.tryParse(_monthlyIncomeController.text) ?? 0;
      final now = DateTime.now();
      final dueDate = now.add(Duration(days: _repaymentPeriod * 30));

      // Calculate repayment values
      final monthlyInterest = amount * (_interestRate / 100) / 12;
      final monthlyPayment = (amount / _repaymentPeriod) + monthlyInterest;
      final totalRepayment = monthlyPayment * _repaymentPeriod;

      final application = {
        'memberId': widget.memberId,
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'ninNumber': _ninController.text.trim().toUpperCase(),
        'ninExpiryDate': Timestamp.fromDate(_ninExpiryDate!),
        'employer': _employerController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'monthlyIncome': monthlyIncome,
        'nextOfKinName': _nextOfKinNameController.text.trim(),
        'nextOfKinPhone': _nextOfKinPhoneController.text.trim(),
        'nextOfKinRelationship': _nextOfKinRelationshipController.text.trim(),
        'loanType': _loanType,
        'amount': amount,
        'purpose': _purposeController.text.trim(),
        'repaymentPeriod': _repaymentPeriod,
        'interestRate': _interestRate,
        'monthlyPayment': monthlyPayment,
        'totalRepayment': totalRepayment,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': 'Pending Approval',
        'applicationDate': FieldValue.serverTimestamp(),
        'agreedToTerms': true,
        'termsAgreedAt': FieldValue.serverTimestamp(),
        'documents': _documents.map((f) => f.name).toList(),
        'remainingBalance': totalRepayment,
        'memberSavingsAtApplication': widget.memberSavings,
        'applicationSource': 'Mobile App',
        'verified': false,
        'verificationNotes': '',
      };
      if (widget.onSubmit !=null){

        await widget.onSubmit(application);
      }

      

      

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Application Submitted Successfully'),
            content: const Text(
              'Your loan application has been submitted and is under review. '
              'You will be notified of the approval status within 2-3 business days.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // if (mounted) {
      {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Application'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with member info
              Card(
                elevation: 4,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Member ID: ${widget.memberId}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Available Savings: ${_formatCurrency(widget.memberSavings)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'Enter your full name as on NIN',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Full name is required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: 'e.g., 0701234567',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ninController,
                        decoration: const InputDecoration(
                          labelText: 'NIN Number *',
                          hintText: 'Enter 14-character NIN',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        validator: _validateNIN,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectNinExpiry,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'NIN Expiry Date *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.calendar_today),
                            errorText: _ninExpiryDate != null && _ninExpiryDate!.isBefore(DateTime.now())
                                ? 'NIN has expired'
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _ninExpiryDate == null
                                    ? 'Select NIN expiry date'
                                    : DateFormat('dd MMM yyyy').format(_ninExpiryDate!),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Employment Information Section
              _buildSectionHeader('Employment Information', Icons.work),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _employerController,
                        decoration: const InputDecoration(
                          labelText: 'Employer/Business Name',
                          hintText: 'Enter your employer or business name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _occupationController,
                        decoration: const InputDecoration(
                          labelText: 'Occupation/Job Title',
                          hintText: 'Enter your job title or occupation',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _monthlyIncomeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Income (UGX)',
                          hintText: 'Enter your monthly income',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Next of Kin Information Section
              _buildSectionHeader('Next of Kin Information', Icons.family_restroom),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nextOfKinNameController,
                        decoration: const InputDecoration(
                          labelText: 'Next of Kin Name *',
                          hintText: 'Enter next of kin full name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Next of kin name is required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nextOfKinPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Next of Kin Phone Number *',
                          hintText: 'e.g., 0701234567',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nextOfKinRelationshipController,
                        decoration: const InputDecoration(
                          labelText: 'Relationship *',
                          hintText: 'e.g., Spouse, Parent, Sibling',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.family_restroom),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Relationship is required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
              ),

              // Loan Details Section
              _buildSectionHeader('Loan Details', Icons.money),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _loanType,
                        decoration: const InputDecoration(
                          labelText: 'Loan Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: ['Personal', 'Business', 'Emergency', 'Education', 'Medical']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _loanType = value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Loan Amount (UGX) *',
                          hintText: 'Min: 50,000 | Max: ${_formatCurrency(widget.memberSavings)}',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        validator: _validateAmount,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _purposeController,
                        decoration: const InputDecoration(
                          labelText: 'Purpose of Loan *',
                          hintText: 'Explain how you will use the loan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please state the purpose' : null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _repaymentPeriod,
                        decoration: const InputDecoration(
                          labelText: 'Repayment Period *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: List.generate(22, (i) => i + 3) // 3 to 24 months
                            .map((months) => DropdownMenuItem(
                                  value: months,
                                  child: Text('$months months'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _repaymentPeriod = value!),
                      ),
                      if (_amountController.text.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Loan Summary',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow('Monthly Payment:', _calculateMonthlyPayment()),
                              _buildSummaryRow('Total Repayment:', _calculateTotalRepayment()),
                              _buildSummaryRow('Interest Rate:', '$_interestRate% per annum'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Documents Section
              _buildSectionHeader('Supporting Documents', Icons.upload_file),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload supporting documents (Optional)',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Acceptable formats: PDF, JPG, PNG\nRecommended: Salary slip, Bank statement, Business license',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickDocuments,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select Documents'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade800,
                        ),
                      ),
                      if (_documents.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Documents:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              ..._documents.map((file) => Text(
                                    '• ${file.name}',
                                    style: const TextStyle(fontSize: 12),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Terms and Conditions
              _buildSectionHeader('Terms & Conditions', Icons.gavel),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _termsAndConditions,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                              activeColor: Colors.green,
                            ),
                            const Expanded(
                              child: Text(
                                'I have read, understood, and agree to all terms and conditions stated above. I confirm that all information provided is true and accurate.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Submit Button
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isSubmitting ? null : _submitApplication,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('SUBMITTING APPLICATION...'),
                          ],
                        )
                      : const Text(
                          'SUBMIT LOAN APPLICATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateMonthlyPayment() {
    if (_amountController.text.isEmpty) return 'UGX 0';

    try {
      final amount = double.parse(_amountController.text);
      final monthlyInterest = amount * (_interestRate / 100) / 12;
      final monthlyPayment = (amount / _repaymentPeriod) + monthlyInterest;
      return _formatCurrency(monthlyPayment);
    } catch (e) {
      return 'UGX 0';
    }
  }

  String _calculateTotalRepayment() {
    if (_amountController.text.isEmpty) return 'UGX 0';

    try {
      final amount = double.parse(_amountController.text);
      final monthlyInterest = amount * (_interestRate / 100) / 12;
      final monthlyPayment = (amount / _repaymentPeriod) + monthlyInterest;
      final totalRepayment = monthlyPayment * _repaymentPeriod;
      return _formatCurrency(totalRepayment);
    } catch (e) {
      return 'UGX 0';
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }
}

// loan_application.dart

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:file_picker/file_picker.dart';
// import 'loan.dart';

// class LoanApplicationScreen extends StatefulWidget {
//   final String memberId;
//   final double memberSavings;

//   const LoanApplicationScreen({
//     super.key,
//     required this.memberId,
//     required this.memberSavings,
//   });

//   @override
//   State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
// }

// class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _fullNameController = TextEditingController();
//   final _phoneNumberController = TextEditingController();
//   final _amountController = TextEditingController();
//   final _purposeController = TextEditingController();
//   final _ninController = TextEditingController();
//   final _employerController = TextEditingController();
//   final _occupationController = TextEditingController();
//   final _monthlyIncomeController = TextEditingController();
//   final _nextOfKinNameController = TextEditingController();
//   final _nextOfKinPhoneController = TextEditingController();
//   final _nextOfKinRelationshipController = TextEditingController();

//   DateTime? _ninExpiryDate;
//   bool _agreeToTerms = false;
//   List<PlatformFile> _documents = [];
//   bool _isSubmitting = false;

//   String _loanType = 'Personal';
//   int _repaymentPeriod = 3;
//   final double _interestRate = 12.0;

//   @override
//   void initState() {
//     super.initState();
//     _fetchMemberDetails();
//   }

//   Future<void> _fetchMemberDetails() async {
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('members')
//           .doc(widget.memberId)
//           .get();

//       if (doc.exists && mounted) {
//         setState(() {
//           _fullNameController.text = doc.get('fullName') ?? '';
//           _phoneNumberController.text = doc.get('phoneNumber') ?? '';
//           _ninController.text = doc.get('ninNumber') ?? '';
//           _employerController.text = doc.get('employer') ?? '';
//           _occupationController.text = doc.get('occupation') ?? '';
//           _monthlyIncomeController.text =
//               doc.get('monthlyIncome')?.toString() ?? '';
//           final ninExpiry = doc.get('ninExpiryDate');
//           if (ninExpiry != null) {
//             _ninExpiryDate = (ninExpiry as Timestamp).toDate();
//           }
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading member details: $e')),
//       );
//     }
//   }

//   void _submitApplication() async {
//     if (!_formKey.currentState!.validate() ||
//         _ninExpiryDate == null ||
//         !_agreeToTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill in all fields and agree to terms'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (_ninExpiryDate!.isBefore(DateTime.now())) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('NIN has expired.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() => _isSubmitting = true);

//     try {
//       final amount = double.parse(_amountController.text);
//       final monthlyIncome = double.tryParse(_monthlyIncomeController.text) ?? 0;
//       final now = DateTime.now();
//       final dueDate = now.add(Duration(days: _repaymentPeriod * 30));

//       final monthlyInterest = amount * (_interestRate / 100) / 12;
//       final monthlyPayment = (amount / _repaymentPeriod) + monthlyInterest;
//       final totalRepayment = monthlyPayment * _repaymentPeriod;

//       final application = {
//         'memberId': widget.memberId,
//         'fullName': _fullNameController.text.trim(),
//         'phoneNumber': _phoneNumberController.text.trim(),
//         'ninNumber': _ninController.text.trim().toUpperCase(),
//         'ninExpiryDate': Timestamp.fromDate(_ninExpiryDate!),
//         'employer': _employerController.text.trim(),
//         'occupation': _occupationController.text.trim(),
//         'monthlyIncome': monthlyIncome,
//         'nextOfKinName': _nextOfKinNameController.text.trim(),
//         'nextOfKinPhone': _nextOfKinPhoneController.text.trim(),
//         'nextOfKinRelationship': _nextOfKinRelationshipController.text.trim(),
//         'loanType': _loanType,
//         'amount': amount,
//         'purpose': _purposeController.text.trim(),
//         'repaymentPeriod': _repaymentPeriod,
//         'interestRate': _interestRate,
//         'monthlyPayment': monthlyPayment,
//         'totalRepayment': totalRepayment,
//         'dueDate': Timestamp.fromDate(dueDate),
//         'status': 'Pending Approval',
//         'applicationDate': FieldValue.serverTimestamp(),
//         'agreedToTerms': true,
//         'termsAgreedAt': FieldValue.serverTimestamp(),
//         'documents': _documents.map((f) => f.name).toList(),
//         'remainingBalance': totalRepayment,
//         'memberSavingsAtApplication': widget.memberSavings,
//         'applicationSource': 'Mobile App',
//         'verified': false,
//         'verificationNotes': '',
//       };

//       await Loan.submitToFirestore(application);

//       if (mounted) {
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Application Submitted'),
//             content: const Text('Your loan application has been submitted.'),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   Navigator.of(context).pop(true);
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error submitting application: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isSubmitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Loan Application')),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             TextFormField(
//               controller: _fullNameController,
//               decoration: const InputDecoration(labelText: 'Full Name'),
//               validator: (value) =>
//                   value == null || value.isEmpty ? 'Required' : null,
//             ),
//             TextFormField(
//               controller: _phoneNumberController,
//               decoration: const InputDecoration(labelText: 'Phone Number'),
//               validator: (value) =>
//                   value == null || value.isEmpty ? 'Required' : null,
//             ),
//             TextFormField(
//               controller: _amountController,
//               decoration: const InputDecoration(labelText: 'Loan Amount'),
//               keyboardType: TextInputType.number,
//               validator: (value) =>
//                   value == null || double.tryParse(value) == null
//                   ? 'Enter valid amount'
//                   : null,
//             ),
//             ElevatedButton(
//               onPressed: _isSubmitting ? null : _submitApplication,
//               child: Text(
//                 _isSubmitting ? 'Submitting...' : 'Submit Loan Application',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
