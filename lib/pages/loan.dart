

// import 'package:cloud_firestore/cloud_firestore.dart';



// class Payment {
//   final double amount;
//   final DateTime date;
//   final String reference;
  

//   Payment({
//     required this.amount,
//     required this.date,
//     required this.reference,
//   });

//   factory Payment.fromJson(Map<String, dynamic> json) {
//     return Payment(
//       amount: (json['amount'] as num).toDouble(),
//       date: DateTime.parse(json['date']),
//       reference: json['reference'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'amount': amount,
//       'date': date.toIso8601String(),
//       'reference': reference,
//     };
//   }
// }


// class Loan {
//   final String id;
//   final double amount;
//   double remainingBalance;
//   final DateTime disbursementDate;
//   final DateTime dueDate;
//   String status;
//   final String type;
//   final double interestRate;
//   final double totalRepayment;
//   final List<Payment> payments;
//   final int repaymentPeriod;
//   final DateTime applicationDate; 

//   Loan({
//     required this.id,
//     required this.amount,
//     required this.remainingBalance,
//     required this.disbursementDate,
//     required this.dueDate,
//     required this.status,
//     required this.type,
//     required this.interestRate,
//     required this.totalRepayment,
//     required this.repaymentPeriod,
//     this.payments = const [],
//     required this.applicationDate,
//   });

//   double get nextPaymentAmount {
//     if (repaymentPeriod > 0) {
//       return totalRepayment / repaymentPeriod;
//     }
//     return 0;
//   }

//   factory Loan.fromJson(Map<String, dynamic> json) {
//     return Loan(
//       id: json['id'],
//       amount: (json['amount'] as num).toDouble(),
//       remainingBalance: (json['remainingBalance'] as num).toDouble(),
//       disbursementDate: DateTime.parse(json['disbursementDate']),
//       dueDate: DateTime.parse(json['dueDate']),
//       status: json['status'],
//       type: json['type'],
//       interestRate: (json['interestRate'] as num).toDouble(),
//       totalRepayment: (json['totalRepayment'] as num).toDouble(),
//       repaymentPeriod: json['repaymentPeriod'],
//       payments: (json['payments'] as List<dynamic>)
//           .map((p) => Payment.fromJson(p))
//           .toList(),
//       applicationDate: DateTime.parse(json['applicationDate']), // Added this line
//     );
//   }

//   factory Loan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
//     final d = doc.data()!;
//     return Loan(
//       id: doc.id,
//       amount: (d['amount'] as num).toDouble(),
//       remainingBalance: (d['remainingBalance'] as num).toDouble(),
//       disbursementDate: DateTime.parse(d['disbursementDate']),
//       dueDate: DateTime.parse(d['dueDate']),
//       status: d['status'],
//       type: d['type'],
//       interestRate: (d['interestRate'] as num).toDouble(),
//       totalRepayment: (d['totalRepayment'] as num).toDouble(),
//       repaymentPeriod: d['repaymentPeriod'],
//       payments: (d['payments'] as List<dynamic>)
//           .map((p) => Payment.fromJson(p))
//           .toList(),
//       applicationDate: DateTime.parse(d['applicationDate']), // Added this line
//     );
//   }


//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'amount': amount,
//       'remainingBalance': remainingBalance,
//       'disbursementDate': disbursementDate.toIso8601String(),
//       'dueDate': dueDate.toIso8601String(),
//       'status': status,
//       'type': type,
//       'interestRate': interestRate,
//       'totalRepayment': totalRepayment,
//       'repaymentPeriod': repaymentPeriod,
//       'payments': payments.map((p) => p.toJson()).toList(),
//       'applicationDate': applicationDate.toIso8601String(), // Added this line
//     };
//   }
// }




import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, completed, rejected }



class Payment {
  final double amount;
  final DateTime date;
  final String reference;
  final String? paymentMethod;
  final PaymentStatus status;
  final String? transactionId;
  final String payerFullName;  // Added
  final String payerPhoneNumber;  // Added

