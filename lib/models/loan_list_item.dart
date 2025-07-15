import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartsacco/pages/loan.dart';

class LoanListItem extends StatelessWidget {
  final Loan loan;
  final String Function(double) formatCurrency;
  final Color Function(String) getStatusColor;
  final Function(Loan) onPaymentPressed;

  const LoanListItem({
    required this.loan,
    required this.formatCurrency,
    required this.getStatusColor,
    required this.onPaymentPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loan #${loan.id.substring(0, 8)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(loan.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    loan.status,
                    style: GoogleFonts.poppins(
                      color: getStatusColor(loan.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildLoanDetailRow('Amount:', formatCurrency(loan.amount)),
            _buildLoanDetailRow(
              'Applied:',
              DateFormat('MMM d, y').format(loan.applicationDate),
            ),
            if (loan.status == 'Approved')
              _buildLoanDetailRow(
                'Disbursed:',
                DateFormat('MMM d, y').format(loan.disbursementDate!),
              ),
            if (loan.status == 'Rejected')
              _buildLoanDetailRow('Status:', 'Application Rejected'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }
}