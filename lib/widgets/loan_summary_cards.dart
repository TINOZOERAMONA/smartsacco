// import 'package:flutter/material.dart';
// import '../pages/loan.dart';

// class LoanSummaryCards extends StatelessWidget {
//   final int activeLoansCount;
//   final int overdueLoansCount;
//   final double totalLoanAmount;
//   final List<Loan> approvedLoans;
//   final void Function() onActiveLoansTap;
//   final void Function() onOverdueLoansTap;
//   final void Function() onTotalLoanTap;

//   const LoanSummaryCards({
//     super.key,
//     required this.activeLoansCount,
//     required this.overdueLoansCount,
//     required this.totalLoanAmount,
//     required this.approvedLoans,
//     required this.onActiveLoansTap,
//     required this.onOverdueLoansTap,
//     required this.onTotalLoanTap,
//   });

//   Widget _buildLoanCard(String title, String value, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Card(
//         margin: const EdgeInsets.all(8),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(title,
//                   style: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               Text(value, style: const TextStyle(fontSize: 24)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _buildLoanCard('Active Loans', '$activeLoansCount', onActiveLoansTap),
//         _buildLoanCard('Overdue', '$overdueLoansCount', onOverdueLoansTap),
//         _buildLoanCard(
//             'Total Loan', 'UGX ${totalLoanAmount.toStringAsFixed(2)}', onTotalLoanTap),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import '../pages/loan.dart';

class LoanSummaryCards extends StatelessWidget {
  final int activeLoansCount;
  final int overdueLoansCount;
  final double totalLoanAmount;
  final List<Loan> approvedLoans;
  final VoidCallback onActiveLoansTap;
  final VoidCallback onOverdueLoansTap;
  final VoidCallback onTotalLoanTap;

  const LoanSummaryCards({
    super.key,
    required this.activeLoansCount,
    required this.overdueLoansCount,
    required this.totalLoanAmount,
    required this.approvedLoans,
    required this.onActiveLoansTap,
    required this.onOverdueLoansTap,
    required this.onTotalLoanTap,
  });

  /// Builds a single loan summary card with title, value and tap callback.
  Widget _buildLoanCard(String title, String value, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: Colors.white,
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            splashColor: Colors.blue.withOpacity(0.2),
            highlightColor: Colors.blue.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildLoanCard('Active Loans', '$activeLoansCount', onActiveLoansTap),
        _buildLoanCard('Overdue', '$overdueLoansCount', onOverdueLoansTap),
        _buildLoanCard(
          'Total Loan',
          'UGX ${totalLoanAmount.toStringAsFixed(2)}',
          onTotalLoanTap,
        ),
      ],
    );
  }
}