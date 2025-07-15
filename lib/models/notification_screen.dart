

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartsacco/models/notification_model.dart';
import 'package:smartsacco/models/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  final String memberId;
  final Function(int) onNotificationsRead;

  const NotificationsScreen({
    required this.memberId,
    required this.onNotificationsRead,
    super.key,
  });

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  // Colors
  final Color _primaryColor = const Color(0xFF3366CC);
  final Color _dangerColor = const Color(0xFFF44336);
  final Color _textSecondary = const Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final notificationsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.memberId)
        .collection('notifications')
        .orderBy('date', descending: true)
        .get();

    int unread = 0;
    List<AppNotification> notifications = [];

    for (var doc in notificationsSnapshot.docs) {
      final isRead = doc['isRead'] ?? false;
      if (!isRead) unread++;

      notifications.add(
        AppNotification(
          id: doc.id,
          title: doc['title'] ?? 'Notification',
          message: doc['message'] ?? '',
          date: doc['date']?.toDate() ?? DateTime.now(),
          type: NotificationType.values[doc['type'] ?? 0],
          isRead: isRead,
          actionUrl: doc['actionUrl'],
        ),
      );
    }

    if (mounted) {
      setState(() {
        _notifications = notifications;
        _unreadCount = unread;
      });
      widget.onNotificationsRead(0); // Reset unread count
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return const Color(0xFF4CAF50);
      case NotificationType.loan:
        return _primaryColor;
      case NotificationType.promotion:
        return const Color(0xFFFFA726);
      case NotificationType.general:
        return const Color(0xFF6699FF);
      case NotificationType.loanApplication:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.loan:
        return Icons.credit_card;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.general:
        return Icons.notifications;
      case NotificationType.loanApplication:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  void _viewNotification(AppNotification notification) {
    // Mark as read if unread
    if (!notification.isRead) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .collection('notifications')
          .doc(notification.id)
          .update({'isRead': true});

      setState(() {
        _unreadCount--;
      });
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              DateFormat('MMM d, y h:mm a').format(notification.date),
              style: GoogleFonts.poppins(color: _textSecondary),
            ),
          ],
        ),
        actions: [
          if (notification.actionUrl != null)
            TextButton(
              onPressed: () {
                // Handle action URL
                Navigator.pop(context);
              },
              child: Text(
                'View Details',
                style: GoogleFonts.poppins(color: _primaryColor),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$_unreadCount New',
                style: GoogleFonts.poppins(
                  color: _dangerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 50,
                        color: _textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: GoogleFonts.poppins(color: _textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) => NotificationItem(
                    notification: _notifications[index],
                    getNotificationColor: _getNotificationColor,
                    getNotificationIcon: _getNotificationIcon,
                    onTap: _viewNotification,
                    textSecondary: _textSecondary,
                    primaryColor: _primaryColor,
                    dangerColor: _dangerColor,
                  ),
                ),
        ),
      ],
    );
  }
}


