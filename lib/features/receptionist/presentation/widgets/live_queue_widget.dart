import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../data/models/queue_entry_model.dart';
import '../../../../core/utils/shared_mock_data.dart';
import 'seat_table_dialog.dart';
import '../../data/models/floor_table_model.dart';

class LiveQueueWidget extends StatefulWidget {
  const LiveQueueWidget({super.key});

  @override
  State<LiveQueueWidget> createState() => _LiveQueueWidgetState();
}

class _LiveQueueWidgetState extends State<LiveQueueWidget> {
  List<QueueEntry> get _queue => SharedMockData().queue;

  @override
  void initState() {
    super.initState();
  }

  void _seatAtTable(QueueEntry entry) async {
    final selectedTable = await SeatTableDialog.show(context, entry: entry);
    if (selectedTable != null) {
      setState(() {
        _queue.removeWhere((e) => e.id == entry.id);
        _recalculatePositions();
        
        // Update table status in SharedMockData
        final tables = SharedMockData().tables;
        final index = tables.indexWhere((t) => t.id == selectedTable.id);
        if (index != -1) {
          tables[index] = tables[index].copyWith(
            status: FloorTableStatus.occupied,
            guestName: entry.guestName,
          );
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.guestName} seated at ${selectedTable.name}!'),
            backgroundColor: const Color(0xFF2E9B60),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _notify(QueueEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification sent to ${entry.guestName} (${entry.queueNumber})'),
        backgroundColor: const Color(0xFFF27B50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _removeFromQueue(QueueEntry entry) {
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _queue.removeWhere((e) => e.id == entry.id);
                _recalculatePositions();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${entry.guestName} removed from queue.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
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
            const Text(
              'Est. 15m',
              style: TextStyle(
                color: Color(0xFFF27B50),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_queue.length} parties waiting for tables',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),

        // Queue Cards List
        if (_queue.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60),
            alignment: Alignment.center,
            child: Column(
              children: const [
                Icon(Icons.check_circle_outline, size: 52, color: Color(0xFF2E9B60)),
                SizedBox(height: 14),
                Text(
                  'No parties in queue!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'All waiting guests have been seated.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
            color: Colors.black.withOpacity(0.015),
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
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF27B50),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.queueNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
