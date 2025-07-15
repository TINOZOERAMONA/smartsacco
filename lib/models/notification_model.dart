import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  payment,
  loan,
  promotion,
  general, loanApplication,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  bool isRead;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
    this.actionUrl,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      date: data['date']?.toDate() ?? DateTime.now(),
      type: NotificationType.values[data['type'] ?? 0],
      isRead: data['isRead'] ?? false,
      actionUrl: data['actionUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'date': date,
      'type': type.index,
      'isRead': isRead,
      'actionUrl': actionUrl,
    };
  }
}