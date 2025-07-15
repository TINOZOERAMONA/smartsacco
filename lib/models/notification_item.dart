import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartsacco/models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final Color Function(NotificationType) getNotificationColor;
  final IconData Function(NotificationType) getNotificationIcon;
  final Function(AppNotification) onTap;
  final Color textSecondary;
  final Color primaryColor;
  final Color dangerColor;

  const NotificationItem({
    required this.notification,
    required this.getNotificationColor,
    required this.getNotificationIcon,
    required this.onTap,
    required this.textSecondary,
    required this.primaryColor,
    required this.dangerColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: getNotificationColor(notification.type).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            getNotificationIcon(notification.type),
            color: getNotificationColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(notification.date),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dangerColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => onTap(notification),
      ),
    );
  }
}