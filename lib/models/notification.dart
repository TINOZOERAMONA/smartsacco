//Types of notifications supported in the application
enum NotificationType {
  payment,
  loan,
  promotion,
  general,
}

// Represents a notification in the application with all relevant metadata
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;

  // Whether the user has viewed this notification
  bool isRead;
  // Optional deep link for handling notification taps
  final String? actionUrl;

// Creates a new notification instance
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
    this.actionUrl,
  });



 // Creates an AppNotification from JSON data (for API responses)
  // Throws FormatException if date parsing fails

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      date: DateTime.parse(json['date']),
      type: NotificationType.values[json['type']],
      isRead: json['isRead'],
      actionUrl: json['actionUrl'],
    );
  }

// Converts the notification to JSON format (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'type': type.index,
      'isRead': isRead,
      'actionUrl': actionUrl,
    };
  }
}




