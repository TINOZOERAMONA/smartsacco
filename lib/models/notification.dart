enum NotificationType {
  payment,
  loan,
  promotion,
  general,
}






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




