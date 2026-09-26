import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

enum NotificationCategory { all, queueAndBookings, offers }

class CustomerNotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String category; // 'queue', 'booking', 'offer', 'loyalty'
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? actionLabel;
  final String section; // 'Today', 'Earlier'
  bool isRead;

  CustomerNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.actionLabel,
    required this.section,
    this.isRead = false,
  });
}

class CustomerNotificationsSheet extends StatefulWidget {
  const CustomerNotificationsSheet({super.key});

  @override
  State<CustomerNotificationsSheet> createState() =>
      _CustomerNotificationsSheetState();
}

class _CustomerNotificationsSheetState
    extends State<CustomerNotificationsSheet> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

  late List<CustomerNotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      CustomerNotificationItem(
        id: '1',
        title: 'Table Ready Soon!',
        message:
            'You are #1 in queue at Ocean Bistro (Table for 2). Please proceed to the host desk.',
        time: '5m ago',
        category: 'queue',
        icon: Icons.hourglass_top_rounded,
        iconColor: const Color(0xFFD97706),
        iconBgColor: AppColors.amberTint,
        actionLabel: 'View Queue Ticket',
        section: 'Today',
        isRead: false,
      ),
      CustomerNotificationItem(
        id: '2',
        title: 'Reservation Confirmed',
        message:
            'Your booking #RSV10245 for 2 guests at Ocean Bistro today at 7:30 PM is confirmed.',
        time: '1h ago',
        category: 'booking',
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF10B981),
        iconBgColor: AppColors.mintTint,
        actionLabel: 'View Reservation',
        section: 'Today',
        isRead: false,
      ),
      CustomerNotificationItem(
        id: '3',
        title: 'Weekend 20% Off Special',
        message:
            'Enjoy 20% off all brunch & artisan brews this Saturday at Black Cat Café.',
        time: 'Yesterday, 4:15 PM',
        category: 'offer',
        icon: Icons.local_offer_outlined,
        iconColor: const Color(0xFFFF6B4A),
        iconBgColor: AppColors.peachTint,
        actionLabel: 'View Offer',
        section: 'Earlier',
        isRead: true,
      ),
      CustomerNotificationItem(
        id: '4',
        title: 'Queue Joined Successfully',
        message:
            'You joined the virtual queue #Q12 at Ocean Bistro. Estimated wait is 12 mins.',
        time: 'Yesterday, 1:20 PM',
        category: 'queue',
        icon: Icons.people_outline_rounded,
        iconColor: const Color(0xFF0284C7),
        iconBgColor: AppColors.skyTint,
        section: 'Earlier',
        isRead: true,
      ),
      CustomerNotificationItem(
        id: '5',
        title: 'Earned 150 DinePoints',
        message:
            'Your receipt from The Mango Tree has been verified. 150 points added to your balance!',
        time: 'Sep 22, 9:00 PM',
        category: 'loyalty',
        icon: Icons.stars_rounded,
        iconColor: const Color(0xFF8B5CF6),
        iconBgColor: const Color(0xFFF3E8FF),
        section: 'Earlier',
        isRead: true,
      ),
    ];
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _markAsRead(CustomerNotificationItem item) {
    setState(() {
      item.isRead = true;
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  List<CustomerNotificationItem> _getFilteredNotifications() {
    switch (_selectedCategory) {
      case NotificationCategory.queueAndBookings:
        return _notifications
            .where((n) => n.category == 'queue' || n.category == 'booking')
            .toList();
      case NotificationCategory.offers:
        return _notifications
            .where((n) => n.category == 'offer' || n.category == 'loyalty')
            .toList();
      case NotificationCategory.all:
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredNotifications();
    final todayList = filtered.where((n) => n.section == 'Today').toList();
    final earlierList =
        filtered.where((n) => n.section == 'Earlier').toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Title + Unread Badge + Mark all read + Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                if (_unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_unreadCount new',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                const Spacer(),
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: _markAllAsRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D3B2E),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filter Segment Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTabPill('All', NotificationCategory.all),
                const SizedBox(width: 8),
                _buildTabPill(
                    'Queue & Bookings', NotificationCategory.queueAndBookings),
                const SizedBox(width: 8),
                _buildTabPill('Offers & Points', NotificationCategory.offers),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Notification List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    children: [
                      if (todayList.isNotEmpty) ...[
                        _buildSectionHeader('TODAY'),
                        const SizedBox(height: 8),
                        ...todayList.map((item) => _buildNotificationCard(item)),
                        const SizedBox(height: 16),
                      ],
                      if (earlierList.isNotEmpty) ...[
                        _buildSectionHeader('EARLIER'),
                        const SizedBox(height: 8),
                        ...earlierList
                            .map((item) => _buildNotificationCard(item)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String title, NotificationCategory category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D3B2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D3B2E) : AppColors.border,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildNotificationCard(CustomerNotificationItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: 22,
        ),
      ),
      child: GestureDetector(
        onTap: () => _markAsRead(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead
                ? Colors.white
                : const Color(0xFFF9FBFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? AppColors.border
                  : const Color(0xFF0D3B2E).withValues(alpha: 0.2),
              width: item.isRead ? 1 : 1.2,
            ),
            boxShadow: [
              if (!item.isRead)
                BoxShadow(
                  color: const Color(0xFF0D3B2E).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Icon Bubble
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: item.iconColor,
                ),
              ),
              const SizedBox(width: 12),

              // Content: Title, Message, Time, Action Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.accentOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (item.actionLabel != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          _markAsRead(item);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D3B2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.actionLabel!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You have caught up with all queue alerts, bookings, and specials.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
