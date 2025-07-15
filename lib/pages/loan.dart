class Loan {
  final String id;
  final double amount;
  double remainingBalance;
  final DateTime disbursementDate;
  final DateTime dueDate;
  String status;
  final String type;
  final double interestRate;
  final double totalRepayment;
  final List<Payment> payments;
  final int repaymentPeriod;

  Loan({
    required this.id,
    required this.amount,
    required this.remainingBalance,
    required this.disbursementDate,
    required this.dueDate,
    required this.status,
    required this.type,
    required this.interestRate,
    required this.totalRepayment,
    required this.repaymentPeriod,
    this.payments = const [],
  });

  double get nextPaymentAmount {
    if (repaymentPeriod > 0) {
      return totalRepayment / repaymentPeriod;
    }
    return 0;
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
  return Loan(
    id: json['id'],
    amount: (json['amount'] as num).toDouble(), // Fix: move closing parenthesis before .toDouble()
    remainingBalance: (json['remainingBalance'] as num).toDouble(),
    disbursementDate: DateTime.parse(json['disbursementDate']),
    dueDate: DateTime.parse(json['dueDate']),
    status: json['status'],
    type: json['type'],
    interestRate: (json['interestRate'] as num).toDouble(),
    totalRepayment: (json['totalRepayment'] as num).toDouble(),
    repaymentPeriod: json['repaymentPeriod'] as int, // cast to int explicitly
    payments: (json['payments'] as List<dynamic>)
        .map((p) => Payment.fromJson(p))
        .toList(),
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'remainingBalance': remainingBalance,
      'disbursementDate': disbursementDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'type': type,
      'interestRate': interestRate,
      'totalRepayment': totalRepayment,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }
}

class Payment {
  final double amount;
  final DateTime date;
  final String reference;

  Payment({required this.amount, required this.date, required this.reference});

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      reference: json['reference'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'reference': reference,
    };
  }
}