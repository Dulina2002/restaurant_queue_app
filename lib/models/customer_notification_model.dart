import 'package:flutter/material.dart';

class CustomerNotificationItem {
  final String id;
  final String title;
  final String message;
  final String category; // 'queue', 'booking', 'offer', 'loyalty'
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? actionLabel;
  final DateTime createdAt;
  bool isRead;

  CustomerNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.createdAt,
    this.actionLabel,
    this.isRead = false,
  });

  /// 'Today' or 'Earlier' – computed live from the timestamp.
  String get section {
    final now = DateTime.now();
    final sameDay = createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
    return sameDay ? 'Today' : 'Earlier';
  }

  /// Relative time label, e.g. "Just now", "5m ago", "Yesterday, 4:15 PM".
  String get time {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (section == 'Today') return '${diff.inHours}h ago';

    final hour12 = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    final clock = '$hour12:$minute $period';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final isYesterday = createdAt.year == yesterday.year &&
        createdAt.month == yesterday.month &&
        createdAt.day == yesterday.day;
    if (isYesterday) return 'Yesterday, $clock';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[createdAt.month - 1]} ${createdAt.day}, $clock';
  }
}