  Payment({
    required this.amount,
    required this.date,
    required this.reference,
    required this.payerFullName,  // Required
    required this.payerPhoneNumber,  // Required
    this.paymentMethod,
    this.status = PaymentStatus.pending,
    this.transactionId,
  }) : assert(payerPhoneNumber.isNotEmpty, 'Phone number cannot be empty');


  


  

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: _parseDate(json['date']) ?? DateTime.now(),
      reference: json['reference']?.toString() ?? '',
      payerFullName: json['payerFullName']?.toString() ?? 'Unknown',  // Default value
      payerPhoneNumber: json['payerPhoneNumber']?.toString() ?? '',  // Required
      paymentMethod: json['paymentMethod']?.toString(),
      status: _parsePaymentStatus(json['status']),
      transactionId: json['transactionId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date,
      'reference': reference,
      'payerFullName': payerFullName,
      'payerPhoneNumber': payerPhoneNumber,
      'status': status.name,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (transactionId != null) 'transactionId': transactionId,
    };
  }

  Payment copyWith({
    double? amount,
    DateTime? date,
    String? reference,
    String? payerFullName,
    String? payerPhoneNumber,
    String? paymentMethod,
    PaymentStatus? status,
    String? transactionId,
  }) {
    return Payment(
      amount: amount ?? this.amount,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      payerFullName: payerFullName ?? this.payerFullName,
      payerPhoneNumber: payerPhoneNumber ?? this.payerPhoneNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  @override
  String toString() {
    return 'Payment($payerFullName, $payerPhoneNumber, ${amount.toStringAsFixed(2)}, $status)';
  }
}

class Loan {
  final String id;
  final double amount;
  double remainingBalance;
  final DateTime? disbursementDate;
  final DateTime? dueDate;
  String _status;
  final String type;
  final double interestRate;
  final double totalRepayment;
  final List<Payment> payments;
  final int repaymentPeriod;
  final DateTime applicationDate;
  final String applicantFullName;  // Changed from applicantPhone to full name
  final String applicantPhoneNumber;
  final String? coSignerFullName;  // Added
  final String? coSignerPhoneNumber;  // Added
  final String? purpose;
  final String? loanOfficerId;
  final String? loanOfficerName;  // Added
  final DateTime? lastUpdated;

  Loan({
    required this.id,
    required this.amount,
    required this.remainingBalance,
    required this.applicantFullName,
    required this.applicantPhoneNumber,
    this.disbursementDate,
    this.dueDate,
    required String status,
    required this.type,
    required this.interestRate,
    required this.totalRepayment,
    required this.repaymentPeriod,
    List<Payment>? payments,
    required this.applicationDate,
    this.coSignerFullName,
    this.coSignerPhoneNumber,
    this.purpose,
    this.loanOfficerId,
    this.loanOfficerName,
    this.lastUpdated, required double nextPaymentAmount,
  })  : _status = status.toLowerCase(),
        payments = payments ?? const [],
        assert(amount >= 0, 'Amount cannot be negative'),
        assert(interestRate >= 0, 'Interest rate cannot be negative'),
        assert(applicantPhoneNumber.isNotEmpty, 'Phone number cannot be empty');

  String get status => _status;

  set status(String value) {
    final lower = value.toLowerCase();
    if (!_validStatuses.contains(lower)) {
      throw ArgumentError('Invalid loan status: $value');
    }
    _status = lower;
  }

  static const _validStatuses = {
    'pending',
    'approved',
    'active',
    'rejected',
    'completed',
    'defaulted'
  };

  double get nextPaymentAmount {
    if (!isActive) return 0;
    if (repaymentPeriod <= 0) return 0;

    final remainingPayments = repaymentPeriod - completedPayments.length;
    if (remainingPayments <= 0) return 0;

    return (totalRepayment - totalPaid) / remainingPayments;
  }

  List<Payment> get completedPayments => payments
      .where((p) => p.status == PaymentStatus.completed)
      .toList();

  double get totalPaid => completedPayments.fold(
        0.0,
        (sum, payment) => sum + payment.amount,
      );

  bool get isActive => status == 'active' || status == 'approved';

  bool get isOverdue {
    if (dueDate == null || !isActive) return false;
    return dueDate!.isBefore(DateTime.now()) && remainingBalance > 0;
  }

//   factory Loan.fromFirestore(DocumentSnapshot doc) {
//   final data = doc.data() as Map<String, dynamic>;
//   return Loan(
//     id: doc.id,
//     amount: (data['amount'] as num).toDouble(),
//     remainingBalance: (data['remainingBalance'] as num).toDouble(),
//     disbursementDate: DateTime.parse(data['disbursementDate']),
//     dueDate: DateTime.parse(data['dueDate']),
//     status: data['status'],
//     type: data['type'],
//     interestRate: (data['interestRate'] as num).toDouble(),
//     totalRepayment: (data['totalRepayment'] as num).toDouble(),
//     repaymentPeriod: data['repaymentPeriod'],
//     payments: (data['payments'] as List<dynamic>)
//         .map((p) => Payment.fromJson(p))
//         .toList(),
//     applicationDate: DateTime.parse(data['applicationDate']),
//     applicantFullName: data['applicantFullName'] ?? 'Unknown',
//     applicantPhoneNumber: data['applicantPhoneNumber'] ?? '',
//     nextPaymentAmount: 0, // or calculate it here if you want
//   );
// }
// factory Loan.fromFirestore(DocumentSnapshot doc) {
//   final data = doc.data() as Map<String, dynamic>;
//   return Loan(
//     id: doc.id,
//     amount: (data['amount'] as num).toDouble(),
//     remainingBalance: (data['remainingBalance'] as num).toDouble(),
//     disbursementDate: _parseDate(data['disbursementDate']),
//     dueDate: _parseDate(data['dueDate']),
//     status: data['status'] ?? 'pending',
//     type: data['type'] ?? 'personal',
//     interestRate: (data['interestRate'] as num).toDouble(),
//     totalRepayment: (data['totalRepayment'] as num).toDouble(),
//     repaymentPeriod: data['repaymentPeriod'] ?? 0,
//     payments: (data['payments'] as List<dynamic>?)
//             ?.map((p) => Payment.fromJson(p))
//             .toList() ??
//         [],
//     applicationDate: _parseDate(data['applicationDate']) ?? DateTime.now(),
//     applicantFullName: data['applicantFullName']?.toString() ?? 'Unknown',
//     applicantPhoneNumber: data['applicantPhoneNumber']?.toString() ?? '',
//     coSignerFullName: data['coSignerFullName']?.toString(),
//     coSignerPhoneNumber: data['coSignerPhoneNumber']?.toString(),
//     purpose: data['purpose']?.toString(),
//     loanOfficerId: data['loanOfficerId']?.toString(),
//     loanOfficerName: data['loanOfficerName']?.toString(),
//     lastUpdated: _parseDate(data['lastUpdated']),
//     nextPaymentAmount: 0, // You can calculate this if needed
//   );
// }


  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      remainingBalance: (json['remainingBalance'] as num?)?.toDouble() ?? 0,
      applicantFullName: json['applicantFullName']?.toString() ?? 'Unknown',
      applicantPhoneNumber: json['applicantPhoneNumber']?.toString() ?? '',
      disbursementDate: _parseDate(json['disbursementDate']),
      dueDate: _parseDate(json['dueDate']),
      status: json['status']?.toString() ?? 'pending',
      type: json['type']?.toString() ?? 'personal',
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0,
      totalRepayment: (json['totalRepayment'] as num?)?.toDouble() ?? 0,
      repaymentPeriod: (json['repaymentPeriod'] as int?) ?? 0,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => Payment.fromJson(p))
              .toList() ??
          [],
      applicationDate: _parseDate(json['applicationDate']) ?? DateTime.now(),
      coSignerFullName: json['coSignerFullName']?.toString(),
      coSignerPhoneNumber: json['coSignerPhoneNumber']?.toString(),
      purpose: json['purpose']?.toString(),
      loanOfficerId: json['loanOfficerId']?.toString(),
      loanOfficerName: json['loanOfficerName']?.toString(),
      lastUpdated: _parseDate(json['lastUpdated']), nextPaymentAmount: 0,
    );
  }

  // factory Loan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    
  //   return Loan.fromJson({...doc.data() ?? {}, 'id': doc.id});
  // }

  factory Loan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  return Loan(
    id: doc.id,
    amount: (d['amount'] as num).toDouble(),
    remainingBalance: (d['remainingBalance'] as num).toDouble(),
    disbursementDate: DateTime.parse(d['disbursementDate']),
    dueDate: DateTime.parse(d['dueDate']),
    status: d['status'],
    type: d['type'],
    interestRate: (d['interestRate'] as num).toDouble(),
    totalRepayment: (d['totalRepayment'] as num).toDouble(),
    repaymentPeriod: d['repaymentPeriod'],
    payments: (d['payments'] as List<dynamic>)
        .map((p) => Payment.fromJson(p))
        .toList(),
    applicationDate: DateTime.parse(d['applicationDate']),
    applicantFullName: d['applicantFullName']?.toString() ?? 'Unknown',  // Add this required argument
    applicantPhoneNumber: d['applicantPhoneNumber']?.toString() ?? '', nextPaymentAmount: 0,    // Add this required argument
  );
}
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'remainingBalance': remainingBalance,
      'applicantFullName': applicantFullName,
      'applicantPhoneNumber': applicantPhoneNumber,
      'status': status,
      'type': type,
      'interestRate': interestRate,
      'totalRepayment': totalRepayment,
      'repaymentPeriod': repaymentPeriod,
      'payments': payments.map((p) => p.toJson()).toList(),
      'applicationDate': applicationDate,
      if (disbursementDate != null) 'disbursementDate': disbursementDate,
      if (dueDate != null) 'dueDate': dueDate,
      if (coSignerFullName != null) 'coSignerFullName': coSignerFullName,
      if (coSignerPhoneNumber != null) 'coSignerPhoneNumber': coSignerPhoneNumber,
      if (purpose != null) 'purpose': purpose,
      if (loanOfficerId != null) 'loanOfficerId': loanOfficerId,
      if (loanOfficerName != null) 'loanOfficerName': loanOfficerName,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
    };
  }

  Loan copyWith({
    String? id,
    double? amount,
    double? remainingBalance,
    String? applicantFullName,
    String? applicantPhoneNumber,
    DateTime? disbursementDate,
    DateTime? dueDate,
    String? status,
    String? type,
    double? interestRate,
    double? totalRepayment,
    List<Payment>? payments,
    int? repaymentPeriod,
    DateTime? applicationDate,
    String? coSignerFullName,
    String? coSignerPhoneNumber,
    String? purpose,
    String? loanOfficerId,
    String? loanOfficerName,
    DateTime? lastUpdated,
  }) {
    return Loan(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      applicantFullName: applicantFullName ?? this.applicantFullName,
      applicantPhoneNumber: applicantPhoneNumber ?? this.applicantPhoneNumber,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      type: type ?? this.type,
      interestRate: interestRate ?? this.interestRate,
      totalRepayment: totalRepayment ?? this.totalRepayment,
      repaymentPeriod: repaymentPeriod ?? this.repaymentPeriod,
      payments: payments ?? this.payments,
      applicationDate: applicationDate ?? this.applicationDate,
      coSignerFullName: coSignerFullName ?? this.coSignerFullName,
      coSignerPhoneNumber: coSignerPhoneNumber ?? this.coSignerPhoneNumber,
      purpose: purpose ?? this.purpose,
      loanOfficerId: loanOfficerId ?? this.loanOfficerId,
      loanOfficerName: loanOfficerName ?? this.loanOfficerName,
      lastUpdated: lastUpdated ?? this.lastUpdated, nextPaymentAmount: 0,
    );
  }

  @override
  String toString() {
    return 'Loan($applicantFullName, $applicantPhoneNumber, ${amount.toStringAsFixed(2)}, $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Loan &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            status == other.status &&
            remainingBalance == other.remainingBalance);
  }

  @override
  int get hashCode => id.hashCode ^ status.hashCode ^ remainingBalance.hashCode;

  static void fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {}
}

DateTime? _parseDate(dynamic date) {
  if (date == null) return null;
  if (date is Timestamp) return date.toDate();
  if (date is DateTime) return date;
  if (date is String) return DateTime.tryParse(date);
  return null;
}

PaymentStatus _parsePaymentStatus(dynamic status) {
  if (status == null) return PaymentStatus.pending;
  if (status is PaymentStatus) return status;
  
  switch (status.toString().toLowerCase()) {
    case 'completed':
      return PaymentStatus.completed;
    case 'rejected':
      return PaymentStatus.rejected;
    default:
      return PaymentStatus.pending;
  }
}

