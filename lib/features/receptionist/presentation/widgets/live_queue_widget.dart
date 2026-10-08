import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/queue_entry_model.dart' as db;
import '../../../../services/supabase_service.dart';
import '../../../../services/receptionist_context.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../data/models/queue_entry_model.dart';
import 'seat_table_dialog.dart';
import '../../data/models/floor_table_model.dart';

class LiveQueueWidget extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;

  const LiveQueueWidget({
    super.key,
    this.restaurantId,
    this.restaurantName,
  });

  @override
  State<LiveQueueWidget> createState() => _LiveQueueWidgetState();
}

class _LiveQueueWidgetState extends State<LiveQueueWidget> {
  List<QueueEntry> _queue = [];
  bool _isLoading = true;
  StreamSubscription<dynamic>? _queueSub;

  String get _currentRestaurantId =>
      widget.restaurantId ?? ReceptionistContext().activeRestaurantId;

  String get _currentRestaurantName =>
      widget.restaurantName ?? ReceptionistContext().activeRestaurantName;

  @override
  void initState() {
    super.initState();
    _subscribeToQueue();
    ReceptionistContext().activeRestaurantNotifier.addListener(_onRestaurantChanged);
  }

  void _onRestaurantChanged() {
    if (mounted) {
      _subscribeToQueue();
    }
  }

  void _subscribeToQueue() {
    _queueSub?.cancel();
    setState(() => _isLoading = true);

    final restaurantId = _currentRestaurantId;
    _queueSub = SupabaseService()
        .streamRestaurantQueue(restaurantId: restaurantId)
        .listen((list) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _queue = list.map((item) {
          int waitMins = item.estimatedWaitMinutes;
          if (item.createdAt != null) {
            final diff = DateTime.now().difference(item.createdAt!.toLocal()).inMinutes;
            if (diff >= 0 && diff < 120) {
              waitMins = diff;
            }
          }
          return QueueEntry(
            id: item.id,
            queueNumber: item.queueNumber,
            guestName: item.guestName,
            partySize: item.partySize,
            waitingMinutes: waitMins,
            position: item.position,
          );
        }).toList();
        _recalculatePositions();
      });
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    ReceptionistContext().activeRestaurantNotifier.removeListener(_onRestaurantChanged);
    super.dispose();
  }

  void _seatAtTable(QueueEntry entry) async {
    final restaurantId = _currentRestaurantId;
    final selectedTable = await SeatTableDialog.show(
      context,
      entry: entry,
      restaurantId: restaurantId,
    );
    if (selectedTable != null) {
      await SupabaseService().updateQueueStatus(
        entry.id,
        db.QueueStatus.seated,
        restaurantId: restaurantId,
      );

      await SupabaseService().updateFloorTableStatus(
        restaurantId: restaurantId,
        tableId: selectedTable.id,
        status: FloorTableStatus.occupied,
        guestName: entry.guestName,
      );

      setState(() {
        _queue.removeWhere((e) => e.id == entry.id);
        _recalculatePositions();
      });

      if (mounted) {
        AppToast.showSuccess(
          context,
          '${entry.guestName} seated at ${selectedTable.name} in $_currentRestaurantName!',
          title: 'Guest Seated',
        );
      }
    }
  }

  void _notify(QueueEntry entry) async {
    final restaurantId = _currentRestaurantId;
    await SupabaseService().updateQueueStatus(
      entry.id,
      db.QueueStatus.called,
      restaurantId: restaurantId,
    );

    if (mounted) {
      AppToast.show(
        context,
        message: 'Notification sent to ${entry.guestName} (${entry.queueNumber})',
        title: 'Notification Sent',
        type: ToastType.info,
      );
    }
  }

  void _removeFromQueue(QueueEntry entry) {
    final restaurantId = _currentRestaurantId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove from Waitlist',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${entry.guestName} (${entry.queueNumber}) from the waitlist queue?',
          style: const TextStyle(color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _queue.removeWhere((e) => e.id == entry.id);
                _recalculatePositions();
              });
              await SupabaseService().leaveQueue(
                queueId: entry.id,
                restaurantId: restaurantId,
              );
              if (!mounted) return;
              AppToast.show(
                this.context,
                message: '${entry.guestName} removed from queue.',
                title: 'Queue Updated',
                type: ToastType.warning,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _recalculatePositions() {
    for (int i = 0; i < _queue.length; i++) {
      _queue[i] = _queue[i].copyWith(position: i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Title & Estimated Time
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Waitlist Queue',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Text(
                          _currentRestaurantName,
                          style: const TextStyle(
                            color: Color(0xFFC2410C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_queue.length} ${_queue.length == 1 ? 'party' : 'parties'} waiting',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _queue.isEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _queue.isEmpty ? const Color(0xFFBBF7D0) : const Color(0xFFFFEDD5),
                ),
              ),
              child: Text(
                _queue.isEmpty ? 'Direct Seating' : 'Est. ${_queue.length * 5}m wait',
                style: TextStyle(
                  color: _queue.isEmpty ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Queue Cards List
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
          )
        else if (_queue.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 52, color: Color(0xFF10B981)),
                const SizedBox(height: 14),
                Text(
                  'No parties in queue for $_currentRestaurantName!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All waiting guests have been seated. New waitlist entries will appear live.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _queue.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildQueueCard(_queue[index]);
            },
          ),
      ],
    );
  }

  Widget _buildQueueCard(QueueEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name & Details + Queue Position Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circle Avatar with Queue Number
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF27B50),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    entry.queueNumber,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name and guest/waiting details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.guestName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.partySize} Guests  •  Waiting ${entry.waitingMinutes} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Position in line badge
              Text(
                '#${entry.position} in line',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF27B50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons Row: Seat at Table + Notify + Remove (X)
          Row(
            children: [
              // Seat at Table Button
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: () => _seatAtTable(entry),
                  icon: const Icon(Icons.check, color: Colors.white, size: 16),
                  label: const Text(
                    'Seat at Table',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E9B60),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Notify Button
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: () => _notify(entry),
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                  label: const Text(
                    'Notify',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Close / Remove Button
              OutlinedButton(
                onPressed: () => _removeFromQueue(entry),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(40, 44),
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFF87171),
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
