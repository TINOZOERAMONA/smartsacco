// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class LoanApprovalPage extends StatefulWidget {
  final String loanId;
  final Map<String, dynamic> loanData;

  const LoanApprovalPage({
    super.key,
    required this.loanId,
    required this.loanData,
  });

  @override
  LoanApprovalPageState createState() => LoanApprovalPageState();
}

class LoanApprovalPageState extends State<LoanApprovalPage> {
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
