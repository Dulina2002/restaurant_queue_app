import 'dart:async';
import 'package:flutter/material.dart';
import '../models/customer_notification_model.dart';
import '../models/queue_entry_model.dart';
import '../models/reservation_model.dart';
import '../shared/theme/app_colors.dart';
import 'supabase_service.dart';

/// Builds the customer's notification feed in real time by watching the live
/// queue and reservation streams and emitting an event whenever something changes
/// (queue joined / moving up / table ready / left, reservation confirmed /
/// updated / cancelled).
class CustomerNotificationCenter extends ChangeNotifier {
  CustomerNotificationCenter._();
  static final CustomerNotificationCenter instance = CustomerNotificationCenter._();

  final List<CustomerNotificationItem> _items = [];
  final StreamController<CustomerNotificationItem> _newController =
      StreamController<CustomerNotificationItem>.broadcast();

  String? _userId;
  StreamSubscription<QueueEntryModel?>? _queueSub;
  StreamSubscription<List<ReservationModel>>? _reservationSub;

  bool _queueBaselineDone = false;
  bool _reservationBaselineDone = false;
  QueueEntryModel? _lastQueue;
  final Map<String, ReservationModel> _lastReservations = {};

  /// Fires only for genuinely new events (not for the initial history load).
  Stream<CustomerNotificationItem> get onNew => _newController.stream;

