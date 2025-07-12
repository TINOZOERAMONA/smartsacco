import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class LoanApprovalPage extends StatefulWidget {
  final String loanId;

import 'package:intl/intl.dart';

class LoanApprovalPage extends StatefulWidget {
  final DocumentReference loanRef;

  final Map<String, dynamic> loanData;

  const LoanApprovalPage({
    Key? key,
    required this.loanId,
    required this.loanRef,
    required this.loanData,
  }) : super(key: key);

  @override

  _LoanApprovalPageState createState() => _LoanApprovalPageState();

  State<LoanApprovalPage> createState() => _LoanApprovalPageState();

}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  String? _decision;

  String _notes = '';
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat.yMMMMd().add_jm();

  @override
  Widget build(BuildContext context) {
    final loan = widget.loanData;

    final memberName = loan['memberName'] ?? 'Unknown';
    final amount = loan['amount']?.toString() ?? '0';
    final rawDate = loan['applicationDate'];
    String formattedDate = 'Unknown';

    if (rawDate is Timestamp) {
      formattedDate = _dateFormat.format(rawDate.toDate());
    } else if (rawDate is String) {
      formattedDate = rawDate;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Approval'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade600,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoTile('Loan ID', widget.loanId),
                    _infoTile('Member', memberName),
                    _infoTile('Amount', 'UGX $amount'),
                    _infoTile('Applied On', formattedDate),
                    const Divider(height: 32),
                    const Text(
                      'Decision:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'approved',
                          groupValue: _decision,
                          onChanged: (val) => setState(() => _decision = val),
                        ),
                        const Text('Approve'),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'rejected',
                          groupValue: _decision,
                          onChanged: (val) => setState(() => _decision = val),
                        ),
                        const Text('Reject'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Approval Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (val) => _notes = val,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _loading ? null : _submitDecision,
                        icon: const Icon(Icons.check_circle),
                        label: Text(_loading ? 'Submitting...' : 'Submit Decision'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),

  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get isLocked {
    final status = widget.loanData['status']?.toString().toLowerCase() ?? '';
    return status == 'approved' || status == 'rejected';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateLoanStatus({
    required String status,
    required String notes,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final decisionBy = FirebaseAuth.instance.currentUser?.uid ?? 'admin';

    try {
      await widget.loanRef.update({
        'status': status,
        'decisionDate': FieldValue.serverTimestamp(),
        'decisionBy': decisionBy,
        'notes': notes,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan $status successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoCard() {
    final data = widget.loanData;
    final currencyFormat = NumberFormat.currency(symbol: 'UGX ');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loan Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Amount', currencyFormat.format(data['amount'])),
            _buildInfoRow('Purpose', data['purpose'] ?? 'N/A'),
            _buildInfoRow('Type', data['type'] ?? 'N/A'),
            _buildInfoRow('Status', _getStatusText(data['status'])),
            _buildInfoRow(
              'Application Date',
              _formatDate(data['applicationDate']),
            ),
            _buildInfoRow(
              'Disbursement Date',
              _formatDate(data['disbursementDate']),
            ),
            _buildInfoRow('Due Date', _formatDate(data['dueDate'])),
            _buildInfoRow('Interest Rate', '${data['interestRate']}%'),
            _buildInfoRow(
              'Monthly Payment',
              currencyFormat.format(data['monthlyPayment']),
            ),
            _buildInfoRow(
              'Total Repayment',
              currencyFormat.format(data['totalRepayment']),
            ),
            _buildInfoRow(
              'Remaining Balance',
              currencyFormat.format(data['remainingBalance']),
            ),

          ],
        ),
      ),
    );
  }


  Future<void> _submitDecision() async {
    if (_decision == null) {
      _showMessage('Please select a decision');
      return;
    }

    setState(() => _loading = true);

    try {
      await _updateLoanStatus(
        loanId: widget.loanId,
        status: _decision!,
        notes: _notes.trim(),
      );

      _showMessage('Loan ${_decision!} successfully');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateLoanStatus({
    required String loanId,
    required String status,
    required String notes,
  }) async {
    final loanRef = FirebaseFirestore.instance.collection('loans').doc(loanId);
    final docSnapshot = await loanRef.get();

    if (!docSnapshot.exists) {
      throw Exception("Loan record not found.");
    }

    final decisionBy = FirebaseAuth.instance.currentUser?.uid ?? 'admin_placeholder';

    await loanRef.update({
      'status': status,
      'decisionDate': FieldValue.serverTimestamp(),
      'decisionBy': decisionBy,
      'notes': notes,
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
  Widget _buildInfoRow(String label, String value) {
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
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    }
    return date.toString();
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  void _submitDecision() async {
    if (_decision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a decision'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _updateLoanStatus(
      status: _decision!,
      notes: _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loanStatus = widget.loanData['status']?.toString().toLowerCase() ?? '';
    final isApprovedOrRejected = isLocked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Application Review'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade800,
      ),
      backgroundColor: Colors.grey.shade50,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              // Decision Section
              const Text(
                'Loan Decision',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (isApprovedOrRejected)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: loanStatus == 'approved'
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: loanStatus == 'approved'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                    ),
                  ),
                  child: Text(
                    'This loan has already been ${_getStatusText(loanStatus)}.\n'
                    'Decision cannot be changed.',
                    style: TextStyle(
                      color: loanStatus == 'approved'
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                )
              else
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Decision',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: _decision,
                          validator: (value) =>
                              value == null ? 'Please select a decision' : null,
                          onChanged: (value) {
                            setState(() {
                              _decision = value;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'approved',
                              child: Text('Approve Loan'),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text('Reject Loan'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Decision Notes (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _submitDecision,
                            child: const Text(
                              'Submit Decision',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