  List<CustomerNotificationItem> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.isRead).length;

  void start(String userId) {
    if (_userId == userId) return;
    stop();
    _userId = userId;
    _items.clear();
    _queueBaselineDone = false;
    _reservationBaselineDone = false;
    _lastQueue = null;
    _lastReservations.clear();

    final service = SupabaseService();
    _queueSub = service.streamCustomerActiveQueue(userId).listen(
      _onQueue,
      onError: (e) => debugPrint('Notification queue stream error: $e'),
    );
    _reservationSub = service.streamUserReservations(userId).listen(
      _onReservations,
      onError: (e) => debugPrint('Notification reservation stream error: $e'),
    );
    notifyListeners();
  }

  void stop() {
    _queueSub?.cancel();
    _reservationSub?.cancel();
    _queueSub = null;
    _reservationSub = null;
    _userId = null;
  }

  // ---------------- Queue events ----------------

  void _onQueue(QueueEntryModel? q) {
    final prev = _lastQueue;
    _lastQueue = q;
    final live = _queueBaselineDone;
    _queueBaselineDone = true;

    if (q != null && prev == null) {
      _add(
        id: live ? _eventId('queue_joined') : 'queue_joined_${q.id}',
        title: live ? 'Queue Joined Successfully' : 'You are in the queue',
        message:
            'You are #${q.position} in queue at ${q.restaurantName} (party of ${q.partySize}). Estimated wait is ${q.estimatedWaitMinutes} mins.',
        category: 'queue',
        icon: Icons.people_outline_rounded,
        iconColor: const Color(0xFF0284C7),
        iconBgColor: AppColors.skyTint,
        actionLabel: 'View Queue Ticket',
        createdAt: live ? DateTime.now() : (q.createdAt ?? DateTime.now()),
        live: live,
      );
      if (!live && q.status == QueueStatus.called) _tableReady(q, live: false);
      return;
    }

    if (q != null && prev != null) {
      if (q.status == QueueStatus.called && prev.status != QueueStatus.called) {
        _tableReady(q, live: true);
      } else if (q.position < prev.position) {
        _add(
          id: _eventId('queue_move'),
          title: q.position == 1 ? 'You are next!' : 'Moving up the queue',
          message:
              'You are now #${q.position} in queue at ${q.restaurantName}. About ${q.estimatedWaitMinutes} mins to go.',
          category: 'queue',
          icon: Icons.hourglass_top_rounded,
          iconColor: const Color(0xFFD97706),
          iconBgColor: AppColors.amberTint,
          actionLabel: 'View Queue Ticket',
          createdAt: DateTime.now(),
          live: true,
        );
      }
      return;
    }

    if (q == null && prev != null && live) {
      _add(
        id: _eventId('queue_left'),
        title: 'Queue Update',
        message: 'You are no longer in the queue at ${prev.restaurantName}.',
        category: 'queue',
        icon: Icons.exit_to_app_rounded,
        iconColor: const Color(0xFF6B7280),
        iconBgColor: AppColors.background,
        createdAt: DateTime.now(),
        live: true,
      );
    }
  }

  void _tableReady(QueueEntryModel q, {required bool live}) {
    _add(
      id: live ? _eventId('table_ready') : 'table_ready_${q.id}',
      title: 'Your Table is Ready!',
      message:
          'Please proceed to the host desk at ${q.restaurantName} (Table for ${q.partySize}).',
      category: 'queue',
      icon: Icons.notifications_active_rounded,
      iconColor: const Color(0xFF10B981),
      iconBgColor: AppColors.mintTint,
      actionLabel: 'View Queue Ticket',
      createdAt: DateTime.now(),
      live: live,
    );
  }

  // ---------------- Reservation events ----------------

  void _onReservations(List<ReservationModel> list) {
    final live = _reservationBaselineDone;
    _reservationBaselineDone = true;

    for (final r in list) {
      final prev = _lastReservations[r.id];
      _lastReservations[r.id] = r;
      final cancelled = r.status == 'cancelled';

      if (prev == null) {
        _add(
          id: live ? _eventId('res_new') : 'res_${r.id}',
          title: cancelled ? 'Reservation Cancelled' : 'Reservation Confirmed',
          message: cancelled
              ? 'Your booking ${r.reservationCode} at ${r.restaurantName} was cancelled.'
              : 'Your booking ${r.reservationCode} for ${r.partySize} guests at ${r.restaurantName} on ${r.date} at ${r.time} is confirmed.',
          category: 'booking',
          icon: cancelled ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
          iconColor: cancelled ? AppColors.error : const Color(0xFF10B981),
          iconBgColor: cancelled ? const Color(0xFFFEE2E2) : AppColors.mintTint,
          actionLabel: 'View Reservation',
          createdAt: live ? DateTime.now() : (r.createdAt ?? DateTime.now()),
          live: live,
        );
      } else if (!cancelled && prev.status == 'cancelled') {
        continue;
      } else if (cancelled && prev.status != 'cancelled') {
        _add(
          id: _eventId('res_cancel'),
          title: 'Reservation Cancelled',
          message: 'Your booking ${r.reservationCode} at ${r.restaurantName} was cancelled.',
          category: 'booking',
          icon: Icons.cancel_outlined,
          iconColor: AppColors.error,
          iconBgColor: const Color(0xFFFEE2E2),
          createdAt: DateTime.now(),
          live: true,
        );
      } else if (!cancelled &&
          (prev.date != r.date || prev.time != r.time || prev.partySize != r.partySize)) {
        _add(
          id: _eventId('res_update'),
          title: 'Reservation Updated',
          message:
              'Your booking ${r.reservationCode} at ${r.restaurantName} is now ${r.date} at ${r.time} for ${r.partySize} guests.',
          category: 'booking',
          icon: Icons.edit_calendar_rounded,
          iconColor: const Color(0xFFD97706),
          iconBgColor: AppColors.amberTint,
          actionLabel: 'View Reservation',
          createdAt: DateTime.now(),
          live: true,
        );
      }
    }
  }

  // ---------------- Helpers & actions ----------------

  String _eventId(String type) => '${type}_${DateTime.now().microsecondsSinceEpoch}';

  void _add({
    required String id,
    required String title,
    required String message,
    required String category,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required DateTime createdAt,
    required bool live,
    String? actionLabel,
  }) {
    if (_items.any((n) => n.id == id)) return;
    final item = CustomerNotificationItem(
      id: id,
      title: title,
      message: message,
      category: category,
      icon: icon,
      iconColor: iconColor,
      iconBgColor: iconBgColor,
      actionLabel: actionLabel,
      createdAt: createdAt,
      isRead: !live, // history is already "seen"; live events are unread
    );
    _items.add(item);
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
    if (live) _newController.add(item);
  }

  void markAllRead() {
    for (final n in _items) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markRead(String id) {
    for (final n in _items) {
      if (n.id == id) n.isRead = true;
    }
    notifyListeners();
  }

  void delete(String id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
